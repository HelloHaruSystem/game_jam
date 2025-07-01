const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const PauseMenuState = struct {
    selected_option: u32,

    const PauseMenuOptions = enum(u32) {
        resume_game = 0,
        main_menu = 1,
        quit = 2,
    };

    pub fn init() PauseMenuState {
        return PauseMenuState{
            .selected_option = 0,
        };
    }

    pub fn update(self: *PauseMenuState, input: Input) ?GameState {
        _ = input;

        // Handle menu nav
        if (rl.IsKeyPressed(rl.KEY_UP) or rl.IsKeyPressed(rl.KEY_W)) {
            if (self.selected_option > 0) {
                self.selected_option -= 1;
            }
        }

        if (rl.IsKeyPressed(rl.KEY_DOWN) or rl.IsKeyPressed(rl.KEY_S)) {
            if (self.selected_option < 2) {
                self.selected_option += 1;
            }
        }

        // Handle selection
        if (rl.IsKeyPressed(rl.KEY_ENTER) or rl.IsKeyPressed(rl.KEY_SPACE)) {
            switch (@as(PauseMenuOptions, @enumFromInt(self.selected_option))) {
                .resume_game => {
                    self.selected_option = 0; // Reset selection
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

        // make esc key resume
        if (rl.IsKeyPressed(rl.KEY_ESCAPE)) {
            self.selected_option = 0;
            return GameState.playing;
        }

        return null; // Stay in pause menu
    }

    pub fn reset(self: *PauseMenuState) void {
        self.selected_option = 0;
    }
};