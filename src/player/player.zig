const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const Player = struct {
    position: rl.Vector2,
    speed: f32,
    fire_speed: f32,
    facing_left: bool,
    is_moving: bool,

    pub fn init() Player {
        return Player{
            .position = rl.Vector2{ .x = 640, .y = 360, }, // center for the 1280x720 screen
            .speed = 1.0,
            .fire_speed = 1.0,
            .facing_left = false,
            .is_moving = false,
        };
    }

    pub fn update(_: *Player) void {
        // handle movement here
    }
};