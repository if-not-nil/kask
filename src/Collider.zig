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

    s.left = s.map.check_collisions(left_x, (top_y + bottom_y) / 2);
    s.right = s.map.check_collisions(right_x, (top_y + bottom_y) / 2);
    s.top = s.map.check_collisions(s.x, top_y);
    s.bottom = s.map.check_collisions(s.x, bottom_y);

    std.debug.print("L:{} R:{} T:{} B:{}\n", .{
        s.left,
        s.right,
        s.top,
        s.bottom,
    });
}
