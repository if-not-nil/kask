const rl = @import("raylib");
const G = @import("./globals.zig");

const Tile = @This();

pub const BlockType = enum {
    none,
    stone,
};

pub const WallType = enum {
    none,
    stone,
    dirt,
};

block: BlockType = .none,

fn to_color(self: *const Tile) rl.Color {
    return switch (self.block) {
        .stone => rl.Color.gray,
        else => rl.Color.black,
    };
}

pub fn draw(self: *const Tile, x: i32, y: i32) void {
    rl.drawRectangle(x, y, G.BSIZE, G.BSIZE, self.to_color());
}
