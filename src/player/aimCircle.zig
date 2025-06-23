const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const AimCricle = struct {
    distance_from_player: f32,

    pub fn init() AimCricle {
        return AimCricle{
            .distance_from_player = 50.0, // radius of invisible circle around the player character
        };
    }

    // TODO: add some of these as constants
    pub fn draw(self: *AimCricle, player_position: rl.Vector2) void {
        const mouse_position = rl.GetMousePosition();

        // calculate direction from player to mouse
        // dx, dy = the difference between mouse and player positions
        const dx = mouse_position.x - player_position.x;
        const dy = mouse_position.y - player_position.y;

        // get angle in radians
        // using inverse tangent function
        const angle = std.math.atan2(dy, dx);

        // calculate circle center position (center of player + 16 because of the 32x32 sprite)
        const player_center_x = player_position.x + 16; // half of the 32px sprite
        const player_center_y = player_position.y + 16; // half of the 32px sprite again

        // position the arrow on the invisible circle
        const dot_x = player_center_x + std.math.cos(angle) * self.distance_from_player; // with cosinus how far right/left from player center
        const dot_y = player_center_y + std.math.sin(angle) * self.distance_from_player; // with sinus how far up/down from player center

        // TODO: DEBUG REMOVE LATER!
        rl.DrawCircleLines(@intFromFloat(player_center_x), @intFromFloat(player_center_y), self.distance_from_player, rl.GREEN);
        // draw the aim circle
        rl.DrawCircle(@intFromFloat(dot_x), @intFromFloat(dot_y), 5, rl.YELLOW);
    }
};
