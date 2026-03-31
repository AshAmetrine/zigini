const LogLevel = enum {
    debug,
    info,
    warn,
    err,
};

const ReleaseMode = enum {
    debug,
    safe,
    fast,
    small,
};

const BuildOptions = struct {
    release: ReleaseMode = .debug,
    log_level: LogLevel = .info,
    strip: bool = false,
};

const Git = struct {
    owner: []const u8 = "",
    repo: []const u8 = "",
    branch: ?[:0]const u8 = null,
};

project_name: []const u8 = "zig-project",
version: []const u8 = "0.1.0",
build_options: BuildOptions = .{},
git: Git = .{},
