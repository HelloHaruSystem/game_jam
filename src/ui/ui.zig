const std = @import("std");
const rl = @import({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;
const RoundManager = @import("../utils/roundManager.zig").RoundManager;
const ProjectileManager = @import("../projectile/projectile.zig").ProjectileManager;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const UI = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) UI {
        return UI{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *UI) void {
        _ = self; // UI doesn't own any resources
    }

    // main gameplay UI drawing function
    pub fn drawGameplayUI(self: *UI, player: *const Player, round_manager: *const RoundManager) void {
        self.drawFPS();
        self.drawHealthHearts(player);
        self.drawRoundInfo(round_manager);
        self.drawScore(round_manager);
        self.drawTimer(round_manager);
        self.drawKillCount(round_manager);
    }

    fn drawFPS(self: *UI) void {
        const fps = rl.GetFPS();
        const fps_text = std.fmt.allocPrint(self.allocator, "FPS: {d}", .{ fps, }) catch "FPS: ?";
        defer self.allocator.free(fps_text);
        const fps_text_c = self.allocator.dupeZ(u8, fps_text) catch return;
        defer self.allocator.free(fps_text_c);

        const text_width = rl.MeasureText(fps_text_c.ptr, 20);

        // TODO:  add some if these ui values to constants module
        rl.DrawText(fps_text_c, gameConstants.WINDOW_WIDTH - text_width - 20, 20, 20, rl.WHITE);
    }
};