const rl = @cImport({
    @cInclude("raylib.h");
});

pub const Input = struct {
    move_up: bool,
    move_down: bool,
    move_left: bool,
    move_right: bool,
    shoot: bool,

    pub fn update() Input {
        return Input{
            .move_up = rl.IsKeyDown(rl.KEY_W) or rl.IsKeyDown(rl.KEY_UP),
            .move_down = rl.IsKeyDown(rl.KEY_S) or rl.IsKeyDown(rl.KEY_DOWN),
            .move_left = rl.IsKeyDown(rl.KEY_A) or rl.IsKeyDown(rl.KEY_LEFT),
            .move_right = rl.IsKeyDown(rl.KEY_D) or rl.IsKeyDown(rl.KEY_RIGHT),
            .shoot = rl.IsKeyDown(rl.KEY_SPACE),
        };
    }

    pub fn hasMovement(self: Input) bool {
        return self.move_up or self.move_down or self.move_left or self.move_right;
    }

    pub fn hasAttacking(self: Input, can_shoot: bool) bool {
        return self.shoot and can_shoot;
    }

    pub const MovementVector = struct {
        x: f32,
        y: f32,
    };

    pub fn getMovementVector(self: Input) MovementVector {
        var movement = MovementVector{ .x = 0.0, .y = 0.0 };

        if (self.move_up) movement.y -= 1.0;
        if (self.move_down) movement.y += 1.0;
        if (self.move_left) movement.x -= 1.0;
        if (self.move_right) movement.x += 1.0;

        return movement;
    }
};