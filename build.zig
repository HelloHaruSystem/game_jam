const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Configure raylib based on target platform
    const raylib_dep = if (target.result.os.tag == .windows)
        b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
        })
    else
        b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
            .linux_display_backend = .X11,
            .shared = false,
        });

    const exe = b.addExecutable(.{
        .name = "haru_jam",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link raylib
    exe.linkLibrary(raylib_dep.artifact("raylib"));

    // Platform-specific linking
    switch (target.result.os.tag) {
        .windows => {
            // Windows libraries
            exe.linkSystemLibrary("opengl32");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("winmm");
            exe.linkSystemLibrary("shell32");

            // to build for windows use "zig build -Dtarget=x86_64-windows"
            // Hide console window on windows
            //exe.addWin32ResourceFile(.{
            //    .file = b.path("app.rc"),
            //    .flags = &.{},
            //});
            exe.subsystem = .Windows;
        },
        .linux => {
            // Linux libraries
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("Xcursor");
            exe.linkSystemLibrary("Xext");
            exe.linkSystemLibrary("Xfixes");
            exe.linkSystemLibrary("Xi");
            exe.linkSystemLibrary("Xinerama");
            exe.linkSystemLibrary("Xrandr");
            exe.linkSystemLibrary("Xrender");
        },
        .macos => {
            // macOS frameworks (if you want to support macOS too)
            exe.linkFramework("OpenGL");
            exe.linkFramework("Cocoa");
            exe.linkFramework("IOKit");
            exe.linkFramework("CoreVideo");
        },
        else => {},
    }

    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Unit test setup
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_unit_tests.linkLibrary(raylib_dep.artifact("raylib"));

    // Link the same libraries for tests
    switch (target.result.os.tag) {
        .windows => {
            exe_unit_tests.linkSystemLibrary("opengl32");
            exe_unit_tests.linkSystemLibrary("gdi32");
            exe_unit_tests.linkSystemLibrary("winmm");
            exe_unit_tests.linkSystemLibrary("shell32");
        },
        .linux => {
            exe_unit_tests.linkSystemLibrary("GL");
            exe_unit_tests.linkSystemLibrary("X11");
            exe_unit_tests.linkSystemLibrary("Xcursor");
            exe_unit_tests.linkSystemLibrary("Xext");
            exe_unit_tests.linkSystemLibrary("Xfixes");
            exe_unit_tests.linkSystemLibrary("Xi");
            exe_unit_tests.linkSystemLibrary("Xinerama");
            exe_unit_tests.linkSystemLibrary("Xrandr");
            exe_unit_tests.linkSystemLibrary("Xrender");
        },
        .macos => {
            exe_unit_tests.linkFramework("OpenGL");
            exe_unit_tests.linkFramework("Cocoa");
            exe_unit_tests.linkFramework("IOKit");
            exe_unit_tests.linkFramework("CoreVideo");
        },
        else => {},
    }

    exe_unit_tests.linkLibC();

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
