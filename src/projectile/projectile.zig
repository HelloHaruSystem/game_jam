const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const win_consts = @import("../utils/constants/screenAndWindow.zig");

pub const Projectile = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    active: bool,
    life_time: f32,
    time_to_live: f32,

    pub fn init(start_position: rl.Vector2, direction: rl.Vector2, speed: f32) Projectile {
        return Projectile{
            .position = start_position,
            .velocity = rl.Vector2{
                .x = direction.x * speed,
                .y = direction.y * speed,
            },
            .active = true,
            .life_time = 0.0,
            .time_to_live = 3.0, // projectile dies after 3 seconds
        };
    }

    pub fn update(self: *Projectile, delta_time: f32) void {
        if (!self.active) return ;

        // update position
        self.position.x += self.velocity * delta_time;
        self.position.y += self.velocity * delta_time;

        // update life time
        self.life_time += delta_time;
        if (self.life_time >= self.time_to_live) {
            self.active = false;
        }

        // bounds check for screen set non active when reaches outside
        if (self.position.x < -10 or self.position.x > win_consts + 20 or
            self.position.y < -10 or self.position.y > win_consts + 20) {
                self.active = false;
        }
    }   

    pub fn draw(self: *Projectile) void {
        if (!self.active) return;

        // TODO: add animation for the projectile for now it will be a circle
        rl.DrawCircle(@intFromFloat(self.position.x), @intFromFloat(self.position.y), 3, rl.PURPLE);
    }
};

pub const ProjectileManager = struct {
    Projectiles: std.ArrayList(Projectile),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ProjectileManager {
        return ProjectileManager{
            .Projectiles = std.ArrayList(Projectile).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ProjectileManager) void {
        self.Projectiles.deinit();
    }

    pub fn spawn(self: *ProjectileManager, start_position: rl.Vector2, target_position: rl.Vector2, speed: f32) !void {
        // calculate raw difference
        // delta x and delta y
        const dx = target_position.x - start_position.x;
        const dy = target_position.y - start_position.y;
        // using Pythagorean theorem
        // taking the square root of that sum give the distance
        const distance = std.math.sqrt(dx * dx + dy * dy);

        // normalize direction
        const direction = rl.Vector2{
            .x = if (distance > 0) dx / distance else 0,
            .y = if (distance > 0) dy / distance else 0,
        };

        const projectile = Projectile.init(start_position, direction, speed);
        try self.Projectiles.append(projectile);
    }

    pub fn update(self: *ProjectileManager, delta_time: f32) void {
        // update all the projectiles
        for (self.Projectiles.items) |*projectile| {
            projectile.update(delta_time);
        }

        // remove inactive projectiles
        var i: usize = 0;
        while (i < self.Projectiles.items.len) {
            if (!self.Projectiles.items[i].active) {
                _ = self.Projectiles.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    pub fn draw(self: *const ProjectileManager) void {
        for (self.Projectiles.items) |*projectile| {
            projectile.draw();
        }
    }

    pub fn clear(self: *ProjectileManager) void {
        self.Projectiles.clearRetainingCapacity();
    }
};