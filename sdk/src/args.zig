//! Most arguments used for all commands & subcommands
const clap = @import("clap");

pub const Main = struct {
    pub const Subcommands = enum { header };

    pub const parsers = .{
        .command = clap.parsers.enumeration(Subcommands),
    };

    pub const params = clap.parseParamsComptime(
        \\<command>
        \\  header: Get information about cartridge headers
        \\
        \\-h, --help  Display this help and exit.
        \\
    );

    pub const Args = clap.ResultEx(clap.Help, &params, parsers);
};

pub const Header = struct {
    pub const Generate = struct {
        pub const params = clap.parseParamsComptime(
            \\-i, --input <str>     Path to the current cartridge file
            \\-o, --output <str>    Path to the generated (header + cartridge) file
            \\--game-title <str>    Game title inside the header (max 12 bytes)
            \\--game-code <str>     Game code inside the header (max 4 bytes)
            \\--maker-code <str>    Maker code inside the header (max 2 bytes)
            \\
            \\-h, --help  Display this help and exit.
            \\
        );

        pub const Args = clap.ResultEx(clap.Help, &Generate.params, clap.parsers.default);
    };

    pub const Verify = struct {
        pub const params = clap.parseParamsComptime(
            \\<str>
            \\  Path to the cartridge header
            \\
            \\-h, --help  Display this help and exit.
            \\
        );

        pub const Args = clap.ResultEx(clap.Help, &Verify.params, clap.parsers.default);
    };

    pub const Subcommands = enum { generate, verify };

    pub const parsers = .{
        .command = clap.parsers.enumeration(Subcommands),
    };

    pub const params = clap.parseParamsComptime(
        \\<command>
        \\  generate: Add a cartridge header to the given file
        \\
        \\  verify: Verify the entire cartridge header
        \\
        \\-h, --help  Display this help and exit.
        \\
    );

    pub const Args = clap.ResultEx(clap.Help, &params, parsers);
};
