const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const paths = @import("../utils/paths.zig");
const gameConstants = @import("../utils/constants/gameConstants.zig");


pub const TileType = enum(u8) {
    grass = 1,
    water = 2,
    solid = 3,

    pub fn isSolid(self: TileType) bool {
        return self == .solid;
    }

    pub fn getMovementModifier(self: TileType) f32 {
        return switch (self) {
            .grass => 1.0,
            .water => 0.6,
            .solid => 0.0,
        };
    }
};

