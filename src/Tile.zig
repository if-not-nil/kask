const rl = @import("raylib");

const G = @import("./globals.zig");

pub const Tile = @This();

pub const BlockType = enum {
    none,
    stone,
    dirt,
    lava,
};
pub const WallType = enum { none };
pub const CollisionType = enum { none, solid };

block: Tile.BlockType = .none,
wall: Tile.WallType = .none,

// reactive as in reactive to the an entity touching it
// only blocks should have that
reactive: bool = true,
react: ?*const fn (self: *Tile) void = null,
light_emit: ?u4 = 0,

pub fn collision_type(self: *const Tile) CollisionType {
    return switch (self.block) {
        .none => .none,
        else => .solid,
    };
}

pub fn draw(self: *const Tile, x: anytype, y: anytype, light: u4) void {
    const color: rl.Color = switch (self.block) {
        .stone => .gray,
        .dirt => .brown,
        .lava => .red,
        .none => {
            rl.drawRectangle(
                @intCast(x * G.BSIZE),
                @intCast(y * G.BSIZE),
                G.BSIZE,
                G.BSIZE,
                rl.Color{
                    .a = 255,
                    .r = @as(u8, @intCast(light)) * 2,
                    .g = @as(u8, @intCast(light)) * 2,
                    .b = @as(u8, @intCast(light)) * 2,
                },
            );
            return;
        },
    };
    const brightness = 0.2 + 0.8 * (G.F32(light) / 16.0); // 0.2 is the lowest

    const lit = rl.Color{
        .r = @intFromFloat(G.F32(color.r) * brightness),
        .g = @intFromFloat(G.F32(color.g) * brightness),
        .b = @intFromFloat(G.F32(color.b) * brightness),
        .a = color.a,
    };

    rl.drawRectangle(@intCast(x * G.BSIZE), @intCast(y * G.BSIZE), G.BSIZE, G.BSIZE, lit);
}

const react_fns = struct {
    fn dirt(self: *Tile) void {
        self.block = .none;
    }
};

pub const None = Tile{
    .block = .none,
    .reactive = false,
    .wall = .none,
};

pub const Dirt = Tile{
    .block = .dirt,
    .reactive = true,
    .wall = .none,
    .react = &react_fns.dirt,
};

pub const Stone = Tile{
    .block = .stone,
    .reactive = false,
    .wall = .none,
    .light_emit = 15,
};
