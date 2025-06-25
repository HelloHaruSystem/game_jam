const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const PlayerAnimation = @import("../animation/PlayerAnimation.zig").PlayerAnimation;
const Input = @import("input.zig").Input;
const wind_consts = @import("../utils/constants/screenAndWindow.zig");

pub const Player = struct {
    animation: PlayerAnimation,
    position: rl.Vector2,
    speed: f32,
    fire_speed: f32,
    facing_left: bool,
    is_moving: bool,
    is_attacking: bool,
    fire_timer: f32,
    fire_rate: f32,

    // health values
    max_health: u32,
    current_health: u32,
    damager_timer: f32,     // invincibility frames after taking a hit
    damage_cooldown: f32,   // how long the invincibility will last 
    is_invincible: bool,    // for the visual indicator

    pub fn init() Player {
        return Player{
            .animation = PlayerAnimation.init(),
            .position = rl.Vector2{ .x = 640, .y = 360, }, // center for the 1280x720 screen
            .speed = 200.0, 
            .fire_speed = 300.0,
            .facing_left = false,
            .is_moving = false,
            .is_attacking = false,
            .fire_timer = 0.0,
            .fire_rate = 1.5, // 1.5 shots a second

            // health stuff
            .max_health = 3,            // 3 health
            .current_health = 3,
            .damager_timer = 0.0,
            .damage_cooldown = 1.0,     // 1 second
            .is_invincible = false,
        };
    }

    pub fn update(self: *Player, input: Input, delta_time: f32) void {
        // check if player is trying to move
        const movement = input.getMovementVector();
        const was_moving = self.is_moving;
        self.is_moving = input.hasMovement();

        // only update direction if not attacking
        if (!self.animation.isAttacking()) {
            if (movement.x < 0) {
                self.facing_left = true;     // facing left
            } else if (movement.x > 0) {
                self.facing_left = false;    // facing right
            }
            // in cae of only vertical moving keep the current direction
        }
        
        if (self.is_moving) {
            // calculate new position before moving to check bounds
            const new_position = rl.Vector2{
                .x = self.position.x + movement.x * self.speed * delta_time,
                .y = self.position.y + movement.y * self.speed * delta_time,
            };
            // TODO: move sprite_size to a file with constants
            const sprite_size = 32.0;

            // screen boundary check with clamp to make sure the player stays inside the bounds of the window
            // then applies the new positions
            self.position = clampToScreen(new_position, sprite_size);
        }

        // reset frame when switching between idle and walking for smooths transitions (nice)
        // but not when attacking
        if (was_moving != self.is_moving and !self.animation.isAttacking()) {
            self.animation.resetFrame();
        }

        // update fire timer
        if (self.fire_timer > 0) {
            self.fire_timer -= delta_time;
        } 

        // update damage timer
        if (self.damager_timer > 0) {
            self.damager_timer -= 0;
            if (self.damager_timer <= 0) {
                self.is_invincible = false;
            }
        }

        self.animation.update(self, delta_time);
    }

    pub fn draw(self: *Player, texture: rl.Texture2D) void {
        // Flash Player sprite if invincible
        if (self.is_invincible) {
            const flash_speed = 10.0; // 10 flashed per second
            const show_player = (@mod(@as(u32, @intFromFloat(self.damager_timer * flash_speed)), 2) == 0);
            if (!show_player) return; // skip this frame
        }

        self.animation.draw(self, texture);
    }

    pub fn canShoot(self: *Player) bool {
        return self.fire_timer <= 0;
    }

    pub fn shoot(self: *Player) void {
        self.fire_timer = 1.0 / self.fire_rate;
    }

    fn clampToScreen(position: rl.Vector2, sprite_size: f32) rl.Vector2 {
        const screen_width = @as(f32, @floatFromInt(wind_consts.WINDOW_WIDTH));
        const screen_height = @as(f32, @floatFromInt(wind_consts.WINDOW_HEIGHT));

        return rl.Vector2{
            .x = std.math.clamp(position.x, 0.0, screen_width - sprite_size),
            .y = std.math.clamp(position.y, 0.0, screen_height - sprite_size),
        };
    }

    pub fn getBounds(self: *const Player) rl.Rectangle {
        if (self.is_invincible) return;

        //TODO: move this to a file holding consts
        const player_sprite_size = 32.0;
        return rl.Rectangle{
            .x = self.position.x,
            .y = self.position.y,
            .width = player_sprite_size,
            .height = player_sprite_size,
        };
    }

    pub fn takeDamage(self: *Player, damage: u32) void {
        if (self.is_invincible) return;

        // debug
        std.debug.print("Player taking {} damage! Health: {} -> \n", .{ damage, self.current_health });

        if (self.current_health > damage) {
            self.current_health -= damage;
        } else {
            self.current_health = 0;
        }

        // start invincibility
        self.damager_timer = self.damage_cooldown;
        self.is_invincible = true;

        // TODO: add screen shake, danage sound, and a knockback!
    }

    pub fn isDead(self: *const Player) bool {
        return self.current_health == 0;
    }

};