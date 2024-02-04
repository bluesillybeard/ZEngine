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
    /// Sparse list
    localRegistries: std.ArrayList(?registry.SystemRegistry),
    /// Sparse list
    localEcsRegistry: std.ArrayList(?ecs.Registry),
};

pub const LocalHandle = usize;

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
                    .globalEcsRegistry = ecs.Registry.init(allocator),
                    .localRegistries = std.ArrayList(?SystemRegistry).init(allocator),
                    .localEcsRegistry = std.ArrayList(?ecs.Registry).init(allocator),
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
                try system.systemInitGlobal(&this.registries);
            }
            return this;
        }

        pub fn initLocal(this: *@This(), allocator: std.mem.Allocator) !LocalHandle {
            const handle = try this.reserveLocal();
            this.registries.localRegistries.items[handle] = SystemRegistry.init(allocator);
            var localRegistry = &this.registries.localRegistries.items[handle].?;
            var staticAllocator = localRegistry.staticAllocator.allocator();
            // allocate the systems
            inline for(options.localSystems) |System| {
                const system = try staticAllocator.create(System);
                system.* = System.init(staticAllocator, allocator);
                try localRegistry.addRegister(System, system);
            }
            const localEcs = ecs.Registry.init(allocator);
            this.registries.localEcsRegistry.items[handle] = localEcs;
            // initialize the systems
            inline for(options.localSystems) |System| {
                const system = localRegistry.getRegister(System) orelse unreachable;
                try system.systemInitLocal(this.registries, handle);
            }
            return handle;
        }

        pub fn deinitLocal(this: *@This(), local: LocalHandle) void {
            // deinit the local registry
            // TODO: deinit systems in backwards order
            const localRegistry = &this.registries.localRegistries.items[local].?;
            inline for(options.localSystems) |System| {
                const system = localRegistry.getRegister(System).?;
                system.systemDeinitLocal(this.registries, local);
            }
            inline for(options.localSystems) |System| {
                const system = localRegistry.getRegister(System).?;
                system.deinit();
            }
            localRegistry.deinit();
            // Don't forget the entities too
            const localEcs = &this.registries.localEcsRegistry.items[local].?;
            localEcs.deinit();
            // dereference
            this.registries.localRegistries.items[local] = null;
            this.registries.localEcsRegistry.items[local] = null;
        }

        /// Deinit ZEngine, along with all of its associated resources.
        pub fn deinit(this: *@This()) void {
            // TODO: deinit systems in backwards order
            
            // deinit local systems
            for(this.registries.localRegistries.items, 0..) |localRegistryOrNone, index| {
                if(localRegistryOrNone == null) continue;
                this.deinitLocal(index);
            }
            // deinit global systems
            inline for(options.globalSystems) |System| {
                const system = this.registries.globalRegistry.getRegister(System) orelse unreachable;
                system.systemDeinitGlobal(&this.registries);
            }
            // destroy global systems
            inline for(options.globalSystems) |System| {
                const system = this.registries.globalRegistry.getRegister(System) orelse unreachable;
                system.deinit();
            }
            this.registries.globalEcsRegistry.deinit();
            this.registries.globalRegistry.deinit();
            this.registries.localEcsRegistry.deinit();
            this.registries.localRegistries.deinit();
        }

        fn reserveLocal(this: *@This()) !LocalHandle {
            // TODO: find an empty spot if there is one
            const index = this.registries.localRegistries.items.len;
            _ = try this.registries.localRegistries.addOne();
            _ = try this.registries.localEcsRegistry.addOne();
            return index;
        }
        registries: RegistrySet,
    };
}
