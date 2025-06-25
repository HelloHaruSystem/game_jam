const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;
const ProjectileManager = @import("../projectile/projectile.zig").ProjectileManager;
const EnemyManager = @import("../enemy/enemyManager.zig").EnemyManager;
const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const GameConstants = @import("../utils/constants/gameConstants.zig");

pub const PlayingState = struct {
    // playing specific values/states
    wave_number: u32,
    score: u32,

    pub fn init() PlayingState{
        return PlayingState{
            .wave_number = 1,
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
            // update game entities
            player.update(input, delta_time);
            projectile_manager.update(delta_time);
            enemy_manager.update(player.position, delta_time);

            // handle collision
            projectile_manager.checkCollisionWithEnemies(&enemy_manager);
            enemy_manager.checkCollisionWithPlayer(&player);

            // check for game over
            if (player.isDead()) {
                return GameState.game_over;
            }

            // handle shooting
            of (self.shouldPlayerShoot(Input, player)) {
                self.handlePlayerShooting(Player, projectile_manager);
            }

            // handle pause
            if (rl.IsKeyPressed(rl.KEY_ESCAPE)) {
                return GameState.pause_menu;
            }

            // TODO: add wave progression logic
            // TODO: add score tracking

            return null; // stay in playing state
    }

    pub fn reset(self: *PlayingState) {
        self.wave_number = 1;
        self.score = 0;
    }

    fn shouldPlayerShoot(self: *PlayingState, input: Input, player: *Player) bool {
        _ = self; // not used
        return input.shoot and player.canShoot() and !player.animation.isAttacking();
    }

    fn handlePlayerShooting(self: *PlayingState, player: *Player, projectile_manager: *ProjectileManager,) void {
        _ = self; // not used
        
        // start attack animation
        player.animation.startAttack();
        player.shoot();

        // check if projectile should spawn during animation
        if (player.animation.shouldSpawnProjectile()) {
            const mouse_position = rl.GetMousePosition();
            const player_center = self.getPlayerCenter(player);

            // spawn the projectile
            projectile_manager.spawn(player_center, mouse_position, player.fire_speed) catch |err| {
                std.debug.print("Failed to spawn projectile\n", .{err});
            }
        }
        
    }

    fn getPlayerCenter(self: *PlayingState, player: *Player) rl.Vector2 {
        _ = self;
        const player_sprite_half_size = GameConstants.PLAYER_SPRITE_SIZE / 2;
        return rl.Vector2{
            .x = player.position.x + player_sprite_half_size,
            .y = player.position.y + player_sprite_half_size,
        };
    }
};