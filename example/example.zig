const std = @import("std");
const zigini = @import("zigini");
const Config = @import("Config.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var config_reader = zigini.Ini(Config).init(allocator);
    defer config_reader.deinit();

    const config = try config_reader.readFileToStruct(init.io, "example/config.ini", .{});

    std.debug.print("Writing ini file to stdout...\n\n", .{});

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    try zigini.writeFromStruct(config, stdout, null, .{ .renameHandler = writeRenameHandler, .write_default_values = false });

    try stdout.flush();
}

fn writeRenameHandler(comptime header: ?[]const u8, comptime field_name: ?[]const u8) ?[]const u8 {
    if (field_name == null) {
        // We can rename the header here
        if (std.mem.eql(u8, header.?, "build_options")) return "build";

        return null; // null = keep the same
    }

    // Here, we are renaming field_name.
    //
    // Note: renaming the header above only renames it in the output
    // so make sure to compare the header with the original name
    // rather than what you renamed it to.
    if (header != null and std.mem.eql(u8, header.?, "build_options")) {
        if (std.mem.eql(u8, field_name.?, "release")) return "optimize";
    }

    // returning null removes the field from the output
    if (std.mem.eql(u8, field_name.?, "version")) return null;

    return field_name;
}
