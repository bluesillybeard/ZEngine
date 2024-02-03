const testing = @import("std").testing;
const zengine = @import("zengine");
const std = @import("std");
const ecs = @abs("ecs");


// mocking stuff and things
const MockComponent = struct {
    x: f32, y: f32,
    width: f32, height: f32,
};

const MockSystem = struct {
    /// A name for the system. Should only contain letters, numbers, and underscores. no spaces or other characters.
    pub const name: []const u8 = "mock_system";
    /// The list of components added by this system.
    pub const components = [_]type{MockComponent};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        _ = options;
    }

    // initialize fields at runtime.
    pub fn init(this: *@This(), staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) void {
        _ = heapAllocator;
        _ = this;
        _ = staticAllocator;
    }
    // TODO: entity registry
    /// The system init method is much more capible, as it is run after all of the systems have been created in memory.
    /// Systems that other ones might rely on should have a simple way to detect if they have been initialized
    /// and read that value to tell users if they forgot to add a prerequisite system.
    pub fn systemInit(this: *@This(), systemRegistry: zengine.SystemRegistry, entityRegistry: ecs.Registry) !void {
        _ = this;
        _ = systemRegistry;
        _ = entityRegistry;
    }

    pub fn systemDeinit(this: *@This(), systemRegistry: zengine.SystemRegistry, entityRegistry: ecs.Registry) !void {
        _ = this;
        _ = systemRegistry;
        _ = entityRegistry;
    }

    /// Clear out any memory that was allocated using the heap allocator given at init.
    pub fn deinit(this: *@This()) void {
        _ = this;
    }
};

test "Basic test" {
    const ZEngine = zengine.ZEngine(.{
        .globalSystems = &[_]type{MockSystem},
        .localSystems = &[]type{},
    });
    const engine = ZEngine.init(testing.allocator);
    _ = engine; // autofix
}


