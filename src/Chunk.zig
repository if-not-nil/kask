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

pub fn DEBUG_lightmap(self: *Chunk) void {
    for (0..CS) |x| {
        for (0..CS) |y| {
            rl.drawText(
                rl.textFormat("%d", .{@as(u8, self.lightmap[x][y])}),
                @intCast((self.x * CS * G.BSIZE) + x * G.BSIZE),
                @intCast((self.y * CS * G.BSIZE) + y * G.BSIZE),
                16,
                .red,
            );
        }
    }
}
