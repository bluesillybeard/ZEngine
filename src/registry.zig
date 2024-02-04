const std = @import("std");
const ecs = @import("ecs");
// registries for storing systems and components.

const RegistryMapContext = struct {
    pub inline fn hash(this: @This(), key: usize) u32 {
        _ = this;
        return @intCast(key & std.math.maxInt(u32));
    }
    pub inline fn eql(this: @This(), keyA: usize, keyB: usize, idx: usize) bool {
        _ = idx;
        _ = this;
        return keyA == keyB;
    }
};
// input -> type id
// output -> pointer to the object
// Don't store the hash since hashing is insanely fast - it's literally just a single bitwise and.
const RegistryMap = std.ArrayHashMap(usize, usize, RegistryMapContext, false);

fn hashType(comptime T: type) u64 {
    return std.hash.Fnv1a_64.hash(@typeName(T));
}

pub const SystemRegistryError = error{
    /// is returned if two of the same register is added.
    /// This may also be returned if two types have the same hash.
    DuplicateKeysError,
};

// TODO: add a way to input a check function that verifies a type is valid to use in the thing.
// So that a type that is not valid cannot be added to the registry.
pub const SystemRegistry = struct {
    const This = @This();
    ///The internal structure of data. The allocator for the system registry is stored in this as well.
    storage: RegistryMap,
    ///An arena allocator for this registry
    staticAllocator: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator) This {
        return This{
            .storage = RegistryMap.init(allocator),
            .staticAllocator = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(this: *This) void {
        this.storage.deinit();
        this.staticAllocator.deinit();
    }

    pub fn addRegister(this: *This, comptime T: type, register: *T) SystemRegistryError!void {
        const hash = hashType(T);
        const ptr = @intFromPtr(register);
        const res = this.storage.getOrPut(hash) catch unreachable;
        if (res.found_existing) {
            return SystemRegistryError.DuplicateKeysError;
        }
        res.value_ptr.* = ptr;
    }

    pub fn getRegister(this: This, comptime T: type) ?*T {
        const hash = hashType(T);
        // assume the value is of the correct type.
        // We can assume this because if two different types have the same hash,
        // then something much more problematic is happening.
        const ptr = this.storage.get(hash);
        if (ptr == null) return null;
        return @ptrFromInt(ptr.?);
    }
};

pub const EntityRegistry = struct {
    ecsRegistry: ecs.Registry,
    

};
