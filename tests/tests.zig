const std = @import("std");

test "all" {
    std.testing.refAllDecls(@import("tests/general.zig"));
}
