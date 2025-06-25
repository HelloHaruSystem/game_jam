const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const ProjectileAnimation = @import("../animation/projectileAnimation.zig").ProjectileAnimation;
const EnemyManager = @import("../enemy/enemyManager.zig").EnemyManager;
const win_consts = @import("../utils/constants/screenAndWindow.zig");

pub const Projectile = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    active: bool,
    life_time: f32,
    time_to_live: f32,
    animation: ProjectileAnimation,
    damage: u32,

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
            .animation = ProjectileAnimation.init(),
            .damage = 1, // default dmg value //TODO: change this to come from player as the player powers up
        };
    }

    pub fn getBounds(self: *const Projectile) rl.Rectangle {
        const projectile_size = 16.0 * 2.0;    // 16x16 sprite * 2 scale from animation //TODO: add scale and sprite size as constants in it's own file!
        return rl.Rectangle{
            .x = self.position.x - (projectile_size / 2),
            .y = self.position.y - (projectile_size / 2),
            .width = projectile_size,
            .height = projectile_size,
        };
    }

    // TODO: add power up that makes it pierce enemies
    pub fn onHit(self: *Projectile) void {
        self.active = false;
    }

    pub fn update(self: *Projectile, delta_time: f32) void {
        if (!self.active) return ;

        // update position
        self.position.x += self.velocity.x * delta_time;
        self.position.y += self.velocity.y * delta_time;

        // update life time
        self.life_time += delta_time;
        if (self.life_time >= self.time_to_live) {
            self.active = false;
        }

        // update animation
        self.animation.update(delta_time);

        // bounds check for screen set non active when reaches outside
        if (self.position.x < - 20 or self.position.x > @as(f32, @floatFromInt(win_consts.WINDOW_WIDTH + 20)) or
            self.position.y < - 20 or self.position.y > @as(f32, @floatFromInt(win_consts.WINDOW_HEIGHT + 20))) {
                self.active = false;
        }
    }   

    pub fn draw(self: *Projectile, texture: rl.Texture2D) void {
        if (!self.active) return; 
        self.animation.draw(self.position, self.velocity, texture);
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

    pub fn checkCollisionWithEnemies(self: *ProjectileManager, enemy_manager: *EnemyManager) void {
        for (self.Projectiles.items) |*projectile| {
            if (!projectile.active) continue;

            // check against all enemies
            for (enemy_manager.enemies.items) |*enemy| {
                if (!enemy.active) continue;

                // get the collision rectangles
                const projectile_bounds = projectile.getBounds();
                const enemy_bounds = enemy.getBounds();

                // check to see if the rectangles overlap
                if (rl.CheckCollisionRecs(projectile_bounds, enemy_bounds)) {
                    // collision!
                    enemy.takeDamage(projectile.damage);
                    projectile.onHit();

                    //TODO: play hit sound and do explosion animation

                    // since the projectile is destroyed we just break
                    //TODO: if the project pierce power-up is implemented don't break just yet
                    break;
                }
            }
        }
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

    pub fn draw(self: *const ProjectileManager, texture: rl.Texture2D) void {
        for (self.Projectiles.items) |*projectile| {
            projectile.draw(texture);
        }
    }

    pub fn clear(self: *ProjectileManager) void {
        self.Projectiles.clearRetainingCapacity();
    }
};