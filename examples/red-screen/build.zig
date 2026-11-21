const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            // Our target is arm-none-eabi
            .cpu_arch = .arm,
            .abi = .eabi,
            .os_tag = .freestanding,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "redscreen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addAssemblyFile(b.path("bootstrap.S"));
    exe.setLinkerScript(b.path("gba.ld"));

    b.installArtifact(exe);

    const bin = b.addObjCopy(exe.getEmittedBin(), .{
        .format = .binary,
    });
    bin.step.dependOn(&exe.step);

    // The building system works without copying to a .bin file,
    // however this might be useful for debugging purposes
    const copy_bin = b.addInstallBinFile(bin.getOutput(), "redscreen.bin");
    copy_bin.step.dependOn(&bin.step);

    const gba = b.addSystemCommand(&.{
        "zig",
        "build",
        "run",
        "--",
        "header",
        "generate",
    });
    gba.addPrefixedFileArg("-i", bin.getOutput());
    // TODO: find a way as to not hardcode the zig-out prefix path
    gba.addPrefixedFileArg("-o", b.path("zig-out/bin/redscreen.gba"));

    gba.setCwd(b.path("../../sdk"));
    gba.step.dependOn(&copy_bin.step);

    b.default_step.dependOn(&gba.step);
}
