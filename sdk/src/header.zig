//! Cartridge header related commands
const clap = @import("clap");
const std = @import("std");

const args = @import("args.zig");
const cartridge = @import("cartridge.zig");

pub fn verifyMain(io: std.Io, gpa: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &args.Header.Verify.params, clap.parsers.default, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
        .terminating_positional = 0,
    }) catch |err| {
        try diag.reportToFile(io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        try std.Io.File.stdout().writeStreamingAll(io, "gbasdk header verify\n");
        return clap.helpToFile(io, .stdout(), clap.Help, &args.Header.Verify.params, .{});
    }

    const cartridge_path = res.positionals[0];

    if (cartridge_path == null) {
        try std.Io.File.stderr().writeStreamingAll(io, "No cartridge path given\n");
        std.process.exit(1);
    }

    const dir = std.Io.Dir.cwd();
    var buf: [@sizeOf(cartridge.Header)]u8 align(@alignOf(cartridge.Header)) = undefined;

    _ = try dir.readFile(io, cartridge_path.?, &buf);

    const header: *cartridge.Header = @ptrCast(&buf);
    try header.display(io);
}

pub fn main(io: std.Io, gpa: std.mem.Allocator, iter: *std.process.Args.Iterator, main_args: args.Main.Args) !void {
    _ = main_args;

    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &args.Header.params, args.Header.parsers, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
        .terminating_positional = 0,
    }) catch |err| {
        try diag.reportToFile(io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        try std.Io.File.stdout().writeStreamingAll(io, "gbasdk header\n");
        return clap.helpToFile(io, .stdout(), clap.Help, &args.Header.params, .{});
    }

    const command = res.positionals[0];

    if (command == null) {
        try std.Io.File.stderr().writeStreamingAll(io, "No command found, use --help to get all commands.\n");
        std.process.exit(1);
    }

    switch (command.?) {
        .verify => try verifyMain(io, gpa, iter),
    }
}
