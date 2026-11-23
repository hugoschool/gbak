const std = @import("std");

/// Directly taken from https://www.problemkaputt.de/gbatek-gba-cartridge-header.htm
pub const Header = struct {
    pub const game_title_size = 12;
    pub const game_code_size = 4;
    pub const maker_code_size = 2;

    pub const nintendo_logo_size = 156;

    // Comments have been added on each line to keep formatting
    pub const nintendo_logo_value: [nintendo_logo_size]u8 = .{
        0x24, 0xff, 0xae, 0x51, 0x69, 0x9a, 0xa2, 0x21, 0x3d, 0x84, //
        0x82, 0x0a, 0x84, 0xe4, 0x09, 0xad, 0x11, 0x24, 0x8b, 0x98, //
        0xc0, 0x81, 0x7f, 0x21, 0xa3, 0x52, 0xbe, 0x19, 0x93, 0x09, //
        0xce, 0x20, 0x10, 0x46, 0x4a, 0x4a, 0xf8, 0x27, 0x31, 0xec, //
        0x58, 0xc7, 0xe8, 0x33, 0x82, 0xe3, 0xce, 0xbf, 0x85, 0xf4, //
        0xdf, 0x94, 0xce, 0x4b, 0x09, 0xc1, 0x94, 0x56, 0x8a, 0xc0, //
        0x13, 0x72, 0xa7, 0xfc, 0x9f, 0x84, 0x4d, 0x73, 0xa3, 0xca, //
        0x9a, 0x61, 0x58, 0x97, 0xa3, 0x27, 0xfc, 0x03, 0x98, 0x76, //
        0x23, 0x1d, 0xc7, 0x61, 0x03, 0x04, 0xae, 0x56, 0xbf, 0x38, //
        0x84, 0x00, 0x40, 0xa7, 0x0e, 0xfd, 0xff, 0x52, 0xfe, 0x03, //
        0x6f, 0x95, 0x30, 0xf1, 0x97, 0xfb, 0xc0, 0x85, 0x60, 0xd6, //
        0x80, 0x25, 0xa9, 0x63, 0xbe, 0x03, 0x01, 0x4e, 0x38, 0xe2, //
        0xf9, 0xa2, 0x34, 0xff, 0xbb, 0x3e, 0x03, 0x44, 0x78, 0x00, //
        0x90, 0xcb, 0x88, 0x11, 0x3a, 0x94, 0x65, 0xc0, 0x7c, 0x63, //
        0x87, 0xf0, 0x3c, 0xaf, 0xd6, 0x25, 0xe4, 0x8b, 0x38, 0x0a, //
        0xac, 0x72, 0x21, 0xd4, 0xf8, 0x07, //
    };

    /// Hard coded value (checksum)
    pub const fixed_value = 0x96;

    /// According to the ARMv7TDMI branch instruction encoding.
    /// If you read the manual, the fields are actually reversed due to endianness.
    const BranchInstruction = packed struct(u32) {
        address: u24,
        long: bool,
        opcode: u3,
        cond: u4,
    };

    /// Displays all the content inside the header
    /// Displays if the header is valid or not
    pub fn display(h: Header, io: std.Io) !void {
        var stdout = std.Io.File.stdout().writerStreaming(io, &.{});
        const interface = &stdout.interface;

        {
            const entrypoint_branch: BranchInstruction = @bitCast(h.entrypoint);

            // We're at the very start of the header
            const current_pc = 8;
            // The address MUST fit inside 32 bits, therefore we need to shift it by 2
            const entrypoint_address: u32 = (entrypoint_branch.address << 2) + current_pc;

            try interface.print("ROM Entrypoint:\n", .{});
            try interface.print("  raw: 0x{x}\n", .{h.entrypoint});
            try interface.print("  opcode: {s} 0x{x}\n", .{ if (entrypoint_branch.long) "bl" else "b", entrypoint_address });
            try interface.print("  valid: {s}\n", .{if (Header.verifyEntrypoint(h.entrypoint)) "valid" else "invalid"});
        }

        try interface.print("Nintendo Logo: {s}\n", .{if (Header.verifyNintendoLogo(h.nintendo_logo)) "valid" else "invalid"});
        try interface.print("Game title: {s}\n", .{h.game_title});

        var game_code: [4]u8 = undefined;
        std.mem.writeInt(u32, &game_code, h.game_code, .little);
        try interface.print("Game code: {s} (0x{x})\n", .{ game_code, h.game_code });

        var maker_code: [2]u8 = undefined;
        std.mem.writeInt(u16, &maker_code, h.maker_code, .little);
        try interface.print("Maker code: {s} (0x{x})\n", .{ maker_code, h.maker_code });

        try interface.print("Fixed: {s} (0x{x})\n", .{ if (h.fixed == 0x96) "valid" else "invalid", h.fixed });
        try interface.print("Main unit code: 0x{x}\n", .{h.main_unit_code});
        try interface.print("Device type: 0x{x}\n", .{h.device_type});
        try interface.print("Reserved: 0x{x}\n", .{h.reserved_1});
        try interface.print("Software version: 0x{x}\n", .{h.software_version});

        try interface.print("Complement check:\n", .{});
        try interface.print("  found: 0x{x}\n", .{h.complement_check});
        try interface.print("  calculated: 0x{x}\n", .{h.calculateComplementCheck()});

        try interface.print("Reserved: 0x{x}\n", .{h.reserved_2});
        try interface.print("\n", .{});
        try interface.print("Given cartridge header is {s}\n", .{if (h.verify()) "valid!" else "invalid."});
    }

    /// Calculate the complement check byte
    pub fn calculateComplementCheck(h: Header) u8 {
        // Allow overflow of the complement check byte
        var c: u8 = 0;
        // Turn the structure back into a byte buffer
        const buf: *[@sizeOf(Header)]u8 = @ptrCast(@constCast(&h));

        for (0xA0..(0xBC + 1)) |i| {
            c -%= buf[i];
        }
        c -%= 0x19;
        c &= 0xFF;
        return c;
    }

    /// Verify if the entrypoint instruction is valid
    pub fn verifyEntrypoint(entrypoint: u32) bool {
        const branch: BranchInstruction = @bitCast(entrypoint);

        if (branch.opcode != 0b101) {
            return false;
        }

        return true;
    }

    /// Verify if the nintendo logo is valid
    pub fn verifyNintendoLogo(nintendo_logo: [nintendo_logo_size]u8) bool {
        return std.mem.eql(u8, &nintendo_logo, &nintendo_logo_value);
    }

    /// Verify that the header contains the right values
    pub fn verify(h: Header) bool {
        if (!Header.verifyEntrypoint(h.entrypoint)) {
            return false;
        }

        if (!Header.verifyNintendoLogo(h.nintendo_logo)) {
            return false;
        }

        if (h.fixed != 0x96) {
            return false;
        }

        if (h.complement_check != h.calculateComplementCheck()) {
            return false;
        }
        return true;
    }

    /// Generates a "template" header that can be modified after
    pub fn new() Header {
        const entrypoint = 0xea00002e;

        var header = Header{
            .entrypoint = entrypoint,
            .nintendo_logo = Header.nintendo_logo_value,
            .game_title = @splat(0),
            .game_code = 0,
            .maker_code = 0,
            .fixed = Header.fixed_value,
            .main_unit_code = 0x00,
            .device_type = 0x00,
            .reserved_1 = @splat(0),
            .software_version = 0,
            .complement_check = 0,
            .reserved_2 = 0,
        };

        header.complement_check = header.calculateComplementCheck();

        return header;
    }

    /// 000h    4     ROM Entry Point  (32bit ARM branch opcode, eg. "B rom_start")
    entrypoint: u32 align(1),

    /// 004h    156   Nintendo Logo    (compressed bitmap, required!)
    nintendo_logo: [nintendo_logo_size]u8 align(1),

    /// 0A0h    12    Game Title       (uppercase ascii, max 12 characters)
    game_title: [game_title_size]u8 align(1),

    /// 0ACh    4     Game Code        (uppercase ascii, 4 characters)
    game_code: u32 align(1),

    /// 0B0h    2     Maker Code       (uppercase ascii, 2 characters)
    maker_code: u16 align(1),

    /// 0B2h    1     Fixed value      (must be 96h, required!)
    fixed: u8 align(1),

    /// 0B3h    1     Main unit code   (00h for current GBA models)
    main_unit_code: u8 align(1),

    /// 0B4h    1     Device type      (usually 00h) (bit7=DACS/debug related)
    device_type: u8 align(1),

    /// 0B5h    7     Reserved Area    (should be zero filled)
    reserved_1: [7]u8 align(1),

    /// 0BCh    1     Software version (usually 00h)
    software_version: u8 align(1),

    /// 0BDh    1     Complement check (header checksum, required!)
    complement_check: u8 align(1),

    /// 0BEh    2     Reserved Area    (should be zero filled)
    reserved_2: u16 align(1),
};
