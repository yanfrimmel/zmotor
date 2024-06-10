const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.addCSourceFiles(.{ .files = &[_][]const u8{"src/lodepng.c"}, .flags = &[_][]const u8{ "-g", "-O3" } });
    exe.addIncludePath(b.path("src/"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const clean_step = b.step("clean", "Clean up");

    clean_step.dependOn(&b.addRemoveDirTree(b.install_path).step);
    if (@import("builtin").os.tag != .windows) {
        clean_step.dependOn(&b.addRemoveDirTree(b.pathFromRoot("zig-cache")).step);
    }

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.linkLibC();
    unit_tests.linkSystemLibrary("SDL2");
    unit_tests.linkSystemLibrary("SDL2_ttf");
    unit_tests.addCSourceFiles(.{ .files = &[_][]const u8{"src/lodepng.c"}, .flags = &[_][]const u8{ "-g", "-O3" } });
    unit_tests.addIncludePath(b.path("src/"));

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
