// This is the root module where public declarations are exposed.
const registry = @import("registry.zig");
const ecs = @import("ecs");
const std = @import("std");

pub const ZEngineComptimeOptions = struct {
    /// A global system has once instance for the lifetime of the application
    globalSystems: []const type,
    /// Local systems have one instance per entity registry
    localSystems: []const type,
};

pub const RegistrySet = struct {
    globalRegistry: registry.SystemRegistry,
    globalEcsRegistry: ecs.Registry,
    localRegistries: std.ArrayList(registry.SystemRegistry),
    localEcsRegistry: std.ArrayList(ecs.Registry),
};

/// ZEngine requires a bunch of compile-time information from the user. This function should only be called once for each application.
pub fn ZEngine(comptime options: ZEngineComptimeOptions) type {
    inline for(options.globalSystems) |System| {
        if(!System.comptimeVerification(options)) @compileError(@typeName(System) ++ " Did not pass compile-time verification");
        // TODO: Make sure it has all of the required functions.
        // TODO: make sure the signature matches too

    }
    inline for(options.localSystems) |System| {
        if(!System.comptimeVerification(options)) @compileError(@typeName(System) ++ " Did not pass compile-time verification");
        // TODO: Make sure it has all of the required functions.
        // TODO: make sure the signature matches too
    }
    return struct {
        pub const Options = options;
        pub const SystemRegistry = registry.SystemRegistry;
        /// Creates an instance of ZEngine. Multiple instances are allowed but not recomended, instead use multiple local System/Ecs registres.
        pub fn init(allocator: std.mem.Allocator) !@This() {
            var this = @This(){
                .registries = .{
                    .globalRegistry = SystemRegistry.init(allocator),
                    .globalEcs = ecs.Registry.init(allocator),
                    .localRegistries = std.ArrayList(SystemRegistry).init(allocator),
                    .localEcs = std.ArrayList(ecs.Registry).init(allocator),
                }
                
            };
            const staticAllocator = this.registries.globalRegistry.staticAllocator.allocator();
            // Allocate all of the systems
            inline for(options.globalSystems) |System| {
                const system = try staticAllocator.create(System);
                system.* = System.init(staticAllocator, allocator);
                try this.registries.globalRegistry.addRegister(System, system);
            }
            // Properly initialize all of the systems
            inline for(options.globalSystems) |System| {
                const system = this.registries.globalRegistry.getRegister(System) orelse unreachable;
                try system.systemInit(this.registries.globalRegistry, this.registrySet.globalEcs);
            }
            return this;
        }

        /// Deinit ZEngine, along with all of its associated resources.
        pub fn deinit(this: *@This()) void {
            _ = this; // autofix
            // destroy local registries first, in case they depend on the global registries
            for(this.registries.localRegistries.items) |registry| {
                inline for(options.localSystems) |System| {
                    const system = registry.getRegister(System);
                    
                }
            }
        }
        registries: RegistrySet,
    };
}
