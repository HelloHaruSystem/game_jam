const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const RoundManager = @import("../utils/roundManager.zig").RoundManager;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const GameOverState = struct {
    selected_option: u32,
    final_score: u32,
    final_round: u32,

    const GameOverOptions = enum(u32) {
        restart = 0,
        main_menu = 1,
        quit = 2,
    };

    pub fn init() GameOverState {
        return GameOverState{
            .selected_option = 0,
            .final_score = 0,
            .final_round = 1,
        };
    }

    pub fn setFinalStats(self: *GameOverState, round_manager: *const RoundManager) void  {
        self.final_score = round_manager.score;
        self.final_round = round_manager.current_round;
    }

    pub fn update(self: *GameOverState, input: Input) ?GameState {
        // handle menu navigation
        if (rl.IsKeyPressed(rl.KEY_UP) or input.move_up) {
            if (self.selected_option > 0) {
                self.selected_option -= 1;
            }
        }

        if (rl.IsKeyPressed(rl.KEY_DOWN) or input.move_down) {
            if (self.selected_option < 2) {
                self.selected_option += 1;
            }
        }   

        // handle navigation
        if (rl.IsKeyPressed(rl.KEY_ENTER) or input.shoot) {
            switch (@as(GameOverOptions, @enumFromInt(self.selected_option))) {
                .restart => {
                    self.selected_option = 0;   // reset selection
                    return GameState.playing;
                },
                .main_menu => {
                    self.selected_option = 0;
                    return GameState.start_menu;
                },
                .quit => {
                    self.selected_option = 0;
                    return GameState.quit;
                },
            }
        }

        return null;
    }

};