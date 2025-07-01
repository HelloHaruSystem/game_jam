const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const paths = @import("../utils/paths.zig");
const gameConstants = @import("../utils/constants/gameConstants.zig");


pub const TileType = enum(u8) {
    grass = 1,
    water = 2,
    solid = 3,

    pub fn isSolid(self: TileType) bool {
        return self == .solid;
    }

    pub fn getMovementModifier(self: TileType) f32 {
        return switch (self) {
            .grass => 1.0,          // normal speed
            .water => 0.6,          // slower speed
            .solid => 0.0,          // no speed because solid
        };
    }
};

pub const Tilemap = struct {
    map_texture: rl.Texture2D,
    tile_data: [][]u8,
    map_width: u32,
    map_height: u32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Tilemap {
        // load the map image
        const map_path = try paths.getTilemapImage(allocator);
        defer allocator.free(map_path);
        const map_path_c = try allocator.dupeZ(u8, map_path);
        defer allocator.free(map_path_c);
        const map_texture = rl.LoadTexture(map_path_c.ptr);

        // load the csv data for the tilemap
        const csv_path = try paths.getTilemapCsv(allocator);
        defer allocator.free(csv_path);

        const csv_content = std.fs.cwd().readFileAlloc(allocator, csv_path, 1024 * 1024) catch |err| {
            std.debug.print("Failed to load tilemap CSV: {}\n", .{err});
            return err;
        };
        defer allocator.free(csv_content);

        // parse csv
        var tilemap = Tilemap{
            .map_texture = map_texture,
            .tile_data = undefined,
            .map_width = 0,
            .map_height = 0,
            .allocator = allocator,
        };

        try tilemap.parseCsv(csv_content);
        
        std.debug.print("Loaded tilemap: {}x{} tiles ({}x{} pixels)\n", .{
            tilemap.map_width, tilemap.map_height,
            tilemap.map_width * 16, tilemap.map_height * 16, 
        });

        return tilemap;
    }

    pub fn deinit(self: *Tilemap) void {
        // free tile data
        for (self.tile_data) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.tile_data);

        // unload textures
        rl.UnloadTexture(self.map_texture);
    }

    fn parseCsv(self: *Tilemap, csv_content: []const u8) !void {
        // count rows first
        var line_count: u32 = 0;
        var lines = std.mem.splitSequence(u8, csv_content, "\n");
        while (lines.next()) |_| {
            line_count += 1;
        }

        if (line_count == 0) return error.EmptyCSV;

        // Parse first line to get width
        lines = std.mem.splitSequence(u8, csv_content, "\n");
        const first_line = lines.next() orelse return error.EmptyCSV;
        var col_count: u32 = 0;
        var values = std.mem.splitSequence(u8, first_line, ",");
        while (values.next()) |_| {
            col_count += 1;
        }

        self.map_width = col_count;
        self.map_height = line_count;

        // allocate tile data
        self.tile_data = try self.allocator.alloc([]u8, self.map_height);
        for (self.tile_data) |*row| {
            row.* = try self.allocator.alloc(u8, self.map_width);
        }

        // parse all lines
        lines = std.mem.splitSequence(u8, csv_content, "\n");
        var row: u32 = 0;
        while (lines.next()) |line| : (row += 1) {
            if (row >= self.map_height) break;

            var col: u32 = 0;
            var line_values = std.mem.splitSequence(u8, line, ",");
            while (line_values.next()) |value_str| : (col += 1) {
                if (col >= self.map_width) break;

                // parse the number
                const trimmed = std.mem.trim(u8, value_str, " \t\r\n");
                const tile_value = std.fmt.parseInt(u8, trimmed, 10) catch 1; // sets the default to 1 (grass)
                self.tile_data[row][col] = tile_value;
            }
        }
    }

    pub fn getTileAt(self: *const Tilemap, world_x: f32, world_y: f32) ?TileType {
        // Return null for negative coordinates
        if (world_x < 0 or world_y < 0) {
            return null;
        }
        
        const tile_x = @as(u32, @intFromFloat(world_x / gameConstants.TILE_SIZE));
        const tile_y = @as(u32, @intFromFloat(world_y / gameConstants.TILE_SIZE));

        if (tile_x >= self.map_width or tile_y >= self.map_height) {
            return null;
        }

        const tile_value = self.tile_data[tile_y][tile_x];
        return switch (tile_value) {
            1 => TileType.grass,
            2 => TileType.water,
            3 => TileType.solid,
            else => TileType.grass, // using grass as default again
        };
    }

    pub fn isPositionSolid(self: *const Tilemap, world_x: f32, world_y: f32) bool {
        if (self.getTileAt(world_x, world_y)) |tile_type| {
            return tile_type.isSolid();
        }
        return true; // Treat out-of-bounds as solid
    }

    pub fn getMovementModifierAt(self: *const Tilemap, world_x: f32, world_y: f32) f32 {
        if (self.getTileAt(world_x, world_y)) |tile_type| {
            return tile_type.getMovementModifier();
        }
        return 1.0; // Default speed
    }

    pub fn draw(self: *const Tilemap) void {
        // Draw the map image
        rl.DrawTexture(self.map_texture, 0, 0, rl.WHITE);
    }

    // Get map dimensions in world coordinates
    pub fn getWorldWidth(self: *const Tilemap) f32 {
        return @as(f32, @floatFromInt(self.map_width)) * gameConstants.TILE_SIZE;
    }
    
    pub fn getWorldHeight(self: *const Tilemap) f32 {
        return @as(f32, @floatFromInt(self.map_height)) * gameConstants.TILE_SIZE;
    }
};