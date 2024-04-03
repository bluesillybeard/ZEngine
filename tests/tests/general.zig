const testing = @import("std").testing;
const zengine = @import("zengine");
const std = @import("std");
const ecs = @import("ecs");

// these tests makes sure the basic functionality of ZEngine works properly.
// They provide a demonstration of its use.

test "BasicTest" {
    var engine = zengine.ZEngine.init(testing.allocator);
    defer engine.deinit();
    var silly = SillySystem.init();
    try engine.registerGlobalSystem(SillySystem, &silly);
    var wonky = WonkySystem.init();
    try engine.registerGlobalSystem(WonkySystem, &wonky);
    wonky.run(&engine);
    // Make sure SillySystem's num variable was incremented by WonkySystem
    try testing.expectEqual(1, engine.getGlobalSystem(SillySystem).?.num);
}

test "LocalSystems" {
    var engine = zengine.ZEngine.init(testing.allocator);
    defer engine.deinit();
    var silly = SillySystem.init();
    try engine.registerGlobalSystem(SillySystem, &silly);

    // Make sure SillySystem's num value is zero
    try testing.expectEqual(0, engine.getGlobalSystem(SillySystem).?.num);

    // Init a local system
    const handle = try engine.initLocalRegistry();
    var s1 = LocalSystemOne.init();
    try engine.registerLocalSystem(handle, LocalSystemOne, &s1);
    var s2 = LocalSystemTwo.init();
    try engine.registerLocalSystem(handle, LocalSystemTwo, &s2);
    try s2.run(handle, &engine);
    // SillySystem's num should have been incremented by LocalSystemtwo
    try testing.expectEqual(1, engine.getGlobalSystem(SillySystem).?.num);
    // LocalSystemOne's num should be 1, also incremented by LocalSystemTwo
    try testing.expectEqual(1, engine.getLocalSystem(handle, LocalSystemOne).?.num);

    // Destroy the local system
    s2.unrun(handle, &engine);
    engine.deinitLocalRegistry(handle);

    // Create a new local system
    const handle2 = try engine.initLocalRegistry();
    var s12 = LocalSystemOne.init();
    try engine.registerLocalSystem(handle2, LocalSystemOne, &s12);
    var s22 = LocalSystemTwo.init();
    try engine.registerLocalSystem(handle2, LocalSystemTwo, &s22);
    try s22.run(handle2, &engine);
    // Still one since num is decremented when LocalSystemTwo is deinited.
    try testing.expectEqual(1, engine.getGlobalSystem(SillySystem).?.num);
    // LocalSystemOne's num should be 1, also incremented by LocalSystemTwo
    try testing.expectEqual(1, engine.getLocalSystem(handle2, LocalSystemOne).?.num);
}

test "TooManyWorlds" {
    var engine = zengine.ZEngine.init(testing.allocator);
    var silly = SillySystem.init();
    try engine.registerGlobalSystem(SillySystem, &silly);
    defer engine.deinit();
    var rand = std.rand.DefaultPrng.init(69420);
    const num = 500;
    for (0..num) |_| {
        const rng = rand.random().float(f32);
        if (rng > 0.5 and engine.getNumLocalSystems() > num / 2) {
            // Find a world to remove
            for (0..engine.getCapacityLocalSystems()) |handle| {
                // It is technically a supported option, however it is not a good idea to do this.
                const sillySystemOrNone = engine.getLocalSystem(handle, SillySystem);
                if (sillySystemOrNone == null) continue;
                engine.deinitLocalRegistry(handle);
                break;
            }
        } else {
            const handle = try engine.initLocalRegistry();
            var s1 = LocalSystemOne.init();
            try engine.registerLocalSystem(handle, LocalSystemOne, &s1);
            var s2 = LocalSystemTwo.init();
            try engine.registerLocalSystem(handle, LocalSystemTwo, &s2);
            try s2.run(handle, &engine);
        }
    }
}

const SillySystem = struct {
    pub fn init() @This() {
        return .{ .num = 0 };
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
    pub fn init() WonkySystem {
        // Returning undefined is safe here, since all of the fields are initialized on systemInit.
        return .{};
    }
    pub fn run(this: *WonkySystem, engine: *zengine.ZEngine) void {
        _ = this;
        const sillySystem = engine.getGlobalSystem(SillySystem) orelse @panic("Could not find silly system");
        sillySystem.sayHi();
    }

    pub fn deinit(this: *@This()) void {
        _ = this;
    }
};

const LocalSystemOne = struct {
    pub fn init() @This() {
        return .{ .num = 0 };
    }

    pub fn deinit(this: *@This()) void {
        _ = this;
    }

    pub fn doThing(this: *@This()) void {
        this.num += 1;
    }
    num: i32,
};

const LocalSystemTwo = struct {
    pub fn init() @This() {
        return .{};
    }

    pub fn run(this: *@This(), handle: zengine.LocalHandle, engine: *zengine.ZEngine) !void {
        _ = this;
        const system1 = engine.getLocalSystem(handle, LocalSystemOne).?;
        system1.doThing();
        const sillySystem = engine.getGlobalSystem(SillySystem).?;
        sillySystem.sayHi();
    }

    pub fn unrun(this: *@This(), handle: zengine.LocalHandle, engine: *zengine.ZEngine) void {
        _ = this;
        _ = handle;
        const sillySystem = engine.getGlobalSystem(SillySystem).?;
        sillySystem.sayBye();
    }

    pub fn deinit(this: *@This()) void {
        _ = this;
    }
};
