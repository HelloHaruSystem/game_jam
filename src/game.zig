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
const UI = @import("ui/ui.zig").UI;
const gameConst = @import("utils/constants/gameConstants.zig");

// game state handlers
const StartMenuState = @import("gameStates/startMenu.zig").StartMenuState;
const PlayingState = @import("gameStates/playing.zig").PlayingState;
const PauseMenuState = @import("gameStates/pauseMenu.zig").PauseMenuState;
const GameOverState = @import("gameStates/gameOver.zig").GameOverState;

pub const Game = struct {
    player: Player,
    textures: GameTextures,
    aim_circle: AimCircle,
    projectile_manager: ProjectileManager,
    enemy_manager:EnemyManager,
    current_state: GameState,
    start_menu_state: StartMenuState,
    playing_state: PlayingState,
    pause_menu_state: PauseMenuState,
    game_over_state: GameOverState,
    ui: UI,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Game {
        rl.InitWindow(gameConst.WINDOW_WIDTH, gameConst.WINDOW_HEIGHT, "Haru Jam");
        rl.SetTargetFPS(60);
        rl.SetExitKey(rl.KEY_NULL);

        const textures = try GameTextures.init(allocator);
        const player = Player.init();
        const aim_circle = AimCircle.init();
        const projectile_manager = ProjectileManager.init(allocator);
        const enemy_manager = EnemyManager.init(allocator);
        const ui = UI.init(allocator);

        return Game{
            .player = player,
            .textures = textures,
            .aim_circle = aim_circle,
            .projectile_manager = projectile_manager,
            .enemy_manager = enemy_manager,
            .current_state = GameState.start_menu, // TODO: when menu is added start at the start menu
            .start_menu_state = StartMenuState.init(),
            .playing_state = PlayingState.init(),
            .pause_menu_state = PauseMenuState.init(),
            .game_over_state = GameOverState.init(),
            .ui = ui,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        self.textures.deinit();
        self.projectile_manager.deinit();
        self.enemy_manager.deinit();
        self.ui.deinit();
        rl.CloseWindow();
    }

    pub fn run(self: *Game) void {
        while (!rl.WindowShouldClose() and self.current_state != .quit) {
            self.update();
            self.draw();
        }
    }

    pub fn update(self: *Game) void {
        const input = Input.update();
        const delta_time = rl.GetFrameTime();

        // TODO: do functions for each case
        switch (self.current_state) {
            .start_menu => {
                const next_state = self.start_menu_state.update(input);
                if (next_state) |state| {
                    self.transitionToState(state);
                }
            },
            .pause_menu => {
                const next_state = self.pause_menu_state.update(input);
                if (next_state) |state| {
                    self.transitionToState(state);
                }
            },
            .playing => {
                const next_state = self.playing_state.update(
                    &self.player,
                    &self.projectile_manager,
                    &self.enemy_manager,
                    input,
                    delta_time,
                );
                if (next_state) |state| {
                    self.transitionToState(state);
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
                const next_state = self.game_over_state.update(input);
                if (next_state) |state| {
                    self.transitionToState(state);
                }
            },
            .quit => {
                // Quit state - do nothing, just let the main loop handle it
                // The run() function will exit when it sees this state
            },
        }
    }

    // TODO: make a function for each case
    pub fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        switch (self.current_state) {
            .start_menu => {
                self.ui.drawStartMenu(self.start_menu_state.selected_option);
            },
            .pause_menu => {
                // first draw the game background (paused state)
                self.drawGameplay();
                // then the pause overlay
                self.ui.drawPauseMenu(self.pause_menu_state.selected_option);
            },
            .playing => {
                self.drawGameplay();
            },
            .round_break => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .shopping => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .game_over => {
                self.ui.drawGameOverUI(
                    self.game_over_state.selected_option,
                    self.game_over_state.final_score,
                    self.game_over_state.final_round,
                );
            },
            .quit => {
                // Don't draw anything when quitting
            }
        }
    }

    fn drawGameplay(self: *Game) void {
        rl.ClearBackground(rl.SKYBLUE);
        rl.ShowCursor();

        // draw game objects
        self.player.draw(self.textures.player);
        self.aim_circle.draw(self.player.position);
        self.projectile_manager.draw(self.textures.projectile);
        self.enemy_manager.draw(self.textures.enemy);

        // draw the ui elements
        self.ui.drawGameplayUI(&self.player, &self.playing_state.round_manager);

        // TODO: optional make a debug ui overlay
    }

    fn transitionToState(self: *Game, new_state: GameState) void {
        switch (new_state) {
            .playing => {
                if (self.current_state == .game_over) {
                    self.resetGame();
                } else if (self.current_state == .start_menu) {
                    self.resetGame();
                } else if (self.current_state == .pause_menu) {
                     // Just resume - don't reset the game
                }
            },
            .game_over => {
                self.game_over_state.setFinalStats(&self.playing_state.round_manager);
            },
            else => {},
        }
        self.current_state = new_state;
    }

    fn resetGame(self: *Game) void {
        self.player = Player.init();
        self.enemy_manager.clear();
        self.projectile_manager.clear();
        self.playing_state.reset();
    }
};

pub const GameTextures = struct {
    player: rl.Texture2D,
    projectile: rl.Texture2D,
    enemy: rl.Texture2D,

    pub fn init(allocator: std.mem.Allocator) !GameTextures {
        return GameTextures{
            .player = try textureLoader.loadSprite(allocator, gameConst.PLAYER_SPRITE_SHEET),
            .projectile = try textureLoader.loadSprite(allocator, gameConst.PROJECTILE_SPRITE_SHEET),
            .enemy = try textureLoader.loadSprite(allocator, gameConst.ENEMY_SPRITE_SHEET),
        };
    }

    pub fn deinit(self: *GameTextures) void {
        textureLoader.unloadTexture(self.player);
        textureLoader.unloadTexture(self.projectile);
        textureLoader.unloadTexture(self.enemy);
    }
};