const std = @import("std");

const rl = @import("raylib");

const Chunk = @import("./Chunk.zig");
const Tile = @import("./Tile.zig");
const G = @import("globals.zig");

pub const Map = @This();

// const LightTuple = struct { G.Vec2i, u8 };

allocator: std.mem.Allocator,
chunks: *[G.CHUNK_NUM][G.CHUNK_NUM]Chunk,
// lightmap: std.AutoHashMap(G.Vec2i, u8),

pub fn init(allocator: std.mem.Allocator) !Map {
    var chunks = try allocator.create([G.CHUNK_NUM][G.CHUNK_NUM]Chunk);

    // for (0..G.CHUNK_NUM) |x| {
    //     chunks[x][0] = Chunk.init(x, 0);
    //     chunks[x][0].generate_surface();
    // }
    for (0..G.CHUNK_NUM) |x| {
        chunks[x][0] = Chunk.init(x, 0);
        chunks[x][0].generate_dirt();
    }
    for (0..G.CHUNK_NUM) |x| {
        for (1..G.CHUNK_NUM) |y| {
            chunks[x][y] = Chunk.init(x, y);
            chunks[x][y].generate_stone();
        }
    }

    // var lightmap = std.AutoHashMap(G.Vec2i, u8).init(allocator);
    // try lightmap.put(G.Vec2i{ .x = 600, .y = 2840 }, 16);

    return Map{
        .chunks = chunks,
        .allocator = allocator,
        // .lightmap = lightmap,
    };
}

pub fn deinit(self: *Map) void {
    self.allocator.destroy(self.chunks);
    // {
    //     var it = self.lightmap.iterator();
    //     while (it.next()) |kv| {
    //         std.debug.print("kvv {}\n", .{kv});
    //     }
    // }
    // self.lightmap.deinit();
}

pub fn get_tile(self: *Map, x: usize, y: usize) !*Tile {
    const chunk_x = x / G.CHUNK_SIZE;
    const chunk_y = y / G.CHUNK_SIZE;

    const local_x = x % G.CHUNK_SIZE;
    const local_y = y % G.CHUNK_SIZE;

    if (chunk_x >= G.CHUNK_NUM or chunk_y >= G.CHUNK_NUM) {
        return error.OutOfBounds;
    }

    return &self.chunks[chunk_x][chunk_y].tiles[local_x][local_y];
}

pub fn break_block(self: *Map, x: anytype, y: anytype) !void {
    const chunk_x = @divTrunc(x, G.CHUNK_SIZE);
    const chunk_y = @divTrunc(y, G.CHUNK_SIZE);

    const local_x = @mod(x, G.CHUNK_SIZE);
    const local_y = @mod(y, G.CHUNK_SIZE);

    if (chunk_x < 0 or chunk_y < 0 or chunk_x >= G.CHUNK_NUM or chunk_y >= G.CHUNK_NUM) {
        return error.OutOfBoundsBlockBreak;
    }

    self.chunks[G.USIZE(chunk_x)][G.USIZE(chunk_y)]
        .tiles[G.USIZE(local_x)][G.USIZE(local_y)].block = .none;
}

pub fn check_collisions(self: *Map, x: f32, y: f32) Tile.CollisionType {
    const t_x: usize = @intFromFloat(x / G.BSIZE);
    const t_y: usize = @intFromFloat(y / G.BSIZE);
    const t = self.get_tile(t_x, t_y) catch @panic("checked OOB");
    // std.debug.print("{}, {}, {}\n", .{ x, y, t });
    // std.debug.print("{}, {}, {}\n", .{ t_x, t_y, t });
    // if (t.reactive)
    //     t.react();

    return t.collision_type();
}

// fn calculate_lightmap(x_start: usize, x_end: usize, y_start: usize, y_end: usize) [][]u8 {
//     const size_x = x_end - x_start;
//     const size_y = y_end - y_start;
//     const map = [size_x][size_y]u8;
//     for (0..size_x) |x| {
//         for (0..size_y) |y| {
//             map[x][y] = 0;
//         }
//     }
//     return map;
// }

const draw_w = @divTrunc(G.ScreenWidth, G.BSIZE) + 1;
const draw_h = @divTrunc(G.ScreenHeight, G.BSIZE) + 1;

pub fn draw(self: *Map, pos: rl.Vector2) !void {
    const x_u: usize = @intFromFloat(pos.x);
    const y_u: usize = @intFromFloat(pos.y);

    const x_start = x_u / G.BSIZE;
    const y_start = y_u / G.BSIZE;

    var lightmap = try self.allocator.alloc(u4, draw_w * draw_h);
    @memset(lightmap, 0);
    var queue = std.ArrayList(G.Vec3i).init(self.allocator);
    defer queue.deinit();
    defer self.allocator.free(lightmap);

    for (x_start..@min(x_start + draw_w, G.CHUNK_SIZE * G.CHUNK_NUM)) |x| {
        for (y_start..@min(y_start + draw_h, G.CHUNK_SIZE * G.CHUNK_NUM)) |y| {
            const tile = try self.get_tile(x, y);
            if (tile.light_emit) |emit| {
                const lx = x - x_start;
                const ly = y - y_start;
                const idx = ly * draw_w + lx;
                lightmap[idx] = emit;
                try queue.append(.{ .x = @intCast(x), .y = @intCast(y), .z = emit });
            }
        }
    }

    while (queue.pop()) |node| {
        const dirs = [_][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
        for (dirs) |d| {
            const nx = node.x + d[0];
            const ny = node.y + d[1];

            const lx = nx - @as(i32, @intCast(x_start));
            const ly = ny - @as(i32, @intCast(y_start));

            if (lx < 0 or ly < 0) continue;
            if (lx >= draw_w or ly >= draw_h) continue;

            const i: usize = @intCast(ly * draw_w + lx);
            if (node.z == 0) continue;
            const next_level = node.z - 1;

            if (lightmap[i] >= next_level) continue;

            lightmap[i] = @intCast(next_level);
            try queue.append(.{ .x = nx, .y = ny, .z = next_level });
        }
    }

    for (x_start..@min(x_start + draw_w, G.CHUNK_SIZE * G.CHUNK_NUM)) |x| {
        for (y_start..@min(y_start + draw_h, G.CHUNK_SIZE * G.CHUNK_NUM)) |y| {
            const lx = x - x_start;
            const ly = y - y_start;
            const idx = ly * draw_w + lx;

            var tile = try self.get_tile(x, y);
            tile.draw(x, y, lightmap[idx]);
        }
    }
}
const LIGHT_AREA = 8;

// pub fn propagate_light(self: *Map, x: usize, y: usize) void {
//     _ = self;
//     return [_]light_pos{.{ .level = 16, .pos = .{ .x = x, .y = y } }};
// }
