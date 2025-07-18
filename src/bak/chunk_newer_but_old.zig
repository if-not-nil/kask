const rl = @import("raylib");
const std = @import("std");
const G = @import("globals.zig");
const CS = G.CHUNK_SIZE;

const fastnoise = @import("./fastnoise.zig");
const Tile = @import("./Tile.zig");
const Vec2i = struct { x: i32, y: i32 };

pub const Chunk = @This();

tiles: [CS][CS]Tile,
lightmap: [CS][CS]u4,
x: usize,
y: usize,

pub fn init(chunk_x: usize, chunk_y: usize) Chunk {
    var tiles: [CS][CS]Tile = undefined;
    for (0..CS) |x| {
        tiles[x] = @splat(Tile.None);
    }

    const self = Chunk{
        .tiles = tiles,
        .lightmap = [_][CS]u4{[_]u4{0} ** CS} ** CS,
        .x = chunk_x,
        .y = chunk_y,
    };
    return self;
}

pub fn set_tile(self: *Chunk, x: anytype, y: anytype, block: Tile) void {
    const rx: usize = @intCast(x);
    const ry: usize = @intCast(y);
    self.tiles[rx][ry] = block;
}

pub fn generate_surface(self: *Chunk) void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .domain_warp_type = .simplex_reduced,
        .domain_warp_amp = 5,
        .frequency = 0.05,
    };
    for (0..G.CHUNK_SIZE) |x| {
        const xf = @as(f32, @floatFromInt(x + (self.x * CS)));
        const n = gen.genNoise2D(xf, 0);
        const height: usize = @intFromFloat( // scale to [7, 15]
            @floor((n + 1.0) * 0.5 * 14.0 + 7.0));
        const clamped = @min(height, CS - 1);
        for (CS - clamped..CS) |y| { // i guess its one block higher for no reason
            self.set_tile(x, y, Tile.Dirt);
        }
    }
}

pub fn generate_dirt(self: *Chunk) void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .domain_warp_type = .simplex_reduced,
        .domain_warp_amp = 3,
        .frequency = 0.05,
    };

    var bleed_buf: [G.CHUNK_SIZE]Vec2i = undefined;
    var bleed_buf_count: usize = 0;
    inline for (0..G.CHUNK_SIZE) |i|
        bleed_buf[i] = Vec2i{ .x = 0, .y = 0 };

    for (0..CS) |x| {
        const xf = @as(f32, @floatFromInt(x + (self.x * CS)));
        // =====================
        // part 1.1: heights, 1d
        {
            // responsible for making them like go up and down
            const h_mod_raw = gen.genNoise2D(xf, 128); // Y values are arbitrary
            const h_mod: usize = @intFromFloat( // scale to [0, 15]
                @floor((h_mod_raw + 1.0) * 0.5 * 15.0));

            // responsible for the little rough edges
            const raw_top = gen.genNoise2D(xf, 0.0);
            const raw_bottom = gen.genNoise2D(xf, CS - 1);

            const height_top: usize = @intFromFloat( // scale to [7, 15]
                @floor((raw_top + 1.0) * 0.5 * 14.0 + 7.0));
            const height_bottom: usize = @intFromFloat( // scale to [7, 15]
                @floor((raw_bottom + 1.0) * 0.5 * 14.0 + 7.0));

            const clamped_bottom = @min(height_bottom, CS - 1);
            const clamped_top = @min(height_top, CS - 1);
            for (0..@as(usize, @intFromFloat(@divTrunc(CS, 1.5))) - h_mod + clamped_top) |y| {
                self.tiles[x][y] = Tile.Dirt;
            }
            for (@as(usize, @intFromFloat(@divTrunc(CS, 1.1))) - h_mod - clamped_bottom..CS) |y| {
                self.tiles[x][y] = Tile.Dirt;
            }
            // if (clamped_bottom < 9) {
            //     bleed_buf[bleed_buf_count] = .{
            //         .x = @intCast(x),
            //         .y = @intCast(220 - h_mod - clamped_bottom),
            //     };
            //     bleed_buf_count += 1;
            // }
            if (clamped_bottom < 9) {
                bleed_buf[bleed_buf_count] = .{
                    .x = @intCast(x),
                    // or 220 - h_mod - clamped_bottom
                    .y = @intCast(@as(usize, @intFromFloat(@divTrunc(CS, 1.2))) + h_mod - clamped_bottom),
                };
                bleed_buf_count += 1;
            }
        }
        // part 1.2: caves, 2d
        for (0..CS) |y| {
            if ((self.tiles[x][y]).block == .none)
                continue;

            const yf = @as(f32, @floatFromInt(y + (self.y * CS)));
            const n = gen.genNoise2D(xf, yf);
            if (n > 0.7) {
                self.tiles[x][y] = Tile.None;
            }
        }
    }
    // part II: stonebleeds
    for (bleed_buf[0..bleed_buf_count]) |pos| {
        const xf = G.F32(pos.x + @as(i32, @intCast(self.x * CS)));
        const yf = G.F32(pos.y + @as(i32, @intCast(self.y * CS)));

        var n = gen.genNoise2D(xf, yf);
        const base = n - 0.5;

        var i: i32 = 0;
        const max_depth: i32 = CS / 4;

        while (i < max_depth) : (i += 1) {
            const sample_yf = yf + G.F32(i);
            n = gen.genNoise2D(xf, sample_yf);
            if (n < base) break;

            const world_x = pos.x + G.I32(n);
            const world_y = pos.y + i;
            if (world_y >= 0 and world_y < CS) { // clamp to tile bounds
                self.set_tile(world_x, world_y, Tile.Stone);
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
    for (0..CS) |x| {
        for (0..CS) |y| {
            const lc_y = y + self.y;
            const lc_x = x + self.x;
            const n = gen.genNoise2D(@floatFromInt(lc_x), @floatFromInt(lc_y));
            if (n > 0) {
                if (lc_y > 0) {
                    const above = gen.genNoise2D(@floatFromInt(x + self.x), @floatFromInt(y + self.y - 1));
                    if (above < 0) {
                        self.tiles[x][y] = Tile.Dirt;
                        continue;
                    }
                }
                self.tiles[x][y] = Tile.Stone;
                continue;
            }
            self.tiles[x][y] = Tile.None;
        }
    }
}
