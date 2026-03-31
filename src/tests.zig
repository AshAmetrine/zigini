const std = @import("std");
const ini = @import("zigini");
const Ini = ini.Ini;

const NestedConfig = struct {
    string: []const u8 = "",
    num: u8 = 0,
};

const Config = struct {
    string: ?[]const u8 = "Default String",
    nt_string: [:0]const u8 = "",
    num: u8 = 1,
    nested_config: NestedConfig = .{},
    @"Other Config": ?NestedConfig = null,
};

const NumberOrText = union(enum) {
    int: i32,
    str: []const u8,
};

const UnionConfig = struct {
    value: NumberOrText = .{ .int = 0 },
    opt_value: ?NumberOrText = .{ .str = "abc" },
    num: u8 = 0,
};

fn handleField(arena: std.mem.Allocator, field: ini.IniField) ?ini.IniField {
    var mapped_field = field;

    const header = arena.alloc(u8, 13) catch return null;
    @memcpy(header, "nested_config");

    if (std.mem.eql(u8, field.header, "Nested Config")) mapped_field.header = header;
    if (std.mem.eql(u8, field.key, "other")) mapped_field.key = "num";

    return mapped_field;
}

test "Read: no field handler" {
    var reader = std.Io.Reader.fixed(
        \\string=A String
        \\string=Default String
        \\nt_string=Another String
        \\num=33
        \\[nested_config]
        \\string=Nested String
        \\num=62
        \\[Other Config]
        \\num=10
    );

    var ini_conf = Ini(Config).init(std.testing.allocator);
    defer ini_conf.deinit();
    const config = try ini_conf.readToStruct(&reader, .{});

    try std.testing.expectEqualStrings("Default String", config.string.?);
    try std.testing.expectEqualStrings("Another String", config.nt_string);
    try std.testing.expectEqualStrings("Nested String", config.nested_config.string);
    try std.testing.expect(config.num == 33);
    try std.testing.expect(config.nested_config.num == 62);
    try std.testing.expect(config.@"Other Config".?.num == 10);
}

test "Read: with field handler" {
    var reader = std.Io.Reader.fixed(
        \\other=33
        \\[Nested Config]
        \\other=12
    );

    var ini_conf = Ini(Config).init(std.testing.allocator);
    defer ini_conf.deinit();

    const config = try ini_conf.readToStruct(&reader, .{ .fieldHandler = handleField });

    try std.testing.expect(config.num == 33);
    try std.testing.expect(config.nested_config.num == 12);
}

fn mapFields(comptime header: ?[]const u8, comptime name: ?[]const u8) ?[]const u8 {
    if (name == null) {
        if (std.mem.eql(u8, header.?, "nested_config")) return "Nested Config";
        return null;
    }

    if (std.mem.eql(u8, name.?, "string")) return "new_string";
    return name;
}

test "Write: no namespace" {
    const conf = Config{
        .num = 10,
        .string = "String!",
        .nested_config = .{ .num = 71, .string = "A Random String" },
    };

    var buf: [100]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    try ini.writeFromStruct(conf, &writer, null, .{ .renameHandler = mapFields, .write_default_values = false });
    const ini_str = writer.buffer[0..writer.end];

    const expected =
        \\new_string=String!
        \\num=10
        \\[Nested Config]
        \\new_string=A Random String
        \\num=71
        \\
    ;

    try std.testing.expect(ini_str.len == expected.len);
    try std.testing.expectEqualStrings(expected, ini_str);
}

test "Write: with namespace" {
    const conf = Config{ .num = 98, .string = "Some String", .nested_config = .{ .num = 71 } };

    var buf: [100]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    try ini.writeFromStruct(conf, &writer, "A Namespace", .{ .write_default_values = false });
    const ini_str = writer.buffer[0..writer.end];

    const expected =
        \\[A Namespace]
        \\string=Some String
        \\num=98
        \\
    ;
    try std.testing.expect(ini_str.len == expected.len);
    try std.testing.expectEqualStrings(expected, ini_str);
}

fn customConvert(allocator: std.mem.Allocator, comptime T: type, value: []const u8) anyerror!T {
    if (T == NumberOrText) {
        if (std.fmt.parseInt(i32, value, 10)) |num| {
            return @unionInit(T, "int", num);
        } else |_| {}

        const str = try allocator.dupe(u8, value);
        return @unionInit(T, "str", str);
    }

    return ini.defaultConvertWithDelegate(allocator, T, value, customConvert);
}

test "Read with custom converter: union" {
    var reader = std.Io.Reader.fixed(
        \\value=hello world
        \\opt_value=2
        \\num=12
    );

    var ini_conf = Ini(UnionConfig).init(std.testing.allocator);
    defer ini_conf.deinit();

    const config = try ini_conf.readToStruct(&reader, .{ .convert = customConvert });

    switch (config.value) {
        .int => try std.testing.expect(false),
        .str => |v| try std.testing.expectEqualStrings("hello world", v),
    }

    try std.testing.expect(config.opt_value != null);

    switch (config.opt_value.?) {
        .int => |v| try std.testing.expectEqual(2, v),
        .str => try std.testing.expect(false),
    }

    try std.testing.expectEqual(12, config.num);
}
