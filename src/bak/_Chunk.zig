const Tile = @import("./Tile.zig");
const G = @import("./globals.zig");

const Chunk = @This();

tiles: [256][256]Tile,
x: usize,
y: usize,

pub fn init(chunk_x: usize, chunk_y: usize) Chunk {
    var chunk = Chunk{
        .tiles = undefined,
        .x = chunk_x,
        .y = chunk_y,
    };

    for (0..256) |x| {
        for (0..256) |y| {
            chunk.tiles[x][y] = Tile{ .block = .stone };
        }
    }

    return chunk;
}
