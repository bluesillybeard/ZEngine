const std = @import("std");
const zengine = @import("zengine.zig");
const ecs = @import("ecs");
// This is a template to be used for creating systems and components

// Components are just normal types. They must have a defined memory layout
pub const ComponentTemplate = extern struct {
    // Put data here
};

// Systems are also just like normal types, and they also must have a defined memory layout
pub const SystemTemplate = extern struct {
    /// A name for the system. Should only contain letters, numbers, and underscores. no spaces or other characters.
    pub const name: []const u8 = "system_template";
    /// The list of components added by this system.
    pub const components = [_]type{ComponentTemplate};
    // This is for verifying the system is in the right registry (global v.s local), and making sure all of the systems this one depends on is present before it.
    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        _ = options;
        return true;
    }

    // This is just for initializing the object at a basic level. Allocate memory that lasts for the lifetime of this system with the static allocator,
    // and other things that may be freed or incur more allocations before deinit should use the heap allocator.
    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return .{};
    }
    // The system init method is much more capible, as it is run after all of the systems have been created in memory.
    // It can get a reference to another system - this is how systems can act like libraries.
    // There is also a settings input for user-defined settings. It is anytype since the same settings object is given to all systems,
    // so its type cannot be pre-determined by ZEngine.
    // Global systems are initialized first.
    pub fn systemInitGlobal(this: *@This(), registries: *zengine.RegistrySet, settings: anytype) !void {
        _ = registries;
        _ = this;
        _ = settings;
    }

    // The system init method is much more capible, as it is run after all of the systems have been created in memory.
    // It can get a reference to another system - this is how systems can act like libraries.
    pub fn systemInitLocal(this: *@This(), registries: *zengine.RegistrySet, handle: zengine.LocalHandle, settings: anytype) !void {
        _ = handle;
        _ = registries;
        _ = this;
        _ = settings;
    }

    // This method probably won't have a lot for most systems, however it is present for doing things like serializing save data or disconnecting from servers.
    // Put simply, it is a deinit method that still has access to all of the systems.
    // Local systems are deinited first.
    pub fn systemDeinitGlobal(this: *@This(), registries: *zengine.RegistrySet) void {
        _ = registries;
        _ = this;
    }

    // This method probably won't have a lot for most systems, however it is present for doing things like serializing save data or disconnecting from servers.
    // Put simply, it is a deinit method that still has access to all of the systems.
    // Local systems are deinited first.
    pub fn systemDeinitLocal(this: *@This(), registries: *zengine.RegistrySet) !void {
        _ = registries;
        _ = this;
    }

    // At a minimum, this method should clear out any memory that was allocated using the heap allocator given at init.
    // don't want to free any memory in the systemDeinit method, as other systems could reference it and freeing memory too early could cause access violations.
    pub fn deinit(this: *@This()) void {
        _ = this;
    }
};
