const rl = @import("raylib");

const G = @import("./globals.zig");

pub const Tile = @This();

pub const BlockType = enum {
    none,
    stone,
    dirt,
    lava,
    vine,
};
pub const WallType = enum { none };
pub const CollisionType = enum { none, solid };

block: Tile.BlockType = .none,
wall: Tile.WallType = .none,

// reactive as in reactive to the an entity touching it
// only blocks should have that
reactive: bool = false,
react: ?*const fn (self: *Tile) void = null,
draw_fn: ?*const fn (x: i32, y: i32, light: u4) void = null,
color: ?rl.Color = null,
light_emit: ?u4 = 0,
DEBUG_n: ?f32 = 0, // the noise value

pub fn collision_type(self: *const Tile) CollisionType {
    return switch (self.block) {
        .none => .none,
        .vine => .none,
        else => .solid,
    };
}
//
pub fn draw(self: *const Tile, x: anytype, y: anytype, light: u4) void {
    if (self.draw_fn) |fn_ptr| {
        fn_ptr(@intCast(x), @intCast(y), light);
    } else if (self.color) |color| {
        draw_fns.generic_color(x, y, light, color);
    } else {
        draw_fns.generic_color(x, y, light, .magenta);
    }
}

const react_fns = struct {
    fn dirt(self: *Tile) void {
        self.block = .none;
    }
};

const draw_fns = struct {
    fn generic_color(x: anytype, y: anytype, light: u4, color: rl.Color) void {
        const brightness = 0.2 + 0.8 * (G.F32(light) / 16.0); // 0.2 is the lowest

        const lit = rl.Color{
            .r = @intFromFloat(G.F32(color.r) * brightness),
            .g = @intFromFloat(G.F32(color.g) * brightness),
            .b = @intFromFloat(G.F32(color.b) * brightness),
            .a = color.a,
        };

        rl.drawRectangle(@intCast(x * G.BSIZE), @intCast(y * G.BSIZE), G.BSIZE, G.BSIZE, lit);
    }
    fn vine(x: i32, y: i32, light: u4) void {
        const brightness = 0.2 + 0.8 * (G.F32(light) / 16.0); // 0.2 is the lowest
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
        rl.drawRectangle(
            @intCast(x * G.BSIZE + (G.BSIZE / 4)),
            @intCast(y * G.BSIZE),
            G.BSIZE / 2,
            G.BSIZE,
            rl.Color{
                .r = 0,
                .g = @intFromFloat(100.0 * brightness),
                .b = 0,
                .a = 255,
            },
        );
    }
    fn air(x: i32, y: i32, light: u4) void {
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
    }
};

pub const None = Tile{
    .block = .none,
    .wall = .none,
    .draw_fn = draw_fns.air,
    .light_emit = null,
    .reactive = false,
};

pub const Dirt = Tile{
    .block = .dirt,
    .color = .brown,
    .reactive = true,
    .wall = .none,
    // .react = &react_fns.dirt,
};

pub const Stone = Tile{
    .block = .stone,
    .wall = .none,
    .light_emit = 15,
    .color = .gray,
};

pub const Lava = Tile{
    .block = .lava,
    .wall = .none,
    .color = .red,
};

pub const Vine = Tile{
    .block = .vine,
    .wall = .none,
    .draw_fn = draw_fns.vine,
};
