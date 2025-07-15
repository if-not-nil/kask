const std = @import("std");

const rl = @import("raylib");

const Chunk = @import("./Chunk.zig");
const Tile = @import("./Tile.zig");
const G = @import("globals.zig");

pub const Map = @This();

const LightTuple = struct { G.Vec2i, u8 };

allocator: std.mem.Allocator,
chunks: *[G.CHUNK_NUM][G.CHUNK_NUM]Chunk,
lightmap: *std.ArrayList(LightTuple),

pub fn init(allocator: std.mem.Allocator) !Map {
    var chunks = try allocator.create([G.CHUNK_NUM][G.CHUNK_NUM]Chunk);

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

    var lightmap = std.ArrayList(LightTuple).init(allocator);

    return Map{
        .chunks = chunks,
        .allocator = allocator,
        .lightmap = &lightmap,
    };
}

pub fn deinit(self: *Map) void {
    self.allocator.destroy(self.chunks);
    self.lightmap.deinit();
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

pub fn draw(self: *Map, pos: rl.Vector2) !void {
    const x_u: usize = @intFromFloat(pos.x);
    const y_u: usize = @intFromFloat(pos.y);

    const x_start_tile = x_u / G.BSIZE;
    const y_start_tile = y_u / G.BSIZE;

    const x_end_tile = (x_start_tile + @divTrunc(G.USIZE(rl.getScreenWidth()), G.BSIZE) + 1);
    const y_end_tile = (y_start_tile + @divTrunc(G.USIZE(rl.getScreenHeight()), G.BSIZE) + 1);

    for (x_start_tile..@min(x_end_tile, G.CHUNK_SIZE * G.CHUNK_NUM)) |x| {
        for (y_start_tile..@min(y_end_tile, G.CHUNK_SIZE * G.CHUNK_NUM)) |y| {
            var tile = try self.get_tile(x, y);
            tile.draw(x, y);
        }
    }
}
const LIGHT_AREA = 8;

// pub fn propagate_light(self: *Map, x: usize, y: usize) void {
//     _ = self;
//     return [_]light_pos{.{ .level = 16, .pos = .{ .x = x, .y = y } }};
// }
