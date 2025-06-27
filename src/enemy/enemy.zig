const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const EnemyAnimation = @import("../animation/enemyAnimation.zig").EnemyAnimation;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const EnemyType = enum {
    small_fast,
    medium_normal,
    large_slow,
    boss,

    // TODO: all are the same sprite for now change in the future
    pub fn getStats(self: EnemyType) EnemyStats {
        return switch (self) {
            .small_fast => EnemyStats{
                .max_health = gameConstants.SMALL_ENEMY_HEALTH,
                .speed =gameConstants.SMALL_ENEMY_SPEED,
                .scale = gameConstants.SMALL_ENEMY_SCALE, // default is 0.8
                .sprite_row = gameConstants.ENEMY_WALK_ROW,
            },
            .medium_normal => EnemyStats{
                .max_health = gameConstants.MEDIUM_ENEMY_HEALTH,
                .speed = gameConstants.MEDIUM_ENEMY_SPEED,
                .scale = gameConstants.MEDIUM_ENEMY_SCALE,
                .sprite_row = gameConstants.ENEMY_WALK_ROW,
            },
            .large_slow => EnemyStats{
                .max_health = gameConstants.LARGE_ENEMY_HEALTH,
                .speed = gameConstants.LARGE_ENEMY_SPEED,
                .scale = gameConstants.LARGE_ENEMY_SCALE,
                .sprite_row = gameConstants.ENEMY_WALK_ROW,
            },
            .boss => EnemyStats{
                .max_health = gameConstants.BOSS_ENEMY_HEALTH,
                .speed = gameConstants.BOSS_ENEMY_SPEED,
                .scale = gameConstants.BOSS_ENEMY_SCALE,
                .sprite_row = gameConstants.ENEMY_WALK_ROW,
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
    position: rl.Vector2,
    velocity: rl.Vector2,
    enemy_type: EnemyType,
    current_health: u32,
    max_health: u32,
    speed: f32,
    scale: f32,
    sprite_row: u32,
    facing_left: bool,
    active: bool,
    animation: EnemyAnimation,

    // TODO: add animation file

    pub fn init(spawn_location: rl.Vector2, enemy_type: EnemyType) Enemy {
        const stats = enemy_type.getStats();

        return Enemy{
            .position = spawn_location,
            .velocity = rl.Vector2{ .x = 0, .y = 0 },
            .enemy_type = enemy_type,
            .current_health = stats.max_health,
            .max_health = stats.max_health,
            .speed = stats.speed,
            .scale = stats.scale,
            .sprite_row = stats.sprite_row,
            .facing_left = false,
            .active = true,
            .animation = EnemyAnimation.init(),
        };
    }

    pub fn update(self: *Enemy, player_position: rl.Vector2, delta_time: f32) void {
        if (!self.active) return;

        // calculate player center position
        const player_center_position = rl.Vector2{
            .x = player_position.x + 16,
            .y = player_position.y + 16,
        };

        // move towards player
        self.moveTowardsPlayer(player_center_position, delta_time);

        // update hit flash timer
        self.animation.update(delta_time);

        // check if enemy should be removed
        if (self.current_health == 0) {
            self.active = false;
        }
    }

    pub fn draw(self: *Enemy, texture: rl.Texture2D) void {
        if (!self.active) return;

        // call draw function from the animation file
        self.animation.draw(self, texture);
    }

    pub fn moveTowardsPlayer(self: *Enemy, player_position: rl.Vector2, delta_time: f32) void {
        // calculate direction to player
        const dx = player_position.x - self.position.x;
        const dy = player_position.y - self.position.y;
        const distance = std.math.sqrt(dx * dx + dy * dy);

        if (distance > 0) {
            // update facing direction
            // if negative the player is to the left
            self.facing_left = dx < 0;

            // normalize direction and apply speed
            self.velocity.x = (dx / distance) * self.speed;
            self.velocity.y = (dy / distance) * self.speed;

            // update position
            self.position.x += self.velocity.x * delta_time;
            self.position.y += self.velocity.y * delta_time;
        }
    }

    pub fn takeDamage(self: *Enemy, damage: u32) void {
        if (self.current_health > damage) {
            self.current_health -= damage;
        } else {
            self.current_health = 0;
        }

        // start the hit flash from animation file
        self.animation.startHitFlash();
    }

    pub fn getBounds(self: *const Enemy) rl.Rectangle {
        return self.animation.getBounds(self);
    }

    pub fn isDead(self: *const Enemy) bool {
        return !self.active or self.current_health == 0;
    }
};