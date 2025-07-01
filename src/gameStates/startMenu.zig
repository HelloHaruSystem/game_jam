const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const StartMenuState = struct {
    selected_option: u32,

    const MenuOptions = enum(u32) {
        start_game = 0,
        quit = 1,
    };

    pub fn init() StartMenuState {
        return StartMenuState{
            .selected_option = 0,
        };
    }

    pub fn update(self : *StartMenuState, input: Input) ?GameState {
        _ = input;
        // handle menu navigation
        if (rl.IsKeyPressed(rl.KEY_UP) or rl.IsKeyPressed(rl.KEY_W)) {
            if (self.selected_option > 0) {
                self.selected_option -= 1;
            }
        }

        if (rl.IsKeyPressed(rl.KEY_DOWN) or rl.IsKeyPressed(rl.KEY_S)) {
            if (self.selected_option < 1) { // 0 and 1 are valid options
                self.selected_option += 1;
            }
        }

        // Handle selection
        if (rl.IsKeyPressed(rl.KEY_ENTER) or rl.IsKeyPressed(rl.KEY_SPACE)) {
            switch (@as(MenuOptions, @enumFromInt(self.selected_option))) {
                .start_game => {
                    self.selected_option = 0; // Reset selection
                    return GameState.playing;
                },
                .quit => {
                    // For now just close the window
                    rl.CloseWindow();
                    return null;
                },
            }
        }

        return null; // Stay in start menu
    }

    pub fn reset(self: *StartMenuState) void {
        self.selected_option = 0;
    }
};