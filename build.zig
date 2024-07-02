const std = @import("std");

/// true - Add the prebuilt libsys_lib.a as a link dependency to "static_library" via a "system" library command (demonstrates the bug)
/// false - Build "sys_lib" from source and add as a link dependency to "static_library" (demonstrates normal behavior)
const system_library_method = false;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Static library that depends on our "sys_lib" pre-compiled system library
    const static_lib = b.addStaticLibrary(.{ .name = "staticlib", .target = target, .optimize = optimize });
    static_lib.addCSourceFiles(.{
        .files = &.{"static_library/staticlib.c"},
    });
    static_lib.addIncludePath(b.path("static_library"));
    static_lib.installHeadersDirectory(b.path("static_library"), "staticlib", .{});

    if (system_library_method) {
        // Reference the pre-built static library in prebuilt_sys_lib instead of building the static library ourselves
        static_lib.addSystemIncludePath(.{ .cwd_relative = "/home/hayden/Documents/zig/archiver_bug/prebuilt_sys_lib/include" });
        static_lib.installHeadersDirectory(.{ .cwd_relative = "/home/hayden/Documents/zig/archiver_bug/prebuilt_sys_lib/include" }, "", .{});
        static_lib.addLibraryPath(.{ .cwd_relative = "/home/hayden/Documents/zig/archiver_bug/prebuilt_sys_lib/lib" });
        static_lib.linkSystemLibrary2("sys_lib", .{
            .needed = true,
            .preferred_link_mode = .static,
            .use_pkg_config = .no,
        });
    } else {
        // Build the static library ourselves and link this way
        const sys_lib = b.addStaticLibrary(.{ .name = "sys_lib", .target = target, .optimize = optimize });
        sys_lib.addCSourceFiles(.{ .files = &.{
            "sys_lib/sys_lib.c",
        } });
        sys_lib.addIncludePath(b.path("sys_lib"));
        sys_lib.installHeadersDirectory(b.path("sys_lib"), "", .{});
        b.installArtifact(sys_lib);
        static_lib.linkLibrary(sys_lib);
        static_lib.installLibraryHeaders(sys_lib);
    }
    b.installArtifact(static_lib);

    // Exe that links against our static library
    const exe = b.addExecutable(.{ .name = "main", .target = target, .optimize = optimize, .link_libc = true });
    exe.addCSourceFiles(.{ .files = &.{
        "src/main.c",
    } });
    exe.linkLibrary(static_lib);

    if (system_library_method) {
        for (static_lib.root_module.lib_paths.items) |path| {
            exe.addLibraryPath(path);
        }
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
