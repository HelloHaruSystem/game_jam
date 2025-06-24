const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub const ProjectileAnimation = struct {
    current_frame: u32,
    frame_timer: f32,
    frame_duration: f32,

    // animation constants
    const PROJECTILE_ROW = 16;
    const FRAME_COUNT = 5;
    const SPRITE_SIZE = 16; // 16x16 sprite

    pub fn init() ProjectileAnimation {
        return ProjectileAnimation{
            .current_frame = 0,
            .frame_timer = 0.0,
            .frame_duration = 0.08, // fast animation for the projectile change this to make it feel right
        };
    }

    pub fn update(self: *ProjectileAnimation, delta_time: f32) void {
        self.frame_timer += delta_time;
        if (self.frame_timer >= self.frame_duration) {
            self.current_frame = (self.current_frame + 1) % FRAME_COUNT;
            self.frame_timer = 0.0;
        }
    }

    pub fn draw(self: *const ProjectileAnimation, position: rl.Vector2, velocity: rl.Vector2, texture: rl.Texture2D) void {
        const scale = 2.0; // scale factor edit this to change the size of the projectile
        const scaled_size = SPRITE_SIZE * scale;

        const source_rectangle = rl.Rectangle{
            .x = @floatFromInt(self.current_frame * SPRITE_SIZE),
            .y = @floatFromInt(PROJECTILE_ROW * SPRITE_SIZE),
            .width = SPRITE_SIZE,
            .height = SPRITE_SIZE,
        };

        const destination_rectangle = rl.Rectangle{
            .x = position.x,
            .y = position.y,
            .width = scaled_size,
            .height = scaled_size,
        };

        // calculate the rotation angle from velocity vector
        const angle_radians = std.math.atan2(velocity.y, velocity.x);
        const angle_degrees = angle_radians * (180.0 / std.math.pi);

        // origin point for rotation
        const origin = rl.Vector2{
            .x = scaled_size / 2,
            .y = scaled_size / 2,
        };

        rl.DrawTexturePro(texture, source_rectangle, destination_rectangle, origin, angle_degrees,  rl.WHITE);
    }

    pub fn reset(self: *ProjectileAnimation) void {
        self.current_frame = 0;
        self.frame_timer = 0.0;
    }
};
