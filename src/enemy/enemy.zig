const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const EnemyType = enum {
    small_fast,
    medium_normal,
    large_slow,
    boss,

    pub fn getStats(self: EnemyType) EnemyStats {
        return switch (self) {
            .small_fast => EnemyStats{
                .max_health = 1,
                .speed = 120,
                .scale = 0.8,
                .sprite_row = 0,
            },
            .medium_normal => EnemyStats{
                .max_health = 3,
                .speed = 80.0,
                .scale = 1.0,
                .sprite_row = 1,
            },
            .large_slow => EnemyStats{
                .max_health = 5,
                .speed = 50.0,
                .scale = 1.5,
                .sprite_row = 2,
            },
            .boss => EnemyStats{
                .max_health = 20,
                .speed = 30.0,
                .scale = 2.0,
                .sprite_row = 3,
            },
        };
    }
};

pub const EnemyStats = struct {
    max_health: u32,
    speed: f32,
    scale: f32,
    sprite_row: u32,
};

pub const Enemy = struct {

};