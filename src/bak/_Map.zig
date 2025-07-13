const std = @import("std");

const Chunk = @import("./Chunk.zig");
const G = @import("./globals.zig");
const Tile = @import("./Tile.zig");

const Map = @This();

// 1024 chunks
// each is 256x256, the same amount of tiles a 16x16x256 minecraft chunk would have
// except max 4 should really be visible at all times
chunks: [G.WSIZE][G.WSIZE]Chunk,
gen: i32,

pub fn init(seed: i32) Map {
    var map = Map{ .chunks = undefined, .gen = seed };

    for (0..G.WSIZE) |x| {
        for (0..G.WSIZE) |y| {
            map.chunks[x][y] = Chunk.init(x, y);
        }
    }
    return map;
}

pub fn tile_at(self: *Map, x: usize, y: usize) *Tile {
    const chunk_x = x / G.CSIZE;
    const chunk_y = y / G.CSIZE;

    if (chunk_x >= G.WSIZE or chunk_y >= G.WSIZE) {
        std.debug.panic("Out of world bounds: chunk_x={}, chunk_y={}\n", .{ chunk_x, chunk_y });
    }

    const local_x = x % G.CSIZE;
    const local_y = y % G.CSIZE;

    return &self.chunks[chunk_x][chunk_y].tiles[local_x][local_y];
}

pub fn draw(self: *Map, x_start: usize, y_start: usize, w: usize, h: usize) !void {
    const max_tile = G.WSIZE * G.CSIZE;

    for (x_start..@min(x_start + w, max_tile)) |x| {
        for (y_start..@min(y_start + h, max_tile)) |y| {
            const t = self.tile_at(x, y);
            t.draw(@intCast(x * G.BSIZE), @intCast(y * G.BSIZE));
        }
    }
}
