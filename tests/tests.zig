const testing = @import("std").testing;
const zengine = @import("zengine");
const std = @import("std");
const ecs = @abs("ecs");

const SillySystem = struct {
    pub const name: []const u8 = "silly_system";
    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        // TODO
        _ = options;
        return true;
    }

    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return .{.num = 0};
    }
    pub fn systemInit(this: *@This(), registries: *zengine.RegistrySet) !void {
        _ = registries;
        _ = this;
    }

    pub fn systemDeinit(this: *@This(), registries: *zengine.RegistrySet) !void {
        _ = registries;
        _ = this;
    }

    pub fn deinit(this: *@This()) void {
        _ = this;
    }
    // The following two methods can be called by other systems
    pub fn sayHi(this: *@This()) void {
        this.num += 1;
    }
    pub fn sayBye(this: *@This()) void {
        this.num -= 1;
    }
    num: i32,
};

pub const WonkySystem = struct {
    pub const name: []const u8 = "wonky_system";
    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        _ = options;
        // TODO
        return true;
    }

    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        // Returning undefined is safe here, since all of the fields are initialized on systemInit.
        return undefined;
    }
    pub fn systemInit(this: *@This(), registries: *zengine.RegistrySet) !void {
        this.sillySystem = registries.globalRegistry.getRegister(SillySystem) orelse @panic("Could not find silly system");
        this.sillySystem.sayHi();
    }

    pub fn systemDeinit(this: *@This(), systemRegistry: *zengine.RegistrySet) !void {
        _ = systemRegistry;
        this.sillySystem.sayBye();
    }

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


