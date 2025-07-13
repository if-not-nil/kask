const Chunk = @This();

tiles: [256][256]i32,

pub fn init() Chunk {
    var tiles: [256][256]i32 = undefined;
    for (1..tiles.len) |x| {
        for (0..tiles[0].len) |y| {
            tiles[x][y] = 1;
        }
    }

    return Chunk{ .tiles = tiles };
}
