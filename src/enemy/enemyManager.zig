const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const enemy = @import("enemy.zig");
const Player = @import("../player/player.zig").Player;
const RoundManager = @import("../utils/roundManager.zig").RoundManager;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const EnemyManager = struct {
    enemies: std.ArrayList(enemy.Enemy),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) EnemyManager {
        return EnemyManager{
            .enemies = std.ArrayList(enemy.Enemy).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *EnemyManager) void {
        self.enemies.deinit();
    }

    pub fn spawn(self: *EnemyManager, position: rl.Vector2, enemy_type: enemy.EnemyType) !void {
        const new_enemy = enemy.Enemy.init(position, enemy_type);
        try self.enemies.append(new_enemy);
    }

    pub fn spawnAEdge(self: *EnemyManager, enemy_type: enemy.EnemyType) !void {
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));    // use timestamp to get a random number
        const random = prng.random();

        const edge = random.intRangeAtMost(u8, 0, 3);                 // 0 = top, 1 = right, 2 = bottom, 3 = left
        const position = switch (edge) {
            0 => rl.Vector2{ // top
                .x = random.float(f32) * @as(f32, @floatFromInt(gameConstants.WINDOW_WIDTH)),
                .y = -50,
            },
            1 => rl.Vector2{ // right
                .x = @floatFromInt(gameConstants.WINDOW_WIDTH + 50),
                .y = random.float(f32) * @as(f32, @floatFromInt(gameConstants.WINDOW_HEIGHT)),
            },
            2 => rl.Vector2{ // bottom
                .x = random.float(f32) * @as(f32, @floatFromInt(gameConstants.WINDOW_WIDTH)),
                .y = @floatFromInt(gameConstants.WINDOW_HEIGHT + 50),
            },
            3 => rl.Vector2{ // left
                .x = - 50,
                .y = random.float(f32) * @as(f32, @floatFromInt(gameConstants.WINDOW_HEIGHT)),
            },
            else => rl.Vector2{ .x = 0, .y = 0, },
        };

        try self.spawn(position, enemy_type);
    }

    pub fn checkCollisionWithPlayer(self: *EnemyManager, player: *Player) void {
        if (player.isDead()) return;

        for (self.enemies.items) |*e| {
            if (!e.active) continue;

            const enemy_bounds = e.getBounds();
            const player_bounds = player.getBounds();

            if (rl.CheckCollisionRecs(enemy_bounds, player_bounds)) {
                // pass the enemy position to use it for knock back
                const enemy_center = rl.Vector2{
                    .x = e.position.x + 16, // 16 for center of the 32x32 sprite
                    .y = e.position.y + 16,
                };
                
                //TODO: make some enemies deal less or more damage
                player.takeDamage(1, enemy_center);
                break; // only one enemy can hit per frame
            }
        }
    }

    pub fn updateWithRoundSystem(self: *EnemyManager, Player_position: rl.Vector2, delta_time: f32, round_manager: *RoundManager) void {
        // update existing enemies
        self.updateExistingEnemies(Player_position, delta_time);

        // spawn new enemies based on round system
        if (round_manager.shouldSpawnEnemy()) {
            const enemy_type = round_manager.getEnemyTypeToSpawn();
            self.spawnAEdge(enemy_type) catch |err| {
                std.debug.print("Failed to spawn enemy: {}\n", .{err});
            };
        }
    }

    pub fn updateExistingEnemies(self: *EnemyManager, player_position: rl.Vector2, delta_time: f32) void {
        // update all enemies
        for (self.enemies.items) |*e| {
            e.update(player_position, delta_time);
        }

        // remove dead enemies
        var i: usize = 0;
        while (i < self.enemies.items.len) {
            if (self.enemies.items[i].isDead()) {
                _ = self.enemies.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    // deprecated
    pub fn update(self: *EnemyManager, player_position: rl.Vector2, delta_time: f32) void {
       self.updateExistingEnemies(player_position, delta_time);
    }

    pub fn draw(self: *const EnemyManager, texture: rl.Texture2D) void {
        for (self.enemies.items) |*e| {
            e.draw(texture);
        }
    }

    pub fn clear(self: *EnemyManager) void {
        self.enemies.clearRetainingCapacity();
    }

    pub fn getEnemyCount(self: *const EnemyManager) usize {
        var count: usize = 0;
        for (self.enemies.items) |*e| {
            if (e.active) count += 1;
        }
        return count;
    }
};