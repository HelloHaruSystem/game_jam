const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("player/input.zig").Input;
const Player = @import("player/player.zig").Player;
const Arrow = @import("player/arrow.zig").Arrow;
const textureLoader = @import("utils/textureLoader.zig");
const win_const = @import("utils/constants/screenAndWindow.zig");

pub const Game = struct {
    player: Player,
    player_texture: rl.Texture2D,
    arrow: Arrow,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Game {
        rl.InitWindow(win_const.WINDOW_WIDTH, win_const.WINDOW_HEIGHT, "Haru Jam");
        rl.SetTargetFPS(60);

        // init player character
        const player = Player.init();
        // init player texture
        const player_texture = try textureLoader.loadSprite(allocator, "player_spritesheet.png");
        // init aim arrow
        const arrow = Arrow.init();

        return Game{
            .player = player,
            .player_texture = player_texture,
            .arrow = arrow,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        textureLoader.unloadTexture(self.player_texture);
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
        self.player.update(input, delta_time);
    }

    pub fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.SKYBLUE);

        // draw the player character and arrow
        self.player.draw(self.player_texture);
        self.arrow.draw(self.player.position);
    }
};
