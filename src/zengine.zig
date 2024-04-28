// This is the root module where public declarations are exposed.
const ecs = @import("ecs");
const std = @import("std");

pub const ZEngineError = error {
    noEcsFound,
} || RegistryError;

pub const LocalHandle = usize;

pub const ZEngine = struct {
    pub fn init(allocator: std.mem.Allocator) ZEngine {
        return .{
            .allocator = allocator,
            ._globalRegistry = SystemRegistry.init(allocator),
            ._globalEcsRegistry = ecs.Registry.init(allocator),
            ._localRegistries = std.ArrayList(?SystemRegistry).init(allocator),
            ._localEcsRegistries = std.ArrayList(?ecs.Registry).init(allocator),
        };
    }
    /// This destroys the engine and everything it holds.
    /// No order is guaranteed for the destruction of registries and systems.
    /// If something is order dependent, destroy those yourself separately before calling this.
    pub fn deinit(this: *ZEngine) void {
        this._globalRegistry.deinit();
        this._globalEcsRegistry.deinit();
        for(this._localRegistries.items) |*registryOrNone| {
            // You know, getting a pointer from the pointer of a nullable feels a bit jank to me.
            // Like, how does the compiler know to return the pointer of the original object
            // and not a pointer to a new copy of it allocated on the stack?
            // It's dereferenced, which in most cases seems to make a new copy on the stack, and then it is re-referenced.
            if(registryOrNone.* == null) continue;
            const registry = &registryOrNone.*.?;
            registry.deinit();
        }
        this._localRegistries.deinit();
        for(this._localEcsRegistries.items) |*registryOrNone| {
            if(registryOrNone.* == null) continue;
            const registry = &registryOrNone.*.?;
            registry.deinit();
        }
        this._localEcsRegistries.deinit();
    }

    /// Adds a system to the global registry. The user is in charge of managing its memory.
    /// A deinit function is requred at minimum, for when the engine is destroyed.
    pub fn registerGlobalSystem(this: *ZEngine, comptime T: type, system: *T) !void {
        try this._globalRegistry.addRegister(T, system);
    }

    /// Removes a register from the global registry and calls its deinit function.
    pub fn deinitGlobalSystem(this: *ZEngine, comptime T: type) void {
        this._globalRegistry.removeRegister(T);
    }

    pub fn getGlobalSystem(this: *const ZEngine, comptime T: type) ZEngineError!*T {
        return this._globalRegistry.getRegister(T);
    }

    pub fn getGlobalEcs(this: *ZEngine) *ecs.Registry {
        return &this._globalEcsRegistry;
    }

    pub fn initLocalRegistry(this: *ZEngine) !LocalHandle {
        // TODO: way to use a custom allocator for each local registry
        // TODO: search for empty slot?
        try this._localRegistries.append(SystemRegistry.init(this.allocator));
        try this._localEcsRegistries.append(ecs.Registry.init(this.allocator));
        return this._localRegistries.items.len-1;
    }

    pub fn deinitLocalRegistry(this: *ZEngine, handle: LocalHandle) void {
        this._localRegistries.items[handle].?.deinit();
        this._localEcsRegistries.items[handle].?.deinit();
        this._localRegistries.items[handle] = null;
        this._localEcsRegistries.items[handle] = null;
    }

    pub fn getLocalEcs(this: *const ZEngine, handle: LocalHandle) !*ecs.Registry {
        const registry = &this._localEcsRegistries.items[handle];
        if(registry.* == null) return ZEngineError.noEcsFound;
        // This makes me nervous. How does the compiler know to return the address of the actual registry rather than a copy on this function's stack?
        return &(registry.*.?);
    }

    pub fn registerLocalSystem(this: *ZEngine, handle: LocalHandle, comptime T: type, obj: *T) !void {
        try this._localRegistries.items[handle].?.addRegister(T, obj);
    }

    pub fn deinitLocalSystem(this: *ZEngine, handle: LocalHandle, comptime T: type) void {
        this._localRegistries.items[handle].?.removeRegister(T);
    }

    pub fn getLocalSystem(this: *const ZEngine, handle: LocalHandle, comptime T: type) ?*T {
        return this._localRegistries.items[handle].?.getRegister(T);
    }

    pub fn getNumLocalSystems(this: *const ZEngine) usize {
        // TODO: cache this value
        var num: usize = 0;
        for(this._localRegistries.items) |registry| {
            if(registry != null) num+=1;
        }
        return num;
    }

    pub fn getCapacityLocalSystems(this: *const ZEngine) usize {
        return this._localRegistries.items.len;
    }

    allocator: std.mem.Allocator,
    _globalRegistry: SystemRegistry,
    _globalEcsRegistry: ecs.Registry,
    /// Sparse list
    _localRegistries: std.ArrayList(?SystemRegistry),
    /// Sparse list
    _localEcsRegistries: std.ArrayList(?ecs.Registry),
};

pub const RegistryError = error {
    noRegisterFound,
};

const Register = struct {
    object: *anyopaque,
    deinitFn: *const fn (object: *anyopaque) void,
};

const SystemRegistry = struct {
    pub fn init(allocator: std.mem.Allocator) SystemRegistry {
        return .{
            .allocator = allocator,
            ._storage = Storage.init(allocator),
        };
    }

    /// Destroys this along with any remaining registers
    pub fn deinit(this: *SystemRegistry) void {
        var iterator = this._storage.iterator();
        while(iterator.next()) |register| {
            register.value_ptr.deinitFn(register.value_ptr.object);
        }
        this._storage.deinit();
    }

    pub fn addRegister(this: *SystemRegistry, comptime T: type, obj: *T) !void {
        const id = hashType(T);
        const result = try this._storage.getOrPut(id);
        if(result.found_existing) {
            std.debug.panic("Register type {s} has existing register!", .{@typeName(T)});
        }
        result.value_ptr.* = .{
            .object = obj,
            // TODO: this reference to a field that may or may not exist is dificult to debug. Add an actual compile error message if this function is not correct.
            // TODO: instead of just a pointer cast, verify the function signiture THEN do the cast.
            .deinitFn = @ptrCast(&T.deinit),
        };
    }

    pub fn getRegister(this: *const SystemRegistry, comptime T: type) RegistryError!*T {
        const id = hashType(T);
        const register = this._storage.get(id);
        if(register == null) return RegistryError.noRegisterFound;
        // Assume since the ID is the same, the type is the same as well.
        return @alignCast(@ptrCast(register.?.object));
    }

    /// Removes a register from the registry and calls its deinit function.
    pub fn removeRegister(this: *SystemRegistry, comptime T: type) void {
        const id = hashType(T);
        const objOrNone = this._storage.fetchSwapRemove(id);
        if(objOrNone) |obj|{
            obj.value.deinitFn(obj.value.object);
        }
    }

    fn hashType(comptime T: type) u64 {
        return std.hash.Fnv1a_64.hash(@typeName(T));
    }

    const Storage = std.ArrayHashMap(u64, Register, struct {
        pub inline fn hash(this: @This(), key: u64) u32 {
            _ = this;
            return @intCast(key & std.math.maxInt(u32));
        }
        pub inline fn eql(this: @This(), keyA: u64, keyB: u64, idx: usize) bool {
            _ = idx;
            _ = this;
            return keyA == keyB;
        }
    }, false);
    allocator: std.mem.Allocator,
    _storage: Storage,
};