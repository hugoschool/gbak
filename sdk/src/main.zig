const clap = @import("clap");
const std = @import("std");

const args = @import("args.zig");
const header = @import("header.zig");

pub fn main(init: std.process.Init) !void {
    var iter = try init.minimal.args.iterateAllocator(init.gpa);
    defer iter.deinit();

    _ = iter.next();

    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &args.Main.params, args.Main.parsers, &iter, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
        .terminating_positional = 0,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        try std.Io.File.stdout().writeStreamingAll(init.io, "gbasdk - An SDK to help with GBA kernel compilation\n");
        return clap.helpToFile(init.io, .stdout(), clap.Help, &args.Main.params, .{});
    }

    const command = res.positionals[0];

    if (command == null) {
        try std.Io.File.stderr().writeStreamingAll(init.io, "No command found, use --help to get all commands.\n");
        std.process.exit(1);
    }

    switch (command.?) {
        .header => try header.main(init.io, init.gpa, &iter, res),
    }
}
