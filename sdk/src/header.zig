//! Cartridge header related commands
const clap = @import("clap");
const std = @import("std");

const args = @import("args.zig");

pub fn main(io: std.Io, gpa: std.mem.Allocator, iter: *std.process.Args.Iterator, main_args: args.Main.Args) !void {
    _ = main_args;

    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &args.Header.params, clap.parsers.default, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
    }) catch |err| {
        try diag.reportToFile(io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        try std.Io.File.stdout().writeStreamingAll(io, "gbasdk header\n");
        return clap.helpToFile(io, .stdout(), clap.Help, &args.Header.params, .{});
    }

    try std.Io.File.stderr().writeStreamingAll(io, "No command found, use --help to get all commands.\n");
    std.process.exit(1);
}
