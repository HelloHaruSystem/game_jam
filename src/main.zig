const std = @import("std");
const Game = @import("game.zig").Game;

// smal game for TEC game jam
// objective is to move around and shoot ducks with increasing difficulty
// Author: Halfdan Sand Christensen
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // init game
    var game = Game.init(allocator) catch |err| {
        std.debug.print("Failed to initialize game: {}\n", .{err});
        return;
    };
    defer game.deinit();

    // run game!
    std.debug.print("Starting game!\n", .{});
    game.run();
}
