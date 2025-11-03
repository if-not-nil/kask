const std = @import("std");

const rl = @import("raylib");

const Chunk = @import("./Chunk.zig");
const Tile = @import("./Tile.zig");
const G = @import("globals.zig");
const Vec2i = G.Vec2i;

const generators = @import("./generators.zig");
pub const Map = @This();

allocator: std.mem.Allocator,
chunks: *[G.CHUNK_NUM][G.CHUNK_NUM]Chunk,
DEBUG_last_light_recalc: ?G.Rect = null,
light_recalc_queued: bool = false,

pub fn init(allocator: std.mem.Allocator) !Map {
    var map = Map{
        .chunks = try allocator.create([G.CHUNK_NUM][G.CHUNK_NUM]Chunk),
        .allocator = allocator,
    };

    for (0..G.CHUNK_NUM) |x| {
        for (0..G.CHUNK_NUM) |y| {
            map.chunks[x][y] = Chunk.init(&map, x, y);
        }
    }

    try generators.nether(
        &map,
        .{ .x = 0, .y = 0 },
        .{ .x = G.WORLD_SIZE, .y = G.CHUNK_SIZE },
    );
    try generators.worms(
        &map,
        .{ .x = 0, .y = G.CHUNK_SIZE },
        .{ .x = G.CHUNK_SIZE * 2, .y = G.WORLD_SIZE },
    );
    try generators.caves(
        &map,
        .{ .x = G.CHUNK_SIZE * 2, .y = G.CHUNK_SIZE },
        .{ .x = G.CHUNK_SIZE * 4, .y = G.CHUNK_SIZE * 3 },
    );
    return map;
}

pub fn deinit(self: *Map) void {
    for (0..G.CHUNK_NUM) |x| {
        for (0..G.CHUNK_NUM) |y| {
            self.chunks[x][y].deinit();
        }
    }
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

    try self.chunks[G.USIZE(chunk_x)][G.USIZE(chunk_y)].set_tile(G.USIZE(local_x), G.USIZE(local_y), tile);
    // .tiles[G.USIZE(local_x)][G.USIZE(local_y)] = tile;
}

pub fn set_tile_client(self: *Map, x: anytype, y: anytype, tile: Tile) !void {
    try self.set_tile(x, y, tile);
    try self.recalc_light(@intCast(x - 15), @intCast(y - 15), 33, 33);
    // try self.set_light(@intCast(x), @intCast(y), 0);
    // const sx: usize = @intCast(x - 2);
    // const sy: usize = @intCast(y - 2);
    // try self.recalc_light(sx - 32, sy - 32, 65, 65);
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

pub fn reset_light(self: *Map, x_start: usize, y_start: usize, width: usize, height: usize) !void {
    for (x_start..x_start + width) |x| {
        for (y_start..y_start + height) |y| {
            try self.set_light(x, y, 0);
        }
    }
}

pub fn recalc_light(self: *Map, x_start: usize, y_start: usize, width: usize, height: usize) !void {
    try self.reset_light(x_start, y_start, width, height);
    var queue = try std.ArrayList(G.Vec3i).initCapacity(self.allocator, 1);
    defer queue.deinit(self.allocator);
    for (x_start..x_start + width) |x| {
        for (y_start..y_start + height) |y| {
            const tile = try self.get_tile(x, y);
            if (tile.light_emit) |emit| {
                try self.set_light(x, y, emit);
                try queue.append(self.allocator, .{ .x = @intCast(x), .y = @intCast(y), .z = emit });
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
            try queue.append(self.allocator, .{
                .x = nx,
                .y = ny,
                .z = next_level,
            });
        }
    }
    if (comptime G.DEBUG_last_recalc_square) {
        var r = G.Rect{ .x = x_start, .y = y_start, .w = width, .h = height };
        self.DEBUG_last_light_recalc = r.multiply(G.BSIZE);
    }
}

const draw_w = @divTrunc(G.ScreenWidth, G.BSIZE) + 1;
const draw_h = @divTrunc(G.ScreenHeight, G.BSIZE) + 1;

pub fn draw(self: *Map, pos: rl.Vector2) !void {
    const x_u: usize = @intFromFloat(pos.x);
    const y_u: usize = @intFromFloat(pos.y);

    const x_start = x_u / G.BSIZE;
    const y_start = y_u / G.BSIZE;

    if (self.light_recalc_queued) {
        try self.recalc_light(
            @max(0, x_start - 15),
            @max(0, y_start - 15),
            @min(G.WORLD_SIZE, draw_w + 30),
            @min(G.WORLD_SIZE, draw_h + 30),
        );
        std.debug.print("did light\n", .{});
        self.light_recalc_queued = false;
    }

    for (x_start..@min(x_start + draw_w, G.CHUNK_SIZE * G.CHUNK_NUM)) |x| {
        for (y_start..@min(y_start + draw_h, G.CHUNK_SIZE * G.CHUNK_NUM)) |y| {
            var tile = try self.get_tile_with_light(x, y);
            tile.t.draw(x, y, tile.l);
        }
    }
    if (comptime G.DEBUG_LIGHTMAP) {
        const c = G.which_chunk(x_start, y_start);
        self.chunks[c.x][c.y].DEBUG_lightmap();
    }
    if (G.DEBUG_last_recalc_square)
        self.DEBUG_last_light_recalc.?.draw(rl.colorAlpha(.red, 0.5));
}
