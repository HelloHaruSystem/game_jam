const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;

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

    // Row-based animation (0-indexed)
    const IDLE_ROW = 4;
    const WALK_ROW = 3;
    const ATTACK_ROW = 8;

    const WALK_FRAME_COUNT = 8;     // 8 frames for walking 0-7
    const IDLE_FRAME_COUNT = 6;     // 6 frames for idle animation 0-5+
    const ATTACK_FRAME_COUNT = 8;   // 8 frames for walking 0-7

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
                    self.current_frame = (self.current_frame + 1) % ATTACK_FRAME_COUNT;
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
                self.current_frame = (self.current_frame + 1) % WALK_FRAME_COUNT;
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
                self.current_frame = (self.current_frame + 1) % IDLE_FRAME_COUNT;
                self.frame_timer = 0.0;
            }
        }
        
    }

    pub fn draw(self: *PlayerAnimation, player: *const Player, texture: rl.Texture2D) void {
        const row: u32 = switch (self.current_state) {
            .idle => IDLE_ROW,
            .walking => WALK_ROW,
            .attacking => ATTACK_ROW,
        };

        const source_rectangle = rl.Rectangle{
            .x = @floatFromInt(self.current_frame * 32), // TODO: add constants instead of hard coding this (it's 32 because of the sprites being 32x32)
            .y = @floatFromInt(row * 32),
            .width = if (player.facing_left) -32 else 32,
            .height = 32,
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
        self.attack_timer = ATTACK_FRAME_COUNT * self.attack_duration;
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