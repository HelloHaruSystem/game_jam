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
            .break_time = 0.0,
            .break_duration = gameConstants.DEFAULT_BREAK_DURATION,
            .base_spawn_rate = gameConstants.BASE_SPAWN_RATE,
            .current_spawn_rate = gameConstants.BASE_SPAWN_RATE,
            .spawn_timer = 0.0,
            .score = 0,
            .enemies_killed_this_round = 0,
        };
    }

    pub fn update(self: *RoundManager, delta_time: f32) void {
        switch (RoundState) {
            .active => {
                self.round_timer += delta_time;
                self.spawn_timer += delta_time;

                //  check if round is complete
                if (self.round_timer >= self.round_duration) {
                    self.completeRound();
                }
            }
        }
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
};

