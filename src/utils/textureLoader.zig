const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const paths = @import("paths.zig");

pub fn loadSprite(allocator: std.mem.Allocator, filename: []const u8) !rl.Texture2D {
    const sprite_path = try paths.getSpriteSheet(allocator, filename);
    defer allocator.free(sprite_path);

    const c_path = try allocator.dupeZ(u8, sprite_path);
    defer allocator.free(c_path);

    return rl.LoadTexture(c_path.ptr);
}

pub fn unloadTexture(texture: rl.Texture2D) void {
    rl.UnloadTexture(texture);
}