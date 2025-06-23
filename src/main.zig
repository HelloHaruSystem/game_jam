const std = @import("std");
const Game = @import("game.zig").Game;
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