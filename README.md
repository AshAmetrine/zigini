# Zigini

A Zig library to read/write an INI file using a struct.

This library requires Zig >=0.16.0. Check releases if you're using an older version.

## Features

- Read and write INI files with plain Zig structs
- INI sections map to nested structs
- Custom type conversion and write serialization hooks
- Optional omission of default values when writing

## Installation

Add the dependency with `zig fetch`:

```sh
zig fetch --save git+https://github.com/ashametrine/zigini
```

Then add it as an import in `build.zig`:

```zig
const zigini_dep = b.dependency("zigini", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zigini", zigini_dep.module("zigini"));
```

## Quick start

```zig
const std = @import("std");
const zigini = @import("zigini");
const Config = @import("Config.zig");

pub fn main(init: std.process.Init) !void {
    var config_reader = zigini.Ini(Config).init(init.gpa);
    defer config_reader.deinit();

    const config = try config_reader.readFileToStruct(init.io, "example/config.ini", .{});

    std.debug.print("Writing ini file to stdout...\n\n", .{});

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    try zigini.writeFromStruct(config, stdout, null, .{});

    try stdout.flush();
}
```

An example is provided in `example/example.zig`.
Run it with `zig build example`.

## Supported types

- Integers and floats (`u8`, `i32`, `f64`, ...)
- Booleans (`true`, `false`, `1`, `0`)
- Enums (string tag name)
- Strings (`[]const u8` and `[:0]const u8`)
- Optionals of any supported type
- Structs and optional structs for sections

Additional types can be supported with `ReadOptions.convert` or `WriteOptions.writeValue`. 

## Notes

- For integer fields, a single non-digit ASCII character is parsed as its byte value (e.g. `a` -> 97).
- Empty strings or `null` map to `null` for optional fields.
- When there are duplicate keys, the last value wins.
