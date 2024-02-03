const testing = @import("std").testing;
const zengine = @import("zengine");
const std = @import("std");
const ecs = @abs("ecs");

const SillySystem = struct {
    /// A name for the system. Should only contain letters, numbers, and underscores. no spaces or other characters.
    pub const name: []const u8 = "silly_system";
    /// The list of components added by this system.
    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        // TODO
        _ = options;
        return true;
    }

    // initialize fields at runtime.
    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return .{.num = 0};
    }
    // TODO: entity registry
    /// The system init method is much more capible, as it is run after all of the systems have been created in memory.
    /// Systems that other ones might rely on should have a simple way to detect if they have been initialized
    /// and read that value to tell users if they forgot to add a prerequisite system.
    pub fn systemInit(this: *@This(), registries: *zengine.RegistrySet) !void {
        _ = registries;
        _ = this;
    }

    pub fn systemDeinit(this: *@This(), registries: *zengine.RegistrySet) !void {
        _ = registries;
        _ = this;
    }

    /// Clear out any memory that was allocated using the heap allocator given at init.
    pub fn deinit(this: *@This()) void {
        _ = this;
    }
    pub fn sayHi(this: *@This()) void {
        this.num += 1;
    }
    pub fn sayBye(this: *@This()) void {
        this.num += 1;
    }
    num: i32,
};

pub const WonkySystem = struct {
/// A name for the system. Should only contain letters, numbers, and underscores. no spaces or other characters.
    pub const name: []const u8 = "wonky_system";
    /// The list of components added by this system.
    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        // TODO
        _ = options;
        return true;
    }

    // initialize fields at runtime.
    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return undefined;
    }
    // TODO: entity registry
    /// The system init method is much more capible, as it is run after all of the systems have been created in memory.
    /// Systems that other ones might rely on should have a simple way to detect if they have been initialized
    /// and read that value to tell users if they forgot to add a prerequisite system.
    pub fn systemInit(this: *@This(), registries: *zengine.RegistrySet) !void {
        this.sillySystem = registries.globalRegistry.getRegister(SillySystem) orelse @panic("Could not find silly system");
        this.sillySystem.sayHi();
    }

    pub fn systemDeinit(this: *@This(), systemRegistry: *zengine.RegistrySet) !void {
        _ = systemRegistry;
        this.sillySystem.sayBye();
    }

    /// Clear out any memory that was allocated using the heap allocator given at init.
    pub fn deinit(this: *@This()) void {
        _ = this;
    }

    sillySystem: *SillySystem,
};

test "Basic test" {
    const ZEngine = zengine.ZEngine(.{
        .globalSystems = &[_]type{SillySystem, WonkySystem},
        .localSystems = &[_]type{},
    });
    var engine = try ZEngine.init(testing.allocator);
    defer engine.deinit();
    // Make sure SillySystem's num variable was incremented by WonkySystem
    try testing.expectEqual(1, engine.registries.globalRegistry.getRegister(SillySystem).?.num);
}


