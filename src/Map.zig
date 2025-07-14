const std = @import("std");

const rl = @import("raylib");

const Chunk = @import("./Chunk.zig");
const Tile = @import("./Tile.zig");
const G = @import("globals.zig");

const CHUNK_NUM = 16;

pub const Map = @This();
chunks: [CHUNK_NUM][CHUNK_NUM]Chunk,

pub fn init(allocator: std.mem.Allocator) !*Map {
    var map_ptr = try allocator.create(Map);

    map_ptr.* = Map{
        .chunks = undefined,
    };

    for (0..CHUNK_NUM) |x| {
        map_ptr.chunks[x][0] = Chunk.init(x, 0);
        map_ptr.chunks[x][0].generate_dirt();
    }
    for (0..CHUNK_NUM) |x| {
        for (1..CHUNK_NUM) |y| {
            map_ptr.chunks[x][y] = Chunk.init(x, y);
            map_ptr.chunks[x][y].generate_stone();
        }
    }

    return map_ptr;
}

pub fn get_tile(self: *Map, x: usize, y: usize) Tile {
    const chunk_x = x / 256;
    const chunk_y = y / 256;

    const local_x = x % 256;
    const local_y = y % 256;

    if (chunk_x >= CHUNK_NUM or chunk_y >= CHUNK_NUM) {
        return Tile{ .block = .none };
    }

    return self.chunks[chunk_x][chunk_y].tiles[local_x][local_y];
}

pub fn check_collisions(self: *Map, x: f32, y: f32) Tile.CollisionType {
    const t_x: usize = @intFromFloat(x / G.BSIZE);
    const t_y: usize = @intFromFloat(y / G.BSIZE);
    const t = self.get_tile(t_x, t_y);
    std.debug.print("{}, {}, {}\n", .{ x, y, t });
    std.debug.print("{}, {}, {}\n", .{ t_x, t_y, t });
    return t.collision_type();
}

pub fn draw(self: *Map, area: rl.Rectangle) void {
    const x_start_tile = @as(usize, @intFromFloat(area.x));
    const y_start_tile = @as(usize, @intFromFloat(area.y));

    const x_end_tile = x_start_tile + @as(usize, @intFromFloat(area.width)) + G.BSIZE;
    const y_end_tile = y_start_tile + @as(usize, @intFromFloat(area.height)) + G.BSIZE;
    // std.debug.print("{}\n", .{area});
    // std.debug.print("{}, {}, {}, {}\n", .{ x_start_tile, y_start_tile, x_end_tile, y_end_tile });

    for (x_start_tile..@min(x_end_tile, 256 * CHUNK_NUM)) |x| {
        for (y_start_tile..@min(y_end_tile, 256 * CHUNK_NUM)) |y| {
            const tile = self.get_tile(x, y);
            tile.draw(x, y);
        }
    }
}
