const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Enemy = @import("../enemy/enemy.zig").Enemy;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const EnemyAnimation = struct {
    current_frame: u32,
    frame_timer: f32,
    frame_duration: f32,
    hit_timer: f32,

    pub fn init() EnemyAnimation {
        return EnemyAnimation{
            .current_frame = 0,
            .frame_timer = 0.0,
            .frame_duration = 0.15, // animation speed,
            .hit_timer = 0.0,
        };
    }

    pub fn update(self: *EnemyAnimation, delta_time: f32) void {
        // update animation frames
        self.frame_timer += delta_time;
        if (self.frame_timer >= self.frame_duration) {
            self.current_frame = (self.current_frame + 1) % gameConstants.ENEMY_FRAME_COUNT;
            self.frame_timer = 0.0;
        }

        // update hit flash timer
        if (self.hit_timer > 0) {
            self.hit_timer -= delta_time;
        }
    }

    pub fn draw(self: *const EnemyAnimation, enemy: *const Enemy, texture: rl.Texture2D) void {
        const scaled_size = gameConstants.ENEMY_SPRITE_SIZE * enemy.scale;

        const source_rectangle = rl.Rectangle{
            .x = @floatFromInt(self.current_frame * gameConstants.ENEMY_SPRITE_SIZE),
            .y = @floatFromInt(enemy.sprite_row * gameConstants.ENEMY_SPRITE_SIZE),
            .width = if (enemy.facing_left) -gameConstants.ENEMY_SPRITE_SIZE else gameConstants.ENEMY_SPRITE_SIZE,
            .height = gameConstants.ENEMY_SPRITE_SIZE,
        };

        const destination_rectangle = rl.Rectangle{
            .x = enemy.position.x,
            .y = enemy.position.y,
            .width = scaled_size,
            .height = scaled_size,
        };

        const origin = rl.Vector2{
            .x = scaled_size / 2, // for center
            .y = scaled_size / 2,
        };

        // flash red when hit
        const tint = if (self.hit_timer > 0) rl.RED else rl.WHITE;

        rl.DrawTexturePro(texture, source_rectangle, destination_rectangle, origin, 0.0, tint);
    }

    pub fn startHitFlash(self: *EnemyAnimation) void {
        self.hit_timer = gameConstants.HIT_FLASH_DURATION;
    }

    pub fn isFlashing(self: *const EnemyAnimation) bool {
        return self.hit_timer > 0;
    }

    pub fn reset (self: *EnemyAnimation) void {
        self.current_frame = 0;
        self.frame_timer = 0.0;
        self.hit_timer = 0.0;
    }

    pub fn getBounds(_: *const EnemyAnimation, enemy: *const Enemy) rl.Rectangle {
        const scaled_size = gameConstants.ENEMY_SPRITE_SIZE * enemy.scale;
        return rl.Rectangle{
            .x = enemy.position.x - (scaled_size / 2),
            .y = enemy.position.y - (scaled_size / 2),
            .width = scaled_size,
            .height = scaled_size,
        };
    }
};