const std = @import("std");
const jetzig_build = @import("jetzig");
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    const jetzig_dep = b.dependency("jetzig", .{ .optimize = optimize, .target = target });
    const compile_view_step = jetzig_build.CompileViewsStep.create(b, .{ .template_path = "src/app/views/" });

    const lib = b.addStaticLibrary(.{
        .name = "jetzig-demo",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "jetzig-demo",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("jetzig", jetzig_dep.module("jetzig"));
    exe.root_module.addImport("zmpl", jetzig_dep.module("zmpl"));

    b.installArtifact(exe);
    exe.step.dependOn(&compile_view_step.step);

    const generate_routes = b.option(
        bool,
        "jetzig_generate_routes",
        "Generate routes only. Pre-build step required before application build.",
    ) orelse false;

    const compile_static_routes = b.option(
        bool,
        "jetzig_compile_static_routes",
        "Compile static routes. Generate static content before application build.",
    ) orelse false;

    if (generate_routes and compile_static_routes) {
        @panic("Incompatible options: jetzig_generate_routes and jetzig_compile_static_routes");
    }

    if (generate_routes) {
        const generate_routes_step = try jetzig_build.GenerateRoutesStep.create(b, .{
            .views_path = "src/app/views/",
        });
        exe.step.dependOn(&generate_routes_step.step);
    } else if (compile_static_routes) {
        const routes = @import("src/app/views/routes.zig");
        try jetzig_build.compileStaticRoutes(b, routes);
    } else {
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
