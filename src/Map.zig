const std = @import("std");

const rl = @import("raylib");

const Chunk = @import("./Chunk.zig");
const Tile = @import("./Tile.zig");
const G = @import("globals.zig");

const generators = @import("./generators.zig");
pub const Map = @This();

allocator: std.mem.Allocator,
chunks: *[G.CHUNK_NUM][G.CHUNK_NUM]Chunk,
initial_light_chunks: [G.CHUNK_NUM][G.CHUNK_NUM]bool = @splat(@splat(false)),
initial_lighting_done: bool = false,

pub fn init(allocator: std.mem.Allocator) !Map {
    var chunks = try allocator.create([G.CHUNK_NUM][G.CHUNK_NUM]Chunk);

    for (0..G.CHUNK_NUM) |x| {
        for (0..G.CHUNK_NUM) |y| {
            chunks[x][y] = Chunk.init(x, y);
        }
    }

    // for (0..G.CHUNK_NUM) |x| {
    //     for (2..G.CHUNK_NUM) |y| {
    //         chunks[x][y].generate_stone();
    //     }
    // }
    var map = Map{
        .chunks = chunks,
        .allocator = allocator,
    };

    try generators.caves(
        &map,
        .{ .x = 0, .y = 0 },
        .{ .x = G.WORLD_SIZE, .y = G.CHUNK_SIZE },
    );
    try generators.worms(
        &map,
        .{ .x = 0, .y = G.CHUNK_SIZE },
        .{ .x = G.CHUNK_SIZE * 2, .y = G.WORLD_SIZE },
    );
    return map;
}

pub fn deinit(self: *Map) void {
    self.allocator.destroy(self.chunks);
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

pub fn set_light(self: *Map, x: usize, y: usize, level: u4) !void {
    const chunk_x = x / G.CHUNK_SIZE;
    const chunk_y = y / G.CHUNK_SIZE;

    const local_x = x % G.CHUNK_SIZE;
    const local_y = y % G.CHUNK_SIZE;
    if (chunk_x >= G.CHUNK_NUM or chunk_y >= G.CHUNK_NUM) {
        return error.OutOfBounds;
    }
    self.chunks[chunk_x][chunk_y].lightmap[local_x][local_y] = level;
}
pub fn get_tile_with_light(self: *Map, x: usize, y: usize) !struct { t: *Tile, l: u4 } {
    const chunk_x = x / G.CHUNK_SIZE;
    const chunk_y = y / G.CHUNK_SIZE;

    const local_x = x % G.CHUNK_SIZE;
    const local_y = y % G.CHUNK_SIZE;

    if (chunk_x >= G.CHUNK_NUM or chunk_y >= G.CHUNK_NUM) {
        return error.OutOfBounds;
    }

    return .{
        .t = &self.chunks[chunk_x][chunk_y].tiles[local_x][local_y],
        .l = self.chunks[chunk_x][chunk_y].lightmap[local_x][local_y],
    };
}

pub fn set_tile(self: *Map, x: anytype, y: anytype, tile: Tile) !void {
    const chunk_x = @divTrunc(x, G.CHUNK_SIZE);
    const chunk_y = @divTrunc(y, G.CHUNK_SIZE);

    const local_x = @mod(x, G.CHUNK_SIZE);
    const local_y = @mod(y, G.CHUNK_SIZE);

    if (chunk_x < 0 or chunk_y < 0 or chunk_x >= G.CHUNK_NUM or chunk_y >= G.CHUNK_NUM) {
        return error.OutOfBoundsBlockBreak;
    }

    self.chunks[G.USIZE(chunk_x)][G.USIZE(chunk_y)]
        .tiles[G.USIZE(local_x)][G.USIZE(local_y)] = tile;
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

pub fn recalc_light(self: *Map, x_start: usize, y_start: usize, width: usize, height: usize) !void {
    var queue = std.ArrayList(G.Vec3i).init(self.allocator);
    defer queue.deinit();
    for (x_start..x_start + width) |x| {
        for (y_start..y_start + height) |y| {
            const tile = try self.get_tile(x, y);
            if (tile.light_emit) |emit| {
                try self.set_light(x, y, emit);
                try queue.append(.{ .x = @intCast(x), .y = @intCast(y), .z = emit });
            }
        }
    }
    while (queue.pop()) |node| {
        if (node.z == 0) continue;
        const dirs = [_][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };
        for (dirs) |d| {
            const nx = node.x + d[0];
            const ny = node.y + d[1];
            if (nx < 0 or ny < 0) continue;
            const nx_u: usize = @intCast(nx);
            const ny_u: usize = @intCast(ny);
            const nt = try self.get_tile_with_light(nx_u, ny_u);
            if (nt.l >= node.z - 1) continue;

            var next_level = node.z - 1;
            if (nt.t.collision_type() != .none) blk: {
                if (next_level == 1) break :blk;
                next_level = @divTrunc(next_level, 2);
            }
            try self.set_light(nx_u, ny_u, @intCast(next_level));
            try queue.append(.{
                .x = nx,
                .y = ny,
                .z = next_level,
            });
        }
    }
}

const draw_w = @divTrunc(G.ScreenWidth, G.BSIZE) + 1;
const draw_h = @divTrunc(G.ScreenHeight, G.BSIZE) + 1;

pub fn draw(self: *Map, pos: rl.Vector2) !void {
    const x_u: usize = @intFromFloat(pos.x);
    const y_u: usize = @intFromFloat(pos.y);

    const x_start = x_u / G.BSIZE;
    const y_start = y_u / G.BSIZE;

    // TODO: make it not like this
    if (!self.initial_lighting_done) {
        const c = G.which_chunk(x_start, y_start);
        if (!self.initial_light_chunks[c.x][c.y]) {
            try self.recalc_light(c.x * G.CHUNK_SIZE, c.y * G.CHUNK_SIZE, 256, 256);
            std.debug.print("did chunk {}\n", .{c});

            // this is horrible!
            self.initial_light_chunks[@intCast(c.x)][@intCast(c.y)] = true;

            var all_done = true;

            for (self.initial_light_chunks) |chunk_row| {
                for (chunk_row) |is_done| {
                    if (!is_done) {
                        all_done = false;
                        break;
                    }
                }
                if (!all_done) break;
            }

            if (all_done) {
                self.initial_lighting_done = true;
                std.debug.print("all chunks lit up!\n", .{});
            }
        }
    }

    for (x_start..@min(x_start + draw_w, G.CHUNK_SIZE * G.CHUNK_NUM)) |x| {
        for (y_start..@min(y_start + draw_h, G.CHUNK_SIZE * G.CHUNK_NUM)) |y| {
            var tile = try self.get_tile_with_light(x, y);
            tile.t.draw(x, y, tile.l);
        }
    }
}
