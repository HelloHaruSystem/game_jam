const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const PlayerAnimation = @import("../animation/PlayerAnimation.zig").PlayerAnimation;
const Input = @import("input.zig").Input;
const Tilemap = @import("../tilemap/tilemap.zig").Tilemap;
const gameConstants = @import("../utils/constants/gameConstants.zig");

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

    // knock back stuff
    knock_back_velocity: rl.Vector2,
    knock_back_friction: f32,

    pub fn init() Player {
        return Player{
            .animation = PlayerAnimation.init(),
            .position = rl.Vector2{ .x = gameConstants.WINDOW_WIDTH / 2, .y = gameConstants.WINDOW_HEIGHT / 2, }, // center for the 1280x720 screen
            .speed = gameConstants.DEFAULT_PLAYER_SPEED, 
            .fire_speed = gameConstants.DEFAULT_PLAYER_FIRE_SPEED,
            .facing_left = false,
            .is_moving = false,
            .is_attacking = false,
            .fire_timer = 0.0,
            .fire_rate = gameConstants.DEFAULT_PLAYER_FIRE_RATE,

            // health stuff
            .max_health = gameConstants.DEFAULT_PLAYER_MAX_HEALTH,  
            .current_health = gameConstants.DEFAULT_PLAYER_MAX_HEALTH,
            .damager_timer = 0.0,
            .damage_cooldown = gameConstants.DEFAULT_PLAYER_DAMAGE_COOLDOWN,  
            .is_invincible = false,

            // knockback stuff
            .knock_back_velocity = rl.Vector2{ .x = 0.0, .y = 0.0 },
            .knock_back_friction = gameConstants.DEFAULT_PLAYER_KNOCKBACK_FRICTION, // the more the faster decay
        };
    }

    // TODO: split this function up into smaller helper functions
    pub fn update(self: *Player, input: Input, delta_time: f32, tilemap: ?*const Tilemap) void {
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
        }

        // Handle movement with tilemap collision
        if (self.is_moving) {
            if (tilemap) |tm| {
                self.moveWithTileCollision(movement, delta_time, tm);
            } else {
                self.moveWithoutTilemap(movement, delta_time);
            }
        }

        // Handle knockback movement (separate from input movement)
        if (self.knock_back_velocity.x != 0.0 or self.knock_back_velocity.y != 0.0) {
            const knockback_movement = rl.Vector2{
                .x = self.knock_back_velocity.x * delta_time,
                .y = self.knock_back_velocity.y * delta_time,
            };
        
            const new_position = rl.Vector2{
                .x = self.position.x + knockback_movement.x,
                .y = self.position.y + knockback_movement.y,
            };
        
            // Apply knockback if the new position is valid
            const valid = if (tilemap) |tm| 
                self.isPositionValid(new_position, tm) 
            else 
                true;
            
            if (valid) {
                self.position = clampToScreen(new_position, gameConstants.PLAYER_SPRITE_SIZE);
            }
        
            // Apply knockback friction
            self.knock_back_velocity.x *= (1.0 - self.knock_back_friction * delta_time);
            self.knock_back_velocity.y *= (1.0 - self.knock_back_friction * delta_time);
        
            // Stop very small knockbacks
            if (@abs(self.knock_back_velocity.x) < 1.0) {
                self.knock_back_velocity.x = 0.0;
            }
            if (@abs(self.knock_back_velocity.y) < 1.0) {
                self.knock_back_velocity.y = 0.0;
            }
        }

        // reset frame when switching between idle and walking
        if (was_moving != self.is_moving and !self.animation.isAttacking()) {
            self.animation.resetFrame();
        }

        // update fire timer
        if (self.fire_timer > 0) {
            self.fire_timer -= delta_time;
        } 

        // update damage timer
        if (self.damager_timer > 0) {
            self.damager_timer -= delta_time;
            if (self.damager_timer <= 0) {
                self.is_invincible = false;
            }
        }

        self.animation.update(self, delta_time);
    }

    fn moveWithTileCollision(self: *Player, movement: Input.MovementVector, delta_time: f32, tilemap: *const Tilemap) void {
        // Get movement modifier from current tile
        const current_modifier = tilemap.getMovementModifierAt(
            self.position.x + gameConstants.PLAYER_SPRITE_SIZE / 2,
            self.position.y + gameConstants.PLAYER_SPRITE_SIZE / 2
        );
    
        // Calculate movement with tile modifier
        const modified_speed = self.speed * current_modifier;
        const move_x = movement.x * modified_speed * delta_time;
        const move_y = movement.y * modified_speed * delta_time;

        // Try horizontal movement first
        var new_position = rl.Vector2{
            .x = self.position.x + move_x,
            .y = self.position.y,
        };
    
        if (self.isPositionValid(new_position, tilemap)) {
            self.position.x = new_position.x;
        }

        // Then try vertical movement
        new_position = rl.Vector2{
            .x = self.position.x,
            .y = self.position.y + move_y,
        };
    
        if (self.isPositionValid(new_position, tilemap)) {
            self.position.y = new_position.y;
        }

        // Clamp to screen bounds
        self.position = clampToScreen(self.position, gameConstants.PLAYER_SPRITE_SIZE);
    }

    fn moveWithoutTilemap(self: *Player, movement: Input.MovementVector, delta_time: f32) void {
        // Your original movement code
        const total_movement = rl.Vector2{
            .x = movement.x * self.speed * delta_time,
            .y = movement.y * self.speed * delta_time,
        };
    
        const new_position = rl.Vector2{
            .x = self.position.x + total_movement.x,
            .y = self.position.y + total_movement.y,
        };
    
        self.position = clampToScreen(new_position, gameConstants.PLAYER_SPRITE_SIZE);
    }

    fn isPositionValid(self: *const Player, position: rl.Vector2, tilemap: *const Tilemap) bool {
        _ = self;
        const sprite_size = gameConstants.PLAYER_SPRITE_SIZE;
    
        // Check all four corners of the player sprite
        const corners = [_]rl.Vector2{
            rl.Vector2{ .x = position.x, .y = position.y },
            rl.Vector2{ .x = position.x + sprite_size, .y = position.y },
            rl.Vector2{ .x = position.x, .y = position.y + sprite_size },
            rl.Vector2{ .x = position.x + sprite_size, .y = position.y + sprite_size },
        };
    
        for (corners) |corner| {
            if (tilemap.isPositionSolid(corner.x, corner.y)) {
                return false;
            }
        }
    
        return true;
    }

    pub fn draw(self: *Player, texture: rl.Texture2D) void {
        // Flash Player sprite if invincible
        if (self.is_invincible) {
            const show_player = (@mod(@as(u32, @intFromFloat(self.damager_timer * gameConstants.PLAYER_FLASH_SPEED)), 2) == 0);
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
        const screen_width = @as(f32, @floatFromInt(gameConstants.WINDOW_WIDTH));
        const screen_height = @as(f32, @floatFromInt(gameConstants.WINDOW_HEIGHT));

        return rl.Vector2{
            .x = std.math.clamp(position.x, 0.0, screen_width - sprite_size),
            .y = std.math.clamp(position.y, 0.0, screen_height - sprite_size),
        };
    }

    pub fn getBounds(self: *const Player) rl.Rectangle {
        //TODO: move this to a file holding consts
        const player_sprite_size = 32.0;
        return rl.Rectangle{
            .x = self.position.x,
            .y = self.position.y,
            .width = player_sprite_size,
            .height = player_sprite_size,
        };
    }

    pub fn takeDamage(self: *Player, damage: u32, from_position: rl.Vector2) void {
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

        // apply knock back
        const knock_back_strength = gameConstants.DEFAULT_KNOCKBACK_STRENGTH;
        self.applyKnockback(from_position, knock_back_strength);
        // TODO: add screen shake, damage and sound
    }

    pub fn isDead(self: *const Player) bool {
        return self.current_health == 0;
    }
    pub fn applyKnockback(self: *Player, from_position: rl.Vector2, knock_back_strength: f32) void {
        // calculate the direction from enemy to player
        const dx = self.position.x - from_position.x;
        const dy = self.position.y - from_position.y;
        const distance = std.math.sqrt(dx * dx + dy * dy);

        if (distance > 0) {
            // normalize direction and apply strength
            self.knock_back_velocity.x = (dx / distance) * knock_back_strength;
            self.knock_back_velocity.y = (dy / distance) * knock_back_strength;
        }
    }

};