const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;
const ProjectileManager = @import("../projectile/projectile.zig").ProjectileManager;
const EnemyManager = @import("../enemy/enemyManager.zig").EnemyManager;
const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;

pub const PlayingState = struct {
    // playing specific values/states
    wave_number: u32,
    score: u32,

    pub fn init() PlayingState{
        return PlayingState{
            .wave_number = 0,
            .score = 0,
        };
    }

    pub fn update(
        self: *PlayingState,
        player: *Player,
        projectile_manager: *ProjectileManager,
        enemy_manager: *EnemyManager,
        input: Input,
        delta_time: f32,
        ) ?GameSate {
            
    }

    pub fn reset(_: *PlayingState) {

    }

    fn shouldPlayerShoot() {

    }

    fn handlePlayerShooting() {

    }

    fn getPlayerCenter() {

    }
};