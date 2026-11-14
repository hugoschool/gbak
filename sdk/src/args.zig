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
    pub const Subcommands = enum {};

    pub const parsers = .{
        .command = clap.parsers.enumeration(Subcommands),
    };

    pub const params = clap.parseParamsComptime(
        \\-h, --help  Display this help and exit.
        \\
    );

    pub const Args = clap.ResultEx(clap.Help, &params, parsers);
};
