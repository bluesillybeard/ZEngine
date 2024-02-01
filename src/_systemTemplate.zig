const std = @import("std");
const registry = @import("registry.zig");
const zengine = @import("zengine.zig");
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
    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        _ = options;
        // This function should return false OR compile error if the given options do not work for this system.
        // checklist:
        // - all prerequisite systems are placed before this in the list of systems
        // - this system is placed in the right list (global v.s local)
        // - there aren't any systems that clash with this one.
    }

    // create an instance of this system, as well as initialize any other static objects at runtime.
    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) *SystemTemplate {
        // The template system has a simple initialization and allocation.
        // The static allocator will not do anything on free() calls, as it is a simple arena allocator.
        _ = heapAllocator;
        return staticAllocator.create(SystemTemplate);
    }
    // TODO: entity registry
    /// The system init method is much more capible, as it is run after all of the systems have been created in memory.
    /// Systems that other ones might rely on should have a simple way to detect if they have been initialized
    /// and read that value to tell users if they forgot to add a prerequisite system.
    pub fn systemInit(this: *SystemTemplate, systemRegistry: registry.SystemRegistry, entityRegistry: void) !void {
        _ = this;
        _ = systemRegistry;
        _ = entityRegistry;
        // TODO: do a bunch of stuff to demonstrate what this method is for
    }

    pub fn systemDeinit(this: *SystemTemplate, systemRegistry: registry.SystemRegistry, entityRegistry: void) !void {
        _ = this;
        _ = systemRegistry;
        _ = entityRegistry;
        //TODO: do stuff
    }

    /// Clear out any memory that was allocated using the heap allocator given at init.
    pub fn deinit(this: *SystemTemplate) void {
        _ = this;

    }
};

