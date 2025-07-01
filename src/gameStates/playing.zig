const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;
const ProjectileManager = @import("../projectile/projectile.zig").ProjectileManager;
const EnemyManager = @import("../enemy/enemyManager.zig").EnemyManager;
const RoundManager = @import("../utils/roundManager.zig").RoundManager;
const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const TileMap = @import("../tilemap//tilemap.zig").Tilemap;
const GameConstants = @import("../utils/constants/gameConstants.zig");

pub const PlayingState = struct {
    round_manager: RoundManager,

    pub fn init() PlayingState {
        return PlayingState{
            .round_manager = RoundManager.init(),
        };
    }

    pub fn update(
        self: *PlayingState,
        player: *Player,
        projectile_manager: *ProjectileManager,
        enemy_manager: *EnemyManager,
        input: Input,
        delta_time: f32,
        tilemap: ?*const TileMap,
    ) ?GameState {

        // update round system
        self.round_manager.update(delta_time);

        // update game entities
        player.update(input, delta_time, tilemap);
        projectile_manager.update(delta_time);

        // only update enemies and spawn new ones during active rounds
        if (self.round_manager.isRoundActive()) {
            enemy_manager.updateWithRoundSystem(player.position, delta_time, &self.round_manager, tilemap);
        } else {
            // during break just update existing enemies (letting them finishing moving/attacking)
            enemy_manager.updateExistingEnemies(player.position, delta_time, tilemap);
        }

        // handle collision
        projectile_manager.checkCollisionWithEnemies(enemy_manager, &self.round_manager);
        enemy_manager.checkCollisionWithPlayer(player);

        // check for game over
        if (player.isDead()) {
            return GameState.game_over;
        }

        // handle shooting - start attack animation
        if (self.shouldPlayerShoot(input, player)) {
            player.animation.startAttack();
            player.shoot();
        }

        // check if projectile should spawn during animation (separate from input)
        if (player.animation.shouldSpawnProjectile()) {
            const mouse_position = rl.GetMousePosition();
            const player_center = self.getPlayerCenter(player);

            // spawn the projectile
            projectile_manager.spawn(player_center, mouse_position, player.fire_speed) catch |err| {
                std.debug.print("Failed to spawn projectile: {}\n", .{err});
            };
        }

        // handle pause
        if (rl.IsKeyPressed(rl.KEY_ESCAPE)) {
            return GameState.pause_menu;
        }

        // TODO: add wave progression logic
        // TODO: add score tracking

        return null; // stay in playing state
    }

    pub fn reset(self: *PlayingState) void {
        self.round_manager.reset();
    }

    fn shouldPlayerShoot(self: *PlayingState, input: Input, player: *Player) bool {
        _ = self; // not used
        return input.shoot and player.canShoot() and !player.animation.isAttacking();
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
