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
const gameConst = @import("utils/constants/gameConstants.zig");

// game state handlers
const PlayingState = @import("gameStates/playing.zig").PlayingState;
const GameOverState = @import("gameStates/gameOver.zig").GameOverState;

pub const Game = struct {
    player: Player,
    textures: GameTextures,
    aim_circle: AimCircle,
    projectile_manager: ProjectileManager,
    enemy_manager:EnemyManager,
    current_state: GameState,
    playing_state: PlayingState,
    game_over_state: GameOverState,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Game {
        rl.InitWindow(gameConst.WINDOW_WIDTH, gameConst.WINDOW_HEIGHT, "Haru Jam");
        rl.SetTargetFPS(60);

        const textures = try GameTextures.init(allocator);
        const player = Player.init();
        const aim_circle = AimCircle.init();
        const projectile_manager = ProjectileManager.init(allocator);
        const enemy_manager = EnemyManager.init(allocator);

        return Game{
            .player = player,
            .textures = textures,
            .aim_circle = aim_circle,
            .projectile_manager = projectile_manager,
            .enemy_manager = enemy_manager,
            .current_state = GameState.playing, // TODO: when menu is added start at the start menu
            .playing_state = PlayingState.init(),
            .game_over_state = GameOverState.init(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        self.textures.deinit();
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
        const delta_time = rl.GetFrameTime();

        // TODO: do functions for each case
        switch (self.current_state) {
            .start_menu => {
                rl.ShowCursor();
            },
            .pause_menu => {
                rl.ShowCursor();
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
                self.drawGameplay();
            },
            .round_break => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .shopping => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .game_over => {
                self.game_over_state.draw();
            },
        }
    }

    fn drawGameplay(self: *Game) void {
        rl.ClearBackground(rl.SKYBLUE);
        self.player.draw(self.textures.player);
        self.aim_circle.draw(self.player.position);
        self.projectile_manager.draw(self.textures.projectile);
        self.enemy_manager.draw(self.textures.enemy);

        // draw system UI
        self.playing_state.drawUI();

        // TODO: move this to a dedicated ui file
        const fps = rl.GetFPS();
        const fps_text = std.fmt.allocPrint(self.allocator, "FPS: {d}", .{ fps, }) catch "FPS: ?";
        defer self.allocator.free(fps_text);
        const fps_text_c = self.allocator.dupeZ(u8, fps_text) catch return;
        defer self.allocator.free(fps_text_c);

        const text_width = rl.MeasureText(fps_text_c.ptr, 20);
        rl.DrawText(fps_text_c, gameConst.WINDOW_WIDTH - text_width - 20, 20, 20, rl.WHITE);

        // draw health hearts
        self.drawHealthHearts();
    }

    // TODO: MOVE THIS TO A DEDICATED UI FILE
    fn drawHealthHearts(self: *Game) void {
        // TODO: find a heart sprite
        // for now it will be diamonds
        const heart_size = 30;
        const heart_spacing = 40;
        const total_width = (gameConst.DEFAULT_PLAYER_MAX_HEALTH * heart_spacing) - (heart_spacing - heart_size);
        const start_x = (gameConst.WINDOW_WIDTH / 2) - (total_width / 2);
        const y_pos = 20;

        var i: u32 = 0;
        while (i < gameConst.DEFAULT_PLAYER_MAX_HEALTH) : (i += 1) {
            const x_pos = start_x + (i * heart_spacing);

            // determine heart color lose hearts from right to left
            const heart_lost = gameConst.DEFAULT_PLAYER_MAX_HEALTH - self.player.current_health;
            const is_lost_heart = i >= (gameConst.DEFAULT_PLAYER_MAX_HEALTH - heart_lost);
            const heart_color = if (is_lost_heart) rl.BLACK else rl.RED;

            // draw diamond for now
            self.drawHeart(@intCast(x_pos), @intCast(y_pos), @intCast(heart_size), heart_color);
        }
    }

    // TODO: MOVE THIS TO A DEDICATED UI FILE
    fn drawHeart(self: *Game, x: i32, y: i32, size: i32, color: rl.Color) void {
        _ = self; // unused

        // simple heart shape using circles and triangles????
        const half_size = @divTrunc(size, 2);
        const quarter_size = @divTrunc(size, 4);

        // top two circles
        rl.DrawCircle(x + quarter_size, y + quarter_size, @floatFromInt(quarter_size), color);
        rl.DrawCircle(x + (3 * quarter_size), y + quarter_size, @floatFromInt(quarter_size), color);

        // bottom triangle
        rl.DrawTriangle(
            rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y + half_size), },
            rl.Vector2{ .x = @floatFromInt(x + size), .y = @floatFromInt(y + half_size), },
            rl.Vector2{ .x = @floatFromInt(x + half_size), .y = @floatFromInt(y + size), },
            color
        );

        // fill the middle rectangle
        rl.DrawRectangle(x + quarter_size, y + quarter_size, half_size, quarter_size, color);
    }

    fn transitionToState(self: *Game, new_state: GameState) void {
        switch (new_state) {
            .playing => {
                if (self.current_state == .game_over) {
                    self.resetGame();
                }
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