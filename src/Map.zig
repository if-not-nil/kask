const rl = @import("raylib");
const G = @import("globals.zig");
const fastnoise = @import("./fastnoise.zig");
const std = @import("std");

pub const Map = @This();
chunks: [16][16]Chunk,
gen: fastnoise.Noise(f32),

pub fn init() Map {
    var map = Map{
        .chunks = undefined,
        .gen = fastnoise.Noise(f32){
            .seed = 1337,
            .noise_type = .simplex,
            .frequency = 0.05,
        },
    };
    for (0..16) |x| {
        for (0..16) |y| {
            var chunk = Chunk.init(x, y);
            chunk.generate(&map.gen);
            map.chunks[x][y] = chunk;
        }
    }

    return map;
}
pub const Tile = struct {
    const BlockType = enum { none, stone };
    block: Tile.BlockType,
    pub fn draw(self: *const Tile, x: anytype, y: anytype) void {
        _ = self;
        rl.drawRectangle(@intCast(x), @intCast(y), G.BSIZE, G.BSIZE, .white);
    }
};

pub const Chunk = struct {
    x: usize,
    y: usize,
    tiles: [256][256]Tile,
    pub fn init(chunk_x: usize, chunk_y: usize) Chunk {
        var tiles: [256][256]Tile = undefined;
        for (0..256) |x| {
            for (0..256) |y| {
                tiles[x][y] = Tile{ .block = .none };
            }
        }
        const chunk = Chunk{ .x = chunk_x, .y = chunk_y, .tiles = tiles };
        return chunk;
    }
    pub fn generate(self: *Chunk, gen: *fastnoise.Noise(f32)) void {
        for (0..256) |x| {
            for (0..256) |y| {
                const n = gen.genNoise2D(@floatFromInt(x), @floatFromInt(y));
                // std.debug.print("n: {}\n", .{n});
                if (n > 0) {
                    self.tiles[x][y] = Tile{ .block = .stone };
                } else {
                    self.tiles[x][y] = Tile{ .block = .none };
                }
            }
        }
    }
};

pub fn get_tile(self: *Map, x: usize, y: usize) Tile {
    const chunk_x: usize = @intFromFloat(256 / @as(f32, @floatFromInt(x)));
    const chunk_y: usize = @intFromFloat(256 / @as(f32, @floatFromInt(y)));

    const local_x = x - (chunk_x * 256);
    const local_y = y - (chunk_y * 256);
    return self.chunks[chunk_x][chunk_y].tiles[local_x][local_y];
}

pub fn draw(self: *Map, area: rl.Rectangle) void {
    const x_start = @as(usize, @intFromFloat(area.x));
    const y_start = @as(usize, @intFromFloat(area.y));
    const x_end = x_start + @as(usize, @intFromFloat(area.width));
    const y_end = y_start + @as(usize, @intFromFloat(area.height));

    for (x_start..@min(x_end, self.chunks.len * 256)) |x| {
        for (y_start..@min(y_end, self.chunks.len * 256)) |y| {
            const tile = self.get_tile(x, y);
            tile.draw(x, y);
        }
    }
}
// x/y params are for the box of drawn tiles
// pub fn draw(self: *Map, area: rl.Rectangle) void {
//     const x_start = @as(usize, @intFromFloat(area.x));
//     const y_start = @as(usize, @intFromFloat(area.y));
//     const x_end = x_start + @as(usize, @intFromFloat(area.width));
//     const y_end = y_start + @as(usize, @intFromFloat(area.height));
//
//     for (x_start..@min(x_end, self.data.len)) |x| {
//         for (y_start..@min(y_end, self.data.len)) |y| {
//             const color: u8 = @intCast(self.data[x][y]);
//             rl.drawRectangle(
//                 @as(i32, @intCast(x)) * G.BSIZE,
//                 @as(i32, @intCast(y)) * G.BSIZE,
//                 G.BSIZE,
//                 G.BSIZE,
//                 rl.Color.init(color * 255, color * 255, color * 255, 255),
//             );
//         }
//     }
// }
