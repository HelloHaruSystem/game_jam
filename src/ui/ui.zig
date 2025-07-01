const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Player = @import("../player/player.zig").Player;
const RoundManager = @import("../utils/roundManager.zig").RoundManager;
const ProjectileManager = @import("../projectile/projectile.zig").ProjectileManager;
const gameConstants = @import("../utils/constants/gameConstants.zig");

pub const UI = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) UI {
        return UI{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *UI) void {
        _ = self; // UI doesn't own any resources
    }

    // main gameplay UI drawing function
    pub fn drawGameplayUI(self: *UI, player: *const Player, round_manager: *const RoundManager) void {
        self.drawFPS();
        self.drawHealthHearts(player);
        self.drawRoundInfo(round_manager);
        self.drawScore(round_manager);
        self.drawTimer(round_manager);
        self.drawKillCount(round_manager);
    }

    // FPS counter top right
    fn drawFPS(self: *UI) void {
        const fps = rl.GetFPS();
        const fps_text = std.fmt.allocPrint(self.allocator, "FPS: {d}", .{ fps, }) catch "FPS: ?";
        defer self.allocator.free(fps_text);
        const fps_text_c = self.allocator.dupeZ(u8, fps_text) catch return;
        defer self.allocator.free(fps_text_c);

        const text_width = rl.MeasureText(fps_text_c.ptr, 20);
        // TODO:  add some if these ui values to constants module
        rl.DrawText(fps_text_c, gameConstants.WINDOW_WIDTH - text_width - 20, 20, 20, rl.WHITE);
    }

     fn drawHealthHearts(self: *UI, player: *const Player) void {
        const total_width = (gameConstants.DEFAULT_PLAYER_MAX_HEALTH * gameConstants.HEART_SPACING) - (gameConstants.HEART_SPACING - gameConstants.HEART_SIZE);
        const start_x = (gameConstants.WINDOW_WIDTH / 2) - (total_width / 2);

        var i: u32 = 0;
        while (i < gameConstants.DEFAULT_PLAYER_MAX_HEALTH) : (i += 1) {
            const x_pos = start_x + (i * gameConstants.HEART_SPACING);

            // determine heart color lose hearts from right to left
            const heart_lost = gameConstants.DEFAULT_PLAYER_MAX_HEALTH - player.current_health;
            const is_lost_heart = i >= (gameConstants.DEFAULT_PLAYER_MAX_HEALTH - heart_lost);
            const heart_color = if (is_lost_heart) rl.BLACK else rl.RED;

            // draw diamond for now
            self.drawHeart(@intCast(x_pos), @intCast(gameConstants.UI_TOP_LINE_Y), @intCast(gameConstants.HEART_SIZE), heart_color);
        }
    }

    // TODO: find a heart sprite
    // for now it will be be something somewhat similar
    fn drawHeart(self: *UI, x: i32, y: i32, size: i32, color: rl.Color) void {
        _ = self; // unused

        // simple heart shape using different shapes???
        const half_size = @divTrunc(size, 2);
        const quarter_size = @divTrunc(size, 4);

        // top two circles
        rl.DrawCircle(x + quarter_size, y + quarter_size, @floatFromInt(quarter_size), color);
        rl.DrawCircle(x + (3 * quarter_size), y + quarter_size, @floatFromInt(quarter_size), color);

        // bottom triangle
        rl.DrawTriangle(
            rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y + half_size), },
            rl.Vector2{ .x = @floatFromInt(x + size), .y = @floatFromInt(y + half_size), },
            rl.Vector2{ .x = @floatFromInt(x + half_size), .y = @floatFromInt(y + size), },
            color
        );

        // fill the middle rectangle
        rl.DrawRectangle(x + quarter_size, y + quarter_size, half_size, quarter_size, color);
    }

    // round info (top left)
    fn drawRoundInfo(self: *UI, round_manager: *const RoundManager) void {
        const round_text = std.fmt.allocPrint(self.allocator, "Round: {d}", .{
            round_manager.current_round,
        }) catch "Round: ?";
        defer self.allocator.free(round_text);
        const round_text_c = self.allocator.dupeZ(u8, round_text) catch return;
        defer self.allocator.free(round_text_c);

        rl.DrawText(
            round_text_c,
            gameConstants.UI_TOP_LINE_X,
            gameConstants.UI_TOP_LINE_Y,
            gameConstants.UI_FONT_SIZE,
            gameConstants.UI_TEXT_COLOR
        );
    }

    // score (top left below round info)
    fn drawScore(self: *UI, round_manager: *const RoundManager) void {
        const score_text = std.fmt.allocPrint(self.allocator, "Score: {d}", .{
            round_manager.score, 
        }) catch "Score: ?";
        defer self.allocator.free(score_text);
        const score_text_c = self.allocator.dupeZ(u8, score_text) catch return;
        defer self.allocator.free(score_text_c);

        rl.DrawText(
            score_text_c,
            gameConstants.UI_TOP_LINE_X,
            gameConstants.UI_TOP_LINE_Y + 30,
            gameConstants.UI_SMALL_FONT_SIZE,
            gameConstants.UI_TEXT_COLOR
        );
    }

    // timer (top left below score)
    fn drawTimer(self: *UI, round_manager: *const RoundManager) void {
        if (round_manager.round_state == .active) {
            const time_remaining = round_manager.getRoundTimeRemaining();
            const timer_text = std.fmt.allocPrint(self.allocator, "Time: {d:.1}s", .{
                time_remaining, 
            }) catch "Time: ?";
            defer self.allocator.free(timer_text);
            const time_text_c = self.allocator.dupeZ(u8, timer_text) catch return;
            defer self.allocator.free(time_text_c);

            rl.DrawText(
                time_text_c,
                gameConstants.UI_TOP_LINE_X,
                gameConstants.UI_TOP_LINE_Y + 60,
                gameConstants.UI_SMALL_FONT_SIZE,
                gameConstants.UI_TEXT_COLOR
            );
        } else if (round_manager.round_state == .break_time) {
            const break_remaining = round_manager.getBreakTimeRemaining();
            const break_text = std.fmt.allocPrint(self.allocator, "Next Round: {d:.1}s", .{
                break_remaining,
            }) catch "Next Round: =";
            defer self.allocator.free(break_text);
            const break_text_c = self.allocator.dupeZ(u8, break_text) catch return;
            defer self.allocator.free(break_text_c);

            rl.DrawText(break_text_c,
                gameConstants.UI_TOP_LINE_X,
                gameConstants.UI_TOP_LINE_Y + 60,
                gameConstants.UI_SMALL_FONT_SIZE,
                rl.YELLOW
            );
        }
    }

    // draw kill count for current round (top left below timer)
    fn drawKillCount(self: *UI, round_manager: *const RoundManager) void {
        const kill_text = std.fmt.allocPrint(self.allocator, "Kills: {d}", .{
            round_manager.enemies_killed_this_round, 
        }) catch "Kills: ?";
        defer self.allocator.free(kill_text);
        const kill_text_c = self.allocator.dupeZ(u8, kill_text) catch return;
        defer self.allocator.free(kill_text_c);

        rl.DrawText(
            kill_text_c,
            gameConstants.UI_TOP_LINE_X,
            gameConstants.UI_TOP_LINE_Y + 90,
            gameConstants.UI_SMALL_FONT_SIZE,
            gameConstants.UI_TEXT_COLOR
        );
    }

    pub fn drawStartMenu(self: *UI, selected_option: u32) void {
        _ = self;
        rl.ClearBackground(rl.BLACK);

        const center_x = gameConstants.WINDOW_WIDTH / 2;
        const center_y = gameConstants.WINDOW_HEIGHT / 2;

        // game title
        const title = "The Duck Massacre";
        const title_font_size = 90;
        const title_width = rl.MeasureText(title, title_font_size);

        rl.DrawText(
            title,
            center_x - @divTrunc(title_width, 2),
            center_y - 150,
            title_font_size,
            rl.RED,
        );

        // subtitle
        const subtitle = "For Tec Game Jam by Halfdan";
        const subtitle_font_size = 24;
        const subtitle_width = rl.MeasureText(subtitle, subtitle_font_size);

        rl.DrawText(
            subtitle,
            center_x - @divTrunc(subtitle_width, 2),
            center_y - 70,
            subtitle_font_size,
            rl.LIGHTGRAY,
        );

        // menu options
        const start_text = "START GAME";
        const controls_text = "CONTROLS";
        const quit_text = "QUIT";
        const menu_font_size = 36;

        // start game options
        const start_color = if (selected_option == 0) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const start_width = rl.MeasureText(start_text, menu_font_size);

        rl.DrawText(
            start_text,
            center_x - @divTrunc(start_width, 2),
            center_y + 20,
            menu_font_size,
            start_color,
        );

        // controls option
        const controls_color = if (selected_option == 1) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const controls_width = rl.MeasureText(controls_text, menu_font_size);

        rl.DrawText(
            controls_text,
            center_x - @divTrunc(controls_width, 2),
            center_y + 80,
            menu_font_size,
            controls_color,
        );

        // quit option
        const quit_color = if (selected_option == 2) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const quit_width = rl.MeasureText(quit_text, menu_font_size);

        rl.DrawText(
            quit_text,
            center_x - @divTrunc(quit_width, 2),
            center_y + 140,
            menu_font_size,
            quit_color
        );


        // Instructions
        const instruction_text = "Use ARROW KEYS or WASD to navigate, ENTER or SPACE to select";
        const instruction_font_size = 20;
        const instruction_width = rl.MeasureText(instruction_text, instruction_font_size);
        
        rl.DrawText(
            instruction_text,
            center_x - @divTrunc(instruction_width, 2),
            center_y + 220,
            instruction_font_size,
            rl.DARKGRAY
        );
    }

    pub fn drawControlsMenu(self: *UI) void {
        _ = self;
        rl.ClearBackground(rl.BLACK);

        const center_x = gameConstants.WINDOW_WIDTH / 2;
        const center_y = gameConstants.WINDOW_HEIGHT / 2;

        // Title
        const title = "CONTROLS";
        const title_font_size = 60;
        const title_width = rl.MeasureText(title, title_font_size);
        
        rl.DrawText(
            title,
            center_x - @divTrunc(title_width, 2),
            center_y - 200,
            title_font_size,
            rl.YELLOW
        );

        // Controls explanation
        const control1 = "MOVE: WASD or Arrow Keys";
        const control2 = "AIM: Mouse";
        const control3 = "SHOOT: Space Bar";
        const control4 = "PAUSE: Escape Key";

        const control_font_size = 32;

        // Draw each control individually
        var text_width = rl.MeasureText(control1, control_font_size);
        rl.DrawText(
            control1,
            center_x - @divTrunc(text_width, 2),
            center_y - 80,
            control_font_size,
            gameConstants.UI_TEXT_COLOR
        );

        text_width = rl.MeasureText(control2, control_font_size);
        rl.DrawText(
            control2,
            center_x - @divTrunc(text_width, 2),
            center_y - 20,
            control_font_size,
            gameConstants.UI_TEXT_COLOR
        );

        text_width = rl.MeasureText(control3, control_font_size);
        rl.DrawText(
            control3,
            center_x - @divTrunc(text_width, 2),
            center_y + 40,
            control_font_size,
            gameConstants.UI_TEXT_COLOR
        );

        text_width = rl.MeasureText(control4, control_font_size);
        rl.DrawText(
            control4,
            center_x - @divTrunc(text_width, 2),
            center_y + 100,
            control_font_size,
            gameConstants.UI_TEXT_COLOR
        );

        // game explained
        const info_text = "Survive waves of enemies and get the highest score!";
        const info_font_size = 24;
        const info_width = rl.MeasureText(info_text, info_font_size);
        
        rl.DrawText(
            info_text,
            center_x - @divTrunc(info_width, 2),
            center_y + 160,
            info_font_size,
            rl.LIGHTGRAY
        );

        // how to go back
        const back_text = "Press ESCAPE, ENTER, or SPACE to go back";
        const back_font_size = 20;
        const back_width = rl.MeasureText(back_text, back_font_size);
        
        rl.DrawText(
            back_text,
            center_x - @divTrunc(back_width, 2),
            center_y + 220,
            back_font_size,
            rl.DARKGRAY
        );
    }

    pub fn drawPauseMenu(self: *UI, selected_option: u32) void {
        _ = self;

        // draw the somewhat transparent overlay for the NICE pause effect :)
        rl.DrawRectangle(0, 0, gameConstants.WINDOW_WIDTH, gameConstants.WINDOW_HEIGHT,
            rl.Color{ .r = 0, .g = 0, .b = 0, .a = 150, }); // transparent black overlay
        
        const center_x = gameConstants.WINDOW_WIDTH / 2;
        const center_y = gameConstants.WINDOW_HEIGHT / 2;

        // Pause title
        const title = "GAME PAUSED";
        const title_font_size = 60;
        const title_width = rl.MeasureText(title, title_font_size);
        
        rl.DrawText(
            title,
            center_x - @divTrunc(title_width, 2),
            center_y - 120,
            title_font_size,
            rl.YELLOW
        );

        // Menu options
        const resume_text = "RESUME";
        const menu_text = "MAIN MENU";
        const quit_text = "QUIT";
        const menu_font_size = 36;

        // Resume option
        const resume_color = if (selected_option == 0) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const resume_width = rl.MeasureText(resume_text, menu_font_size);

        rl.DrawText(
            resume_text,
            center_x - @divTrunc(resume_width, 2),
            center_y - 20,
            menu_font_size,
            resume_color
        );

        // Main Menu option
        const menu_color = if (selected_option == 1) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const menu_width = rl.MeasureText(menu_text, menu_font_size);

        rl.DrawText(
            menu_text,
            center_x - @divTrunc(menu_width, 2),
            center_y + 40,
            menu_font_size,
            menu_color
        );

        // Quit option
        const quit_color = if (selected_option == 2) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const quit_width = rl.MeasureText(quit_text, menu_font_size);

        rl.DrawText(
            quit_text,
            center_x - @divTrunc(quit_width, 2),
            center_y + 100,
            menu_font_size,
            quit_color
        );

        // Instructions
        const instruction_text = "Use ARROW KEYS or WASD to navigate, ENTER/SPACE to select, ESC to resume";
        const instruction_font_size = 20;
        const instruction_width = rl.MeasureText(instruction_text, instruction_font_size);
        
        rl.DrawText(
            instruction_text,
            center_x - @divTrunc(instruction_width, 2),
            center_y + 180,
            instruction_font_size,
            rl.LIGHTGRAY
        );

    }

    // game over menu
    pub fn drawGameOverUI(self: *UI, selected_option: u32, final_score: u32, final_round: u32) void {
        rl.ClearBackground(rl.RED);

        const center_x = gameConstants.WINDOW_WIDTH / 2;
        const center_y = gameConstants.WINDOW_HEIGHT / 2;

        // game over title
        const title = "GAME OVER";
        const title_font_size = 60;
        const title_width = rl.MeasureText(title, title_font_size);
        
        rl.DrawText(
            title,
            center_x - @divTrunc(title_width, 2),
            center_y - 200,
            title_font_size,
            gameConstants.UI_TEXT_COLOR
        );

        // final score and round display
        const score_text = std.fmt.allocPrint(self.allocator, "Final Score: {d}", .{
            final_score, 
        }) catch "Final Score. ?";
        defer self.allocator.free(score_text);
        const score_text_c = self.allocator.dupeZ(u8, score_text) catch return;
        defer self.allocator.free(score_text_c);

        const score_width = rl.MeasureText(score_text_c, 36);
        rl.DrawText(
            score_text_c,
            center_x - @divTrunc(score_width, 2),
            center_y - 120,
            36,
            rl.YELLOW,
        );

        const round_text = std.fmt.allocPrint(self.allocator, "Reached Round: {d}", .{
            final_round, 
        }) catch "Reached Round ?";
        defer self.allocator.free(round_text);
        const round_text_c = self.allocator.dupeZ(u8, round_text) catch return;
        defer self.allocator.free(round_text_c);

        const round_width = rl.MeasureText(round_text_c, 24);
        rl.DrawText(
            round_text_c,
            center_x - @divTrunc(round_width, 2),
            center_y - 80,
            24,
            rl.LIGHTGRAY,
        );

        // menu options
        const restart_text = "RESTART";
        const menu_text = "MAIN MENU";
        const quit_text = "QUIT";
        const menu_font_size = 36;

        // Restart option
        const restart_color = if (selected_option == 0) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const restart_width = rl.MeasureText(restart_text, menu_font_size);

        rl.DrawText(
            restart_text,
            center_x - @divTrunc(restart_width, 2),
            center_y - 10,
            menu_font_size,
            restart_color
        );

        // Main menu option
        const menu_color = if (selected_option == 1) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const menu_width = rl.MeasureText(menu_text, menu_font_size);

        rl.DrawText(
            menu_text,
            center_x - @divTrunc(menu_width, 2),
            center_y + 50,
            menu_font_size,
            menu_color,
        );

        // Quit option
        const quit_color = if (selected_option == 2) rl.YELLOW else gameConstants.UI_TEXT_COLOR;
        const quit_width = rl.MeasureText(quit_text, menu_font_size);

        rl.DrawText(
            quit_text,
            center_x - @divTrunc(quit_width, 2),
            center_y + 110,
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
            center_y + 200,
            instruction_font_size,
            rl.LIGHTGRAY,
        );
    }
};