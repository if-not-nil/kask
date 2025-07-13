const G = @import("globals.zig");

const Chunk = @import("Chunk.zig");

const World = @This();

chunks: [G.WSIZE][G.WSIZE]Chunk,
pub fn init() World {
    var world = World{ .chunks = undefined };
    for (0..G.WSIZE) |x| {
        for (0..G.WSIZE) |y| {
            world.chunks[x][y] = Chunk.init();
        }
    }
    return world;
}
pub fn draw(self: *World) void {
    _ = self;
}
