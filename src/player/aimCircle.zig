const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const AimCircle = struct {
    distance_from_player: f32,

    pub fn init() AimCircle {
        return AimCircle{
            .distance_from_player = 50.0, // radius of invisible circle around the player character
        };
    }

    // TODO: add some of these as constants
    pub fn draw(self: *AimCircle, player_position: rl.Vector2, camera: *const rl.Camera2D) void {
        const mouse_screen_position = rl.GetMousePosition();
        const mouse_world_position = rl.GetScreenToWorld2D(mouse_screen_position, camera.*);

        // calculate direction from player to mouse
        // dx, dy = the difference between mouse and player positions
        const dx = mouse_world_position.x - player_position.x;
        const dy = mouse_world_position.y - player_position.y;

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
