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

    pub const Subcommands = enum { verify };

    pub const parsers = .{
        .command = clap.parsers.enumeration(Subcommands),
    };

    pub const params = clap.parseParamsComptime(
        \\<command>
        \\  verify: Verify the entire cartridge header
        \\
        \\-h, --help  Display this help and exit.
        \\
    );

    pub const Args = clap.ResultEx(clap.Help, &params, parsers);
};
