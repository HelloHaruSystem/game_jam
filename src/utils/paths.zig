const std = @import("std");
const builtin = @import("builtin");

// asset path
pub fn getAssetPath(allocator: std.mem.Allocator, relative_path: []const u8) ![]u8 {
    const separator = if (builtin.os.tag == .windows) "\\" else "/";
    return std.fmt.allocPrint(allocator, "assets{s}{s}", .{ separator, relative_path });
}

// sprite paths
pub fn getSpriteSheet(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const separator = if (builtin.os.tag == .windows) "\\" else "/";
    return std.fmt.allocPrint(allocator, "assets{s}sprites{s}{s}", .{ separator, separator, filename });
}
