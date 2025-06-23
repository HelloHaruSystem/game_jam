const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const PlayerAnimation = @import("../animation/PlayerAnimation.zig").PlayerAnimation;
const Input = @import("input.zig").Input;

pub const Player = struct {
    animation: PlayerAnimation,
    position: rl.Vector2,
    speed: f32,
    fire_speed: f32,
    facing_left: bool,
    is_moving: bool,

    pub fn init() Player {
        return Player{
            .animation = PlayerAnimation.init(),
            .position = rl.Vector2{ .x = 640, .y = 360, }, // center for the 1280x720 screen
            .speed = 200.0, 
            .fire_speed = 1.0,
            .facing_left = false,
            .is_moving = false,
        };
    }

    pub fn update(self: *Player, input: Input, delta_time: f32) void {
        // check if player is trying to move
        const movement = input.getMovementVector();
        const was_moving = self.is_moving;
        self.is_moving = input.hasMovement();

        // update the direction based on horizontal movement
        if (movement.x < 0) {
            self.facing_left = true;     // facing left
        } else if (movement.x > 0) {
            self.facing_left = false;    // facing right
        }
        // in cae of only vertical moving keep the current direction

        if (self.is_moving) {
            const new_x = self.position.x + movement.x * self.speed * delta_time;
            const new_y = self.position.y + movement.y * self.speed * delta_time;

            // screen boundary check goes here
            self.position.x = new_x;
            self.position.y = new_y;
        }

        // reset frame when switching between idle and walking for smooths transitions (nice)
        if (was_moving != self.is_moving) {
            self.animation.resetFrame();
        }

        self.animation.update(self, delta_time);
    }

    pub fn draw(self: *Player, texture: rl.Texture2D) void {
        self.animation.draw(self, texture);
    }
};