const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const ControlsMenuState = struct {
    pub fn init() ControlsMenuState {
        return ControlsMenuState{};
    }

    pub fn update(self: *ControlsMenuState, input: Input) ?GameState {
        _ = self;
        _ = input;

        // Return to start menu on escape, enter, or space
        if (rl.IsKeyPressed(rl.KEY_ESCAPE) or 
           rl.IsKeyPressed(rl.KEY_ENTER) or 
           rl.IsKeyPressed(rl.KEY_SPACE)) {
            return GameState.start_menu;
        }

        return null;
    }

    pub fn reset(self: *ControlsMenuState) void {
        _ = self; // Nothing to reset
    }
};