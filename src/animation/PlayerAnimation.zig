const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const AnimationState = enum {
    idle,
    walking,
    attacking,
};

pub const PlayerAnimation = struct {
    current_frame: u32,
    frame_timer: f32,
    frame_duration: f32, // how long each frame will show
    current_state:AnimationState,
    attack_timer: f32,
    attack_duration: f32,
    projectile_spawned: bool, // track if projectile was already spawned for this attack

    pub fn init() PlayerAnimation {
        return PlayerAnimation{
            .current_frame = 0,
            .frame_timer = 0.0,
            .frame_duration = 0.15,             // 7fps animation
            .current_state = .idle,  // start at idle state
            .attack_timer = 0.0,
            .attack_duration = 0.04,            // attack faster then moving
            .projectile_spawned = false,
        };
    }

    pub fn update(self: *PlayerAnimation, player: *const Player, delta_time: f32) void {
        // handle attack animation timing
        if (self.current_state == .attacking) {
            self.attack_timer -= delta_time;
            if (self.attack_timer <= 0.0) {
                // attack animation finished return to normal state (walking or idle)
                self.current_state = if (player.is_moving) .walking else .idle;
                self.current_frame = 0;
                self.frame_timer = 0.0;
                self.projectile_spawned = false; // reset for next attack
            } else {
                // keep using attack animation
                self.frame_timer += delta_time;
                if (self.frame_timer >= self.attack_duration) {
                    self.current_frame = (self.current_frame + 1) % gameConstants.PLAYER_ATTACK_FRAME_COUNT;
                    self.frame_timer = 0.0;
                }
                return; // return to skip walking or idle animation
            }
        }

        // normal movement or idle animation
        if (player.is_moving and self.current_state != .attacking) {
            if (self.current_state != .walking) {
                self.current_state = .walking;
                self.current_frame = 0;
                self.frame_timer = 0.0;
            }

            self.frame_timer += delta_time;
            if (self.frame_timer >= self.frame_duration) {
                self.current_frame = (self.current_frame + 1) % gameConstants.PLAYER_WALK_FRAME_COUNT;
                self.frame_timer = 0.0;

                // DEBUG: Print to see the frame sequence
                // std.debug.print("Walking frame: {}\n", .{self.current_frame});
            }
        } else if (!player.is_moving and self.current_state != .attacking) {
            if (self.current_state != .idle) {
                self.current_state = .idle;
                self.current_frame = 0;
                self.frame_timer = 0.0;
            }

            self.frame_timer += delta_time;
            if (self.frame_timer >= self.frame_duration) {
                self.current_frame = (self.current_frame + 1) % gameConstants.PLAYER_IDLE_FRAME_COUNT;
                self.frame_timer = 0.0;
            }
        }
        
    }

    pub fn draw(self: *PlayerAnimation, player: *const Player, texture: rl.Texture2D) void {
        const row: u32 = switch (self.current_state) {
            .idle => gameConstants.PLAYER_IDLE_ROW,
            .walking => gameConstants.PLAYER_WALK_ROW,
            .attacking => gameConstants.PLAYER_ATTACK_ROW,
        };

        const source_rectangle = rl.Rectangle{
            .x = @floatFromInt(self.current_frame * gameConstants.PLAYER_SPRITE_SIZE),
            .y = @floatFromInt(row * gameConstants.PLAYER_SPRITE_SIZE),
            .width = if (player.facing_left) -gameConstants.PLAYER_SPRITE_SIZE else gameConstants.PLAYER_SPRITE_SIZE,
            .height = gameConstants.PLAYER_SPRITE_SIZE,
        };

        rl.DrawTextureRec(texture, source_rectangle, player.position, rl.WHITE);
    }

    pub fn resetFrame(self: *PlayerAnimation) void {
        self.current_frame = 0;
        self.frame_timer = 0.0;
    }

    pub fn startAttack(self: *PlayerAnimation) void {
        self.current_state = .attacking;
        self.current_frame = 0;
        self.frame_timer = 0.0;
        self.attack_timer = gameConstants.PLAYER_ATTACK_FRAME_COUNT * self.attack_duration;
        self.projectile_spawned = false; 
    }

    pub fn isAttacking (self: *const PlayerAnimation) bool {
        return self.current_state == .attacking;
    }

    pub fn shouldSpawnProjectile(self: *PlayerAnimation) bool {
        // spawn projectile on frame 3 but only once per attack
        if (self.current_state == .attacking and
            self.current_frame == 3 and
            !self.projectile_spawned) {
            
            self.projectile_spawned = true;
            return true;
        }
        return false;
    }
};