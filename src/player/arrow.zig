const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const Arrow = struct {
    distance_from_player: f32,

    pub fn init() Arrow {
        return Arrow{
            .distance_from_player = 50.0, // radius of invisible circle around the player character
        };
    }

    pub fn draw(self: *Arrow, player_position: rl.Vector2) void {
        const mouse_position = rl.GetMousePosition();

        // calculate direction from player to mouse
        // dx, dy = the difference between mouse and player positions
        const dx = mouse_position.x - player_position.x;
        const dy = mouse_position.y - player_position.y;

        // calculate the angle
        // using inverse tangent function
        const angle = std.math.atan2(dy, dx);

        // posotion the arrow on the invisible circle
        const arrow_x = player_position.x + std.math.cos(angle) * self.distance_from_player; // with cosinus how far right/left from player center
        const arrow_y = player_position.y + std.math.sin(angle) * self.distance_from_player; // with sinus how far right/left from player center

        // draw the triangle
        // TODO: make this a constant!
        const arrow_size = 10.0;
        const tip_x = arrow_x + std.math.cos(angle) * arrow_size;
        const tip_y = arrow_y + std.math.sin(angle) * arrow_size;

        const left_x = arrow_x + std.math.cos(angle - 2.5) * (arrow_size * 0.7);
        const left_y = arrow_y + std.math.sin(angle - 2.5) * (arrow_size * 0.7);

        const right_x = arrow_x + std.math.cos(angle + 2.5) * (arrow_size * 0.7);
        const right_y = arrow_y + std.math.sin(angle + 2.5) * (arrow_size * 0.7);

        // TODO: make this look better and disable auto formatter
        rl.DrawTriangle(rl.Vector2{ .x = tip_x, .y = tip_y }, rl.Vector2{ .x = left_x, .y = left_y }, rl.Vector2{ .x = right_x, .y = right_y }, rl.BLACK);
    }
};
