const Map = @import("Map.zig");
const Tile = @import("Tile.zig");
const Collider = @This();

const rl = @import("raylib");

const std = @import("std");
map: *Map,
left: Tile.CollisionType = .none,
right: Tile.CollisionType = .none,
bottom: Tile.CollisionType = .none,
top: Tile.CollisionType = .none,
x: f32,
y: f32,
w: f32,

h: f32,
rect: rl.Rectangle = rl.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 },

pub fn check_collisions(s: *Collider) void {
    s.rect = rl.Rectangle{
        .x = s.x - s.w / 2,
        .y = s.y - s.h,
        .width = s.w,
        .height = s.h,
    };

    const left_x = s.x - s.w / 2;
    const right_x = s.x + s.w / 2;
    const bottom_y = s.y;
    const top_y = s.y - s.h;

    const step = 16.0;

    var left: Tile.CollisionType = .none;
    var right: Tile.CollisionType = .none;
    var top: Tile.CollisionType = .none;
    var bottom: Tile.CollisionType = .none;

    var offset: f32 = 0.0;
    while (offset < s.h) : (offset += step) {
        const sample_y = top_y + offset;
        if (s.map.check_collisions(left_x, sample_y) == .solid) left = .solid;
        if (s.map.check_collisions(right_x, sample_y) == .solid) right = .solid;
    }

    offset = 0.0;
    while (offset < s.w) : (offset += step) {
        const sample_x = left_x + offset;
        if (s.map.check_collisions(sample_x, top_y) == .solid) top = .solid;
        if (s.map.check_collisions(sample_x, bottom_y) == .solid) bottom = .solid;
    }

    s.left = left;
    s.right = right;
    s.top = top;
    s.bottom = bottom;
}
