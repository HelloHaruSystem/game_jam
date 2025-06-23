const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;

pub const PlayerAnimation = struct {
    current_frame: u32,
    frame_timer: f32,
    frame_duration: f32, // how long each frame will show
    

    // constants for the player animation
    const IDLE_FRAME = 4;
    const IDLE_FRAME_COUNT = 5;

    const WALK_START_FRAME = 3;
    const WALK_FRAME_COUNT = 7;


    pub fn init() PlayerAnimation {
        return PlayerAnimation{
            .current_frame = IDLE_FRAME,
            .frame_timer = 0.0,
            .frame_duration = 0.15, // 7fps animation
        };
    }

    pub fn update(self: *PlayerAnimation, player: *const Player, delta_time: f32) void {
        if (player.is_moving) {
            self.frame_timer += delta_time;
            if (self.frame_timer >= self.frame_duration) {
                self.current_frame = WALK_START_FRAME +
                    ((self.current_frame - WALK_START_FRAME + 1) % WALK_FRAME_COUNT);
                self.frame_timer = 0.0;
            }
        } else {
            self.current_frame = IDLE_FRAME;
            self.frame_timer = 0.0;
        }
    }

    pub fn draw(self: *PlayerAnimation, player: *const Player, texture: rl.Texture2D) void {
        const frames_per_row = if (player.is_moving) WALK_START_FRAME else IDLE_FRAME_COUNT;

        const source_rectangle = rl.Rectangle{
            .x = @floatFromInt((self.current_frame % frames_per_row) * 32), // hardcoded 32 because the sprite is 32x32
            .y = @floatFromInt((self.current_frame / frames_per_row) * 32),
            .width = if (player.facing_left) -32 else 32,
            .height = 32,
        };

        rl.DrawTextureRec(texture, source_rectangle, player.position, rl.WHITE);
    }
};