const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const EnemyAnimation = @import("../animation/enemyAnimation.zig").EnemyAnimation;

pub const EnemyType = enum {
    small_fast,
    medium_normal,
    large_slow,
    boss,

    // TODO: all are the same sprite for now change in the future
    // TODO: move some of these values to a file with constants for easy changes
    pub fn getStats(self: EnemyType) EnemyStats {
        return switch (self) {
            .small_fast => EnemyStats{
                .max_health = 1,
                .speed = 220,
                .scale = 0.8,
                .sprite_row = 3,
            },
            .medium_normal => EnemyStats{
                .max_health = 3,
                .speed = 80.0,
                .scale = 1.0,
                .sprite_row = 3,
            },
            .large_slow => EnemyStats{
                .max_health = 5,
                .speed = 50.0,
                .scale = 1.5,
                .sprite_row = 3,
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
    position: rl.Vector2,
    velocity: rl.Vector2,
    enemy_type: EnemyType,
    current_health: u32,
    max_health: u32,
    speed: f32,
    scale: f32,
    sprite_row: u32,
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
            .active = true,
            .animation = EnemyAnimation.init(),
        };
    }

    pub fn update(self: *Enemy, player_position: rl.Vector2, delta_time: f32) void {
        if (!self.active) return;

        // move towards player
        self.moveTowardsPlayer(player_position, delta_time);

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