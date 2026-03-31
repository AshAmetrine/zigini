const reader = @import("reader.zig");
const writer = @import("writer.zig");
pub const Ini = reader.Ini;
pub const IniField = reader.IniField;
pub const defaultConvert = reader.defaultConvert;
pub const defaultConvertWithDelegate = reader.defaultConvertWithDelegate;
pub const defaultWriteValue = writer.defaultWriteValue;
pub const writeFromStruct = writer.writeFromStruct;
