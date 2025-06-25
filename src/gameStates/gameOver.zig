const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Input = @import("../player/input.zig").Input;
const GameState = @import("../utils/gameState.zig").GameState;
const win_consts = @import("../utils/constants/screenAndWindow.zig");

pub const GameOverState = struct {
    selected_option: u32,

    const GameOverOptions = enum(u32) {
        restart = 0,
        main_menu = 1,
        quit = 2,
    };

    pub fn init() GameOverState {
        return GameOverState{
            .selected_option = 0,
        };
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
                    // TODO: proper quit 
                },
            }
        }

        return null;
    }

    pub fn draw(self: *GameOverState) void {
        rl.ClearBackground(rl.RED);

        const center_x = win_consts.WINDOW_WIDTH / 2;
        const center_y = win_consts.WINDOW_HEIGHT / 2;

        // game over title
        const title = "GAME OVER";
        const title_font_size = 60;
        const title_width = rl.MeasureText(title, title_font_size);
        rl.DrawText(
            title,
            center_x - @divTrunc(title_width, 2),
            center_y - 150,
            title_font_size,
            rl.WHITE,
        );

        // Menu options
        const restart_text = "RESTART";
        const menu_text = "MAIN MENU";
        const quit_text = "QUIT";
        const menu_font_size = 36;

        // Restart option
        const restart_color = if (self.selected_option == 0) rl.YELLOW else rl.WHITE;
        const restart_width = rl.MeasureText(restart_text, menu_font_size);
        rl.DrawText(
            restart_text,
            center_x - @divTrunc(restart_width, 2),
            center_y - 30,
            menu_font_size,
            restart_color,
        );

        // Main menu option
        const menu_color = if (self.selected_option == 1) rl.YELLOW else rl.WHITE;
        const menu_width = rl.MeasureText(menu_text, menu_font_size);
        rl.DrawText(
            menu_text,
            center_x - @divTrunc(menu_width, 2),
            center_y + 30,
            menu_font_size,
            menu_color,
        );

        // Quit option
        const quit_color = if (self.selected_option == 2) rl.YELLOW else rl.WHITE;
        const quit_width = rl.MeasureText(quit_text, menu_font_size);
        rl.DrawText(
            quit_text,
            center_x - @divTrunc(quit_width, 2),
            center_y + 90,
            menu_font_size,
            quit_color,
        );

        // Instructions
        const instruction_text = "Use ARROW KEYS to navigate, ENTER to select, or press R for quick restart";
        const instruction_font_size = 20;
        const instruction_width = rl.MeasureText(instruction_text, instruction_font_size);
        rl.DrawText(
            instruction_text,
            center_x - @divTrunc(instruction_width, 2),
            center_y + 180,
            instruction_font_size,
            rl.LIGHTGRAY,
        );
    }
};