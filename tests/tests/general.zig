const testing = @import("std").testing;
const zengine = @import("zengine");
const std = @import("std");
const ecs = @import("ecs");

// these tests makes sure the basic functionality of ZEngine works properly.
// They provide a demonstration of its use.

test "BasicTest" {
    const ZEngine = zengine.ZEngine(.{
        .globalSystems = &[_]type{ SillySystem, WonkySystem },
        .localSystems = &[_]type{},
    });
    var engine = try ZEngine.init(testing.allocator);
    defer engine.deinit();
    // Make sure SillySystem's num variable was incremented by WonkySystem
    try testing.expectEqual(1, engine.registries.globalRegistry.getRegister(SillySystem).?.num);
}

test "LocalSystems" {
    const ZEngine = zengine.ZEngine(.{
        .globalSystems = &[_]type{SillySystem},
        .localSystems = &[_]type{ LocalSystemOne, LocalSystemTwo },
    });

    var engine = try ZEngine.init(testing.allocator);
    defer engine.deinit();

    // Make sure SillySystem's num value is zero
    try testing.expectEqual(0, engine.registries.globalRegistry.getRegister(SillySystem).?.num);

    // Init a local system
    const handle = try engine.initLocal(testing.allocator);
    // SillySystem's num should have been incremented by LocalSystemtwo
    try testing.expectEqual(1, engine.registries.globalRegistry.getRegister(SillySystem).?.num);
    // LocalSystemOne's num should be 1, also incremented by LocalSystemTwo
    try testing.expectEqual(1, engine.registries.localRegistries.items[handle].?.getRegister(LocalSystemOne).?.num);

    // Destroy the local system
    engine.deinitLocal(handle);

    // Create a new local system
    const handle2 = try engine.initLocal(testing.allocator);
    // Still one since num is decremented when LocalSystemTwo is deinited.
    try testing.expectEqual(1, engine.registries.globalRegistry.getRegister(SillySystem).?.num);
    // LocalSystemOne's num should be 1, also incremented by LocalSystemTwo
    try testing.expectEqual(1, engine.registries.localRegistries.items[handle2].?.getRegister(LocalSystemOne).?.num);
}

test "TooManyWorlds" {
    const ZEngine = zengine.ZEngine(.{
        .globalSystems = &[_]type{SillySystem},
        .localSystems = &[_]type{ LocalSystemOne, LocalSystemTwo },
    });
    var engine = try ZEngine.init(testing.allocator);
    defer engine.deinit();
    var rand = std.rand.DefaultPrng.init(69420);
    const num = 100;
    for (0..num) |_| {
        const rng = rand.random().float(f32);
        if (rng > 0.5 and engine.registries.localRegistries.items.len > num / 2) {
            // Find a world to remove
            for (engine.registries.localRegistries.items, 0..) |registryOrNone, handle| {
                if (registryOrNone == null) continue;
                engine.deinitLocal(handle);
                break;
            }
        } else {
            _ = try engine.initLocal(testing.allocator);
        }
    }
}

const SillySystem = struct {
    pub const name: []const u8 = "silly_system";
    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        // Silly System has to be a global system, and that's it
        // find SillySystem
        for (options.globalSystems) |GlobalSystem| {
            // if SillySystem is a global system, continue to the next check
            if (comptime std.mem.eql(u8, GlobalSystem.name, name)) {
                // Silly system must not be a local system
                for (options.localSystems) |LocalSystem| {
                    if (comptime std.mem.eql(u8, LocalSystem.name, name)) return false;
                }
                // if it's a global system and not a local system, return true
                return true;
            }
        }
        return false;
    }

    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return .{ .num = 0 };
    }

    pub fn systemInitGlobal(this: *@This(), registries: *zengine.RegistrySet) !void {
        _ = registries;
        _ = this;
    }

    pub fn systemDeinitGlobal(this: *@This(), registries: *zengine.RegistrySet) void {
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
        // Wonky system requires SillySystem to come before it
        // find SillySystem
        for (options.globalSystems, 0..) |GlobalSystem, index| {
            if (comptime std.mem.eql(u8, GlobalSystem.name, SillySystem.name)) {
                // WonkySystem must come after SillySystem
                for (index..options.globalSystems.len) |secondGlobalSystemIndex| {
                    const SecondGlobalSystem = options.globalSystems[secondGlobalSystemIndex];
                    if (comptime std.mem.eql(u8, SecondGlobalSystem.name, WonkySystem.name)) {
                        // SillySystem is a global system, and WonkySystem is a global system that comes after SillySystem
                        return true;
                    }
                }
                @compileLog("WonkySystem must come after SillySystem");
                return false;
            }
        }
        @compileLog("WonkySystem requires SillySystem");
        return false;
    }

    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        // Returning undefined is safe here, since all of the fields are initialized on systemInit.
        return undefined;
    }
    pub fn systemInitGlobal(this: *@This(), registries: *zengine.RegistrySet) !void {
        this.sillySystem = registries.globalRegistry.getRegister(SillySystem) orelse @panic("Could not find silly system");
        this.sillySystem.sayHi();
    }

    pub fn systemDeinitGlobal(this: *@This(), systemRegistry: *zengine.RegistrySet) void {
        _ = systemRegistry;
        this.sillySystem.sayBye();
    }

    pub fn deinit(this: *@This()) void {
        _ = this;
    }
    // Theoretically, it is not the best idea to hold a reference to a system, however there is no reason not to.
    sillySystem: *SillySystem,
};

const LocalSystemOne = struct {
    pub const name: []const u8 = "local_system_1";

    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        _ = options;
        // TODO
        return true;
    }

    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return .{ .num = 0 };
    }

    pub fn systemInitLocal(this: *@This(), registries: zengine.RegistrySet, handle: zengine.LocalHandle) !void {
        _ = handle;
        _ = registries;
        _ = this;
    }

    pub fn systemDeinitLocal(this: *@This(), registries: zengine.RegistrySet, handle: zengine.LocalHandle) void {
        _ = handle;
        _ = registries;
        _ = this;
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
    pub const name: []const u8 = "local_system_2";

    pub const components = [_]type{};

    pub fn comptimeVerification(comptime options: zengine.ZEngineComptimeOptions) bool {
        _ = options;
        // TODO
        return true;
    }

    pub fn init(staticAllocator: std.mem.Allocator, heapAllocator: std.mem.Allocator) @This() {
        _ = heapAllocator;
        _ = staticAllocator;
        return .{};
    }

    pub fn systemInitLocal(this: *@This(), registries: zengine.RegistrySet, handle: zengine.LocalHandle) !void {
        _ = this;
        const registry = &registries.localRegistries.items[handle].?;
        const system1 = registry.getRegister(LocalSystemOne).?;
        system1.doThing();
        const sillySystem = registries.globalRegistry.getRegister(SillySystem).?;
        sillySystem.sayHi();
    }

    pub fn systemDeinitLocal(this: *@This(), registries: zengine.RegistrySet, handle: zengine.LocalHandle) void {
        _ = handle;
        _ = this;
        const sillySystem = registries.globalRegistry.getRegister(SillySystem).?;
        sillySystem.sayBye();
    }

    pub fn deinit(this: *@This()) void {
        _ = this;
    }
};
