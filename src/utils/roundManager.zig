const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const EnemyType = @import("../enemy/enemy.zig").EnemyType;
const gameConstants = @import("constants/gameConstants.zig");

pub const RoundState = enum {
    active,
    break_time,
    completed,
};

pub const RoundManager = struct {
    current_round: u32,
    round_state: RoundState,
    round_timer: f32,
    round_duration: f32,
    break_timer: f32,
    break_duration: f32,

    // enemy spawning
    base_spawn_rate: f32,
    current_spawn_rate: f32,
    spawn_timer: f32,

    // round progression
    score: u32,
    enemies_killed_this_round: u32,

    pub fn init() RoundManager {
        return RoundManager{
            .current_round = 1,
            .round_state = .active,
            .round_timer = 0.0,
            .round_duration = gameConstants.DEFAULT_ROUND_DURATION,
            .break_timer = 0.0,
            .break_duration = gameConstants.DEFAULT_BREAK_DURATION,
            .base_spawn_rate = gameConstants.BASE_SPAWN_RATE,
            .current_spawn_rate = gameConstants.BASE_SPAWN_RATE,
            .spawn_timer = 0.0,
            .score = 0,
            .enemies_killed_this_round = 0,
        };
    }

    pub fn update(self: *RoundManager, delta_time: f32) void {
        switch (self.round_state) {
            .active => {
                self.round_timer += delta_time;
                self.spawn_timer += delta_time;

                //  check if round is complete
                if (self.round_timer >= self.round_duration) {
                    self.completeRound();
                }
            },
            .break_time => {
                self.break_timer += delta_time;

                // check if break is over
                if (self.break_timer >= self.break_duration) {
                    self.startNextRound();
                }
            },
            .completed => {
                // Round system completed
                // TODO: change gameState
                unreachable;
            }
        }
    }

    pub fn shouldSpawnEnemy(self: * RoundManager) bool {
        if (self.round_state != .active) return false;

        if (self.spawn_timer >= self.current_spawn_rate) {
            self.spawn_timer = 0.0;
            return true;
        }
        return false;
    }

    pub fn getEnemyTypeToSpawn(self: *RoundManager) EnemyType {
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
        const random = prng.random();

        // calculate the spawn chances based on current round
        const round_factor = @divTrunc(@as(f32, @floatFromInt(self.current_round - 1)), 10);

        const random_value = random.float(f32);

        // round 1-2 only small enemies
        if (self.current_round <= 2) {
            return EnemyType.small_fast;
        }
        // round 3-5 small + medium enemies
        else if (self.current_round <= 5) {
            if (random_value < 0.7) return EnemyType.small_fast;
            return EnemyType.medium_normal;
        }
        // round 6-10 small, medium and large enemies
        else if (self.current_round <= 10) {
            if (random_value < 0.5) return EnemyType.small_fast;
            if (random_value < 0.8) return EnemyType.medium_normal;
            return EnemyType.large_slow;
        }
        // round 11+ can also spawn boss! (rare)
        else {
            const boss_change = @min(0.1, round_factor * 0.05); // max 10% chance of boss spawning
            const large_change = 0.2 + round_factor * 0.1;
            const medium_change = 0.4;

            if (random_value < boss_change) return EnemyType.boss;
            if (random_value < boss_change + large_change) return EnemyType.large_slow;
            if (random_value < boss_change + large_change + medium_change) return EnemyType.medium_normal;
            return EnemyType.small_fast;
        }
    }

    pub fn onEnemyKilled(self: *RoundManager, enemy_type: EnemyType) void {
        self.enemies_killed_this_round += 1;

        const points = switch (enemy_type) {
            .small_fast => gameConstants.SMALL_ENEMY_SCORE,
            .medium_normal => gameConstants.MEDIUM_ENEMY_SCORE,
            .large_slow => gameConstants.LARGE_ENEMY_SCORE,
            .boss => gameConstants.BOSS_ENEMY_SCORE,
        };
        self.score += points;

        std.debug.print("Enemy killed. score: {d}, Round {d}, kills this round: {d}\n", .{
            self.score, self.current_round, self.enemies_killed_this_round,
        });
    }

    fn completeRound(self: *RoundManager) void {
        std.debug.print("Round {d} completed enemies killed: {d}, total score: {d}\n", .{
            self.current_round, self.enemies_killed_this_round, self.score,
        });

        self.round_state = .break_time;
        self.break_timer = 0.0;

        // bonus points for completing round
        const round_bonus = self.current_round * 25;
        self.score += round_bonus;

        std.debug.print("Round bonus: {d} points new total: {d}\n", .{
            round_bonus, self.score,
        });
    }

    fn startNextRound(self: *RoundManager) void {
        self.current_round += 1;
        self.round_state = .active;
        self.round_timer = 0.0;
        self.enemies_killed_this_round = 0;

        // increase difficulty
        self.updateDifficulty();

        std.debug.print("Starting Round {d}, Spawn rate: {d:.2}s\n", .{
            self.current_round, self.current_spawn_rate,
        });
    }

    fn updateDifficulty(self: *RoundManager) void {
        // Decrease spawn timer (spawn enemies faster)
        const difficulty_factor = 1.0 - (@as(f32, @floatFromInt(self.current_round - 1)) * 0.05);
        self.current_spawn_rate = self.base_spawn_rate * @max(gameConstants.MIN_SPAWN_RATE, difficulty_factor); // can't go lower than min spawn rate

        // increase round duration on later rounds!
        if (self.current_round > 5) {
            self.round_duration = gameConstants.DEFAULT_ROUND_DURATION + (@as(f32, @floatFromInt(self.current_round - 5 )) * 2.0); // + 2 seconds 
        }
    }

    pub fn getRoundTimeRemaining(self: *RoundManager) f32 {
        if (self.round_state == .active) {
            return @max(0.0, self.round_duration - self.round_timer);
        }
        return 0.0;
    }

    pub fn getBreakTimeRemaining(self: *RoundManager) f32 {
        if (self.round_state == .break_time) {
            return @max(0.0, self.break_duration - self.break_timer);
        }
        return 0.0;
    }

    pub fn isRoundActive(self: *RoundManager) bool {
        return self.round_state == .active;
    }

    pub fn isBreakTime(self: *RoundManager) bool {
        return self.round_state == .break_time;
    }

    pub fn reset(self: *RoundManager) void {
        self.* = RoundManager.init();
    }

    // move this to it's own ui file!
    pub fn drawUI(self: *RoundManager) void {
        // TODO: move some of these values to gameConstants file
        const ui_color = rl.WHITE;
        const font_size = 24;
        const small_font_size = 20;

        // round info
        // TODO: pass in an allocator here!
        const round_text = std.fmt.allocPrint(std.heap.page_allocator, "Round: {d}", .{
            self.current_round,
        }) catch "Round: ?";
        defer std.heap.page_allocator.free(round_text);
        const round_text_c = std.heap.page_allocator.dupeZ(u8, round_text) catch return;
        defer std.heap.page_allocator.free(round_text_c);

        // TODO: add the positions to constants
        rl.DrawText(round_text_c.ptr, 20, 20, font_size, ui_color);

        // score
        const score_text = std.fmt.allocPrint(std.heap.page_allocator, "Score: {d}", .{
            self.score,
        }) catch "Score: ?";
        defer std.heap.page_allocator.free(score_text);
        const score_text_c = std.heap.page_allocator.dupeZ(u8, score_text) catch return;
        defer std.heap.page_allocator.free(score_text_c);

        // TODO: add the positions to constants
        rl.DrawText(score_text_c, 20, 50, font_size, ui_color);

        // timer
        if (self.round_state == .active) {
            const time_remaining = self.getRoundTimeRemaining();
            const timer_text = std.fmt.allocPrint(std.heap.page_allocator, "Time: {d:.1}s", .{
                time_remaining,
            }) catch "Time: ?";
            defer std.heap.page_allocator.free(timer_text);
            const timer_text_c = std.heap.page_allocator.dupeZ(u8, timer_text) catch return;
            defer std.heap.page_allocator.free(timer_text_c);

            // TODO: add the positions to constants
            rl.DrawText(timer_text_c, 20, 80, small_font_size, ui_color);
        }
        else if (self.round_state == .break_time) {
            const break_remaining = self.getBreakTimeRemaining();
            const break_text = std.fmt.allocPrint(std.heap.page_allocator, "Next Round: {d:.1}s", .{
                break_remaining,
            }) catch "Next Round: ?";
            defer std.heap.page_allocator.free(break_text);
            const break_text_c = std.heap.page_allocator.dupeZ(u8, break_text) catch return;
            defer std.heap.page_allocator.free(break_text_c);
            
            // TODO: add the positions to constants
            rl.DrawText(break_text_c, 20, 80, small_font_size, rl.YELLOW);
        }

        // kills this round
        const kills_text = std.fmt.allocPrint(std.heap.page_allocator, "Kills: {d}", .{
            self.enemies_killed_this_round,
        }) catch "Kills: ?";
        defer std.heap.page_allocator.free(kills_text);
        const kills_text_c = std.heap.page_allocator.dupeZ(u8, kills_text) catch return;
        defer std.heap.page_allocator.free(kills_text_c);

        // TODO: add the positions to constants
        rl.DrawText(kills_text_c, 20, 110, small_font_size, ui_color);
    }
};

