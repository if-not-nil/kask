const rl = @import("raylib");
const std = @import("std");

const fastnoise = @import("./fastnoise.zig");
const Tile = @import("./Tile.zig");

pub const Chunk = @This();

tiles: [256][256]Tile,
x: usize,
y: usize,
pub fn init(chunk_x: usize, chunk_y: usize) Chunk {
    // IF EVERYTHING BREAKS it could be because of me setting tiles as undefined here
    const self = Chunk{ .tiles = undefined, .x = chunk_x, .y = chunk_y };
    return self;
}

pub fn generate_dirt(self: *Chunk) void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .domain_warp_type = .simplex_reduced,
        .domain_warp_amp = 3,
        .frequency = 0.05,
    };

    for (0..256) |x| {
        const xf = @as(f32, @floatFromInt(x + (self.x * 256)));
        //
        // part 1.1: heights, 1d
        {
            // responsible for making them like go up and down
            const h_mod_raw = gen.genNoise2D(xf, 128); // Y values are arbitrary
            const h_mod: usize = @intFromFloat( // scale to [0, 15]
                @floor((h_mod_raw + 1.0) * 0.5 * 15.0));

            // responsible for the little rough edges
            const raw_top = gen.genNoise2D(xf, 0.0);
            const raw_bottom = gen.genNoise2D(xf, 255.0);

            const height_top: usize = @intFromFloat( // scale to [7, 15]
                @floor((raw_top + 1.0) * 0.5 * 14.0 + 7.0));
            const height_bottom: usize = @intFromFloat( // scale to [7, 15]
                @floor((raw_bottom + 1.0) * 0.5 * 14.0 + 7.0));

            const clamped_bottom = @min(height_bottom, 255);
            const clamped_top = @min(height_top, 255);
            for (0..160 - h_mod + clamped_top) |y| {
                self.tiles[x][y].block = .dirt;
            }
            for (220 - h_mod - clamped_bottom..256) |y| {
                self.tiles[x][y].block = .dirt;
            }
        }
        // part 1.2: caves, 2d
        for (0..256) |y| {
            if ((self.tiles[x][y]).block == .none)
                continue;

            const yf = @as(f32, @floatFromInt(y + (self.y * 256)));
            const n = gen.genNoise2D(xf, yf);
            if (n > 0.7) {
                self.tiles[x][y].block = .none;
            }
        }
    }
    // part II: make the edges pop
    for (1..255) |x| {
        for (1..255) |y| { // checkingthe edge blocks would mean asking the map for the neighbouring chunk
            if (self.tiles[x][y].block == .dirt) {
                const empty_above = self.tiles[x][y - 1].block == .none;
                const empty_below = self.tiles[x][y + 1].block == .none;
                const empty_left = self.tiles[x - 1][y].block == .none;
                const empty_right = self.tiles[x + 1][y].block == .none;
                if (empty_above or empty_below or empty_right or empty_left) {
                    self.tiles[x][y].block = .dirt;
                }
            }
        }
    }
}

pub fn generate_stone(self: *Chunk) void {
    // this should be comptime
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .frequency = 0.05,
    };
    for (0..256) |x| {
        for (0..256) |y| {
            const lc_y = y + self.y;
            const lc_x = x + self.x;
            const n = gen.genNoise2D(@floatFromInt(lc_x), @floatFromInt(lc_y));
            if (n > 0) {
                if (lc_y > 0) {
                    const above = gen.genNoise2D(@floatFromInt(x + self.x), @floatFromInt(y + self.y - 1));
                    if (above < 0) {
                        self.tiles[x][y].block = .dirt;
                        continue;
                    }
                }
                self.tiles[x][y].block = .stone;
                continue;
            }
            self.tiles[x][y].block = .none;
        }
    }
}
