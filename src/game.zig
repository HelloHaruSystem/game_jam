const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("player/input.zig").Input;
const Player = @import("player/player.zig").Player;
const AimCircle = @import("player/aimCircle.zig").AimCircle;
const ProjectileManager = @import("projectile/projectile.zig").ProjectileManager;
const EnemyManager = @import("enemy/enemyManager.zig").EnemyManager;
const GameState = @import("utils/gameState.zig").GameState;
const textureLoader = @import("utils/textureLoader.zig");
const win_const = @import("utils/constants/screenAndWindow.zig");

// game state handlers
const PlayingState = @import("gameStates/playing.zig").PlayingState;



pub const Game = struct {
    player: Player,
    player_texture: rl.Texture2D,
    projectile_texture: rl.Texture2D,
    enemy_texture: rl.Texture2D,
    aim_circle: AimCircle,
    projectile_manager: ProjectileManager,
    enemy_manager:EnemyManager,
    current_state: GameState,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Game {
        rl.InitWindow(win_const.WINDOW_WIDTH, win_const.WINDOW_HEIGHT, "Haru Jam");
        rl.SetTargetFPS(60);

        // init player character
        const player = Player.init();
        // init player texture
        const player_texture = try textureLoader.loadSprite(allocator, "player_spritesheet.png");
        // init projectile texture
        const projectile_texture = try textureLoader.loadSprite(allocator, "projectile_spritesheet.png");
        // init enemy texture
        const enemy_texture = try textureLoader.loadSprite(allocator, "enemy_spritesheet.png");
        // init aim arrow
        const aim_circle = AimCircle.init();

        return Game{
            .player = player,
            .player_texture = player_texture,
            .projectile_texture = projectile_texture,
            .enemy_texture = enemy_texture,
            .aim_circle = aim_circle,
            .projectile_manager = ProjectileManager.init(allocator),
            .enemy_manager = EnemyManager.init(allocator),
            .current_state = GameState.playing, // TODO: when menu is added start at the start menu
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        textureLoader.unloadTexture(self.player_texture);
        textureLoader.unloadTexture(self.projectile_texture);
        textureLoader.unloadTexture(self.enemy_texture);
        self.projectile_manager.deinit();
        self.enemy_manager.deinit();
        rl.CloseWindow();
    }

    pub fn run(self: *Game) void {
        while (!rl.WindowShouldClose()) {
            self.update();
            self.draw();
        }
    }

    pub fn update(self: *Game) void {
        const input = Input.update();

        // TODO: do functions for each case
        switch (self.current_state) {
            .start_menu => {
                rl.ShowCursor();
            },
            .pause_menu => {
                rl.ShowCursor();
            },
            .playing => {
                const delta_time = rl.GetFrameTime();
                self.player.update(input, delta_time);
                self.projectile_manager.update(delta_time);
                self.enemy_manager.update(self.player.position, delta_time);

                // collision
                self.projectile_manager.checkCollisionWithEnemies(&self.enemy_manager);
                self.enemy_manager.checkCollisionWithPlayer(&self.player);

                // check for game over
                if (self.player.isDead()) {
                    self.current_state = .game_over;
                }

                // handle shooting
                //  TODO: move this to it's own function
                if (input.shoot and self.player.canShoot() and !self.player.animation.isAttacking()) {
                    // start attack animation
                    self.player.animation.startAttack();
                    self.player.shoot();
                }

                // check if projectile should spawn during animation
                if (self.player.animation.shouldSpawnProjectile()) {
                    const mouse_position = rl.GetMousePosition();
                    const player_center = rl.Vector2{
                        .x = self.player.position.x + 16,
                        .y = self.player.position.y + 16,
                    };

                    // spawn the projectile
                    // TODO: get the speed from player
                    self.projectile_manager.spawn(player_center, mouse_position, self.player.fire_speed) catch |err| {
                        std.debug.print("Failed to spawn projectile: {}\n", .{err});
                    }; 
                }

            },
            .round_break => {
                rl.ShowCursor();
            },
            .shopping => {
                rl.ShowCursor();
            },
            .game_over => {
                rl.ShowCursor();
                // TODO: move this logic ouT!
                if (rl.IsKeyPressed(rl.KEY_R)) {
                    // reset the game state
                    // TODO: go to .start_menu
                    self.player = Player.init();
                    self.enemy_manager.clear();
                    self.projectile_manager.clear();
                    self.current_state = .playing;
                }
            },
        }
    }

    // TODO: make a function for each case
    pub fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        switch (self.current_state) {
            .start_menu => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .pause_menu => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .playing => {
                rl.ClearBackground(rl.SKYBLUE);
                // draw the player character and circle
                self.player.draw(self.player_texture);
                self.aim_circle.draw(self.player.position);
                self.projectile_manager.draw(self.projectile_texture);
                self.enemy_manager.draw(self.enemy_texture);
            },
            .round_break => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .shopping => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .game_over => {
                rl.ClearBackground(rl.RED);

                // draw temporary game over text
                // TODO: make game over UI
                const text = "GAME OVER";
                const font_size = 60;
                const text_width = rl.MeasureText(text, font_size);
                const screen_center_x = win_const.WINDOW_WIDTH / 2;
                const screen_center_y = win_const.WINDOW_HEIGHT / 2;

                rl.DrawText(
                    text,
                    screen_center_x - @divTrunc(text_width, 2),
                    screen_center_y - font_size / 2,
                    font_size,
                    rl.WHITE,
                );

                // Instructions to restart
                const restart_text = "Press R to restart";
                const restart_font_size = 30;
                const restart_width = rl.MeasureText(restart_text, restart_font_size);

                rl.DrawText(
                    restart_text,
                    screen_center_x - @divTrunc(restart_width, 2),
                    screen_center_y + 50,
                    restart_font_size,
                    rl.WHITE,
                );
            },
        }
    }
};

pub const GameTextures = struct {
    player: rl.Texture2D,
    projectile: rl.Texture2D,
    enemy: rl.Texture2D,

    pub fn init(allocator: std.mem.Allocator) !GameTextures {
        return GameTextures{
            .player = try textureLoader.loadSprite(allocator, "player_spritesheet.png"),
            .projectile = try textureLoader.loadSprite(allocator, "projectile_spritesheet.png"),
            .enemy = try textureLoader.loadSprite(allocator, "enemy_spritesheet.png"),
        };
    }

    pub fn deinit(self: *GameTextures) void {
        textureLoader.unloadTexture(self.player);
        textureLoader.unloadTexture(self.projectile);
        textureLoader.unloadTexture(self.enemy);
    }
};