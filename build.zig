const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    //ZEngine depends on zig-ecs
    const ecs = b.createModule(.{
        .root_source_file = .{ .path = "zig-ecs/src/ecs.zig" },
        .target = target,
        .optimize = optimize,
    });

    // ZEngine is intended to be included as source code as a module like this
    const zengine = b.createModule(.{
        .root_source_file = .{ .path = "src/zengine.zig" },
        .target = target,
        .optimize = optimize,
    });
    zengine.addImport("ecs", ecs);

    // This is for running tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/tests.zig" },
        .name = "tests",
        .optimize = optimize,
        .target = target,
    });
    tests.root_module.addImport("ecs", ecs);
    tests.root_module.addImport("zengine", zengine);
    const runTest = b.addRunArtifact(tests);
    runTest.step.dependOn(&tests.step);
    const testStep = b.step("test", "Run tests");
    testStep.dependOn(&runTest.step);
}
