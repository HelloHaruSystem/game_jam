const std = @import("std");
const Game = @import("game.zig").Game;
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // init game
    var game = Game.init() catch |err| {
        std.debug.print("Failed to initialize game: {}\n", .{err});
        return;
    };
    defer game.deinit();

    // run game!
    try stdout.print("Starting game!\n", .{});
    game.run();
}