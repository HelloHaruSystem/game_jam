const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("player/input.zig").Input;
const Player = @import("player/player.zig").Player;
const AimCircle = @import("player/aimCircle.zig").AimCricle;
const ProjectileManager = @import("projectile/projectile.zig").ProjectileManager;
const GameState = @import("utils/gameState.zig").GameState;
const textureLoader = @import("utils/textureLoader.zig");
const win_const = @import("utils/constants/screenAndWindow.zig");

pub const Game = struct {
    player: Player,
    player_texture: rl.Texture2D,
    aim_circle: AimCircle,
    projectile_manager: ProjectileManager,
    current_state: GameState,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Game {
        rl.InitWindow(win_const.WINDOW_WIDTH, win_const.WINDOW_HEIGHT, "Haru Jam");
        rl.SetTargetFPS(60);

        // init player character
        const player = Player.init();
        // init player texture
        const player_texture = try textureLoader.loadSprite(allocator, "player_spritesheet.png");
        // init aim arrow
        const aim_circle = AimCircle.init();

        return Game{
            .player = player,
            .player_texture = player_texture,
            .aim_circle = aim_circle,
            .projectile_manager = ProjectileManager.init(allocator),
            .current_state = GameState.playing, // TODO: when menu is added start at the start menu
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        textureLoader.unloadTexture(self.player_texture);
        self.projectile_manager.deinit();
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
                rl.HideCursor();
                mouseWindowLock();
                const delta_time = rl.GetFrameTime();
                self.player.update(input, delta_time);
                self.projectile_manager.update(delta_time);

                // handle shooting
                //  TODO: move this to it's own function
                if (input.shoot and self.player.canShoot()) {
                    self.player.shoot();
                    const mouse_position = rl.GetMousePosition();
                    const player_center = rl.Vector2{
                        .x = self.player.position.x + 16,
                        .y = self.player.position.y + 16, // 16 for center of the player
                    };

                    // spawn the projectile
                    // TODO: get the speed from player
                    // TODO: add fire rate limit
                    // TODO: error handle this properly
                    self.projectile_manager.spawn(player_center, mouse_position, 400.0) catch {}; 
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
                self.projectile_manager.draw();
            },
            .round_break => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .shopping => {
                rl.ClearBackground(rl.SKYBLUE);
            },
            .game_over => {
                rl.ClearBackground(rl.SKYBLUE);
            },
        }
    }

    // TODO: fix this or remove
    // this doesn't work
    fn mouseWindowLock() void {
        // keep mouse locked to window bounds
        const mouse_position = rl.GetMousePosition();
        if (mouse_position.x < 0 or mouse_position.x > win_const.WINDOW_WIDTH or
            mouse_position.y < 0 or mouse_position.y > win_const.WINDOW_HEIGHT)
        {
            const clamped_x = std.math.clamp(mouse_position.x, 0, @as(f32, @floatFromInt(win_const.WINDOW_WIDTH)));
            const clamped_y = std.math.clamp(mouse_position.y, 0, @as(f32, @floatFromInt(win_const.WINDOW_HEIGHT)));
            rl.SetMousePosition(@as(c_int, @intFromFloat(clamped_x)), @as(c_int, @intFromFloat(clamped_y)));
        }
    }
};
