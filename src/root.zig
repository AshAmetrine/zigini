const reader = @import("reader.zig");
pub const Ini = reader.Ini;
pub const IniField = reader.IniField;
pub const defaultConvert = reader.defaultConvert;
pub const defaultConvertWithDelegate = reader.defaultConvertWithDelegate;
pub const writeFromStruct = @import("writer.zig").writeFromStruct;
