const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const win_const =  @import("utils/constants/screenAndWindow.zig");

pub const Game = struct {

    pub fn init() !Game {
        rl.InitWindow(win_const.WINDOW_WIDTH, win_const.WINDOW_HEIGHT, "Haru Jam");
        rl.SetTargetFPS(60);

        return Game{

        };
    }

    pub fn deinit(_: *Game) void {
        rl.CloseWindow();
    }

    pub fn run (self: *Game) void {
        while(!rl.WindowShouldClose()) {
            self.update();
            self.draw();
        }
    }

    pub fn update(_: *Game) void {

    }

    pub fn draw(_: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.SKYBLUE);
    }
};