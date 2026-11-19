//! Cartridge header related commands
const clap = @import("clap");
const std = @import("std");

const args = @import("args.zig");
const cartridge = @import("cartridge.zig");

fn generateWriteToOutput(io: std.Io, input_file_path: []const u8, output_file_path: []const u8, header: *cartridge.Header) !void {
    const dir = std.Io.Dir.cwd();
    const input_file = try dir.openFile(io, input_file_path, .{});
    const output_file = try dir.createFile(io, output_file_path, .{});

    var input_file_reader_ = input_file.reader(io, &.{});
    const input_file_reader = &input_file_reader_.interface;

    var output_file_writer_ = output_file.writer(io, &.{});
    const output_file_writer = &output_file_writer_.interface;

    _ = try output_file_writer.write(@ptrCast(header));

    while (true) {
        var buf: [512]u8 = undefined;

        input_file_reader.readSliceAll(&buf) catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        _ = try output_file_writer.write(&buf);
    }

    var stdout = std.Io.File.stdout().writerStreaming(io, &.{});
    const interface = &stdout.interface;

    try interface.print("Successfully wrote to {s}\n", .{output_file_path});
}

fn writeStringIntoInt(str: []const u8, field: anytype) void {
    const ptr: *[@sizeOf(@TypeOf(field))]u8 = @ptrCast(@constCast(field));

    for (0..str.len) |i| {
        ptr[i] = str[i];
    }
}

const GenerateError = error{InvalidArgumentLength};

fn generateHandleArguments(header: *cartridge.Header, arguments: anytype) !void {
    const game_title = arguments.args.@"game-title" orelse "NO NAME";
    const game_code = arguments.args.@"game-code" orelse "NONA";
    const maker_code = arguments.args.@"maker-code" orelse "NO";

    if ((game_title.len > cartridge.Header.game_title_size) or (game_code.len > cartridge.Header.game_code_size) or (maker_code.len > cartridge.Header.maker_code_size)) {
        return GenerateError.InvalidArgumentLength;
    }

    // TODO: replace copyForward for another
    std.mem.copyForwards(u8, &header.game_title, game_title);

    writeStringIntoInt(game_code, &header.game_code);
    writeStringIntoInt(maker_code, &header.maker_code);

    // Regenerate the complement check after changing metadata
    header.complement_check = header.calculateComplementCheck();
}

fn generateMain(io: std.Io, gpa: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &args.Header.Generate.params, clap.parsers.default, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
        .terminating_positional = 0,
    }) catch |err| {
        try diag.reportToFile(io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        try std.Io.File.stdout().writeStreamingAll(io, "gbasdk header generate\n");
        return clap.helpToFile(io, .stdout(), clap.Help, &args.Header.Generate.params, .{});
    }

    if ((res.args.input == null) or (res.args.output == null)) {
        try std.Io.File.stdout().writeStreamingAll(io, "Missing input (--input) or output (--output) argument\n");
        std.process.exit(1);
    }

    const input_file_path = res.args.input.?;
    const output_file_path = res.args.output.?;

    var header = cartridge.Header.new();

    try generateHandleArguments(&header, &res);

    try generateWriteToOutput(io, input_file_path, output_file_path, &header);
}

fn verifyMain(io: std.Io, gpa: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
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
        .generate => try generateMain(io, gpa, iter),
        .verify => try verifyMain(io, gpa, iter),
    }
}
