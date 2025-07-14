const rl = @import("raylib");

const G = @import("./globals.zig");

pub const Tile = @This();

pub const BlockType = enum {
    none,
    stone,
    dirt,
};
pub const WallType = enum { none };
pub const CollisionType = enum { none, solid };

block: Tile.BlockType = .none,
wall: Tile.WallType = .none,
pub fn collision_type(self: *const Tile) CollisionType {
    return switch (self.block) {
        .none => .none,
        else => .solid,
    };
}

pub fn draw(self: *const Tile, x: anytype, y: anytype) void {
    const color = switch (self.block) {
        .stone => rl.Color.gray,
        .dirt => rl.Color.brown,
        else => rl.Color.black,
    };
    rl.drawRectangle(@intCast(x * G.BSIZE), @intCast(y * G.BSIZE), G.BSIZE, G.BSIZE, color);
}
