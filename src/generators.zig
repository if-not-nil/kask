const G = @import("./globals.zig");
const Vec2i = G.Vec2i;
const Map = @import("Map.zig");
const Tile = @import("./Tile.zig");

const std = @import("std");
const fastnoise = @import("./fastnoise.zig");

pub fn surface(map: *Map, from: G.Vec2u, to: G.Vec2u) !void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .domain_warp_type = .simplex_reduced,
        .domain_warp_amp = 5,
        .frequency = 0.05,
    };
    for (from.x..to.x) |x| {
        const n = gen.genNoise2D(G.F32(x), 0);
        const height: usize = @intFromFloat( // scale to [7, 15]
            @floor((n + 1.0) * 0.5 * 14.0 + 7.0));
        const clamped = @min(height, to.y);
        for (to.y - clamped..to.y) |y| { // i guess its one block higher for no reason
            try map.set_tile(x, y, Tile.Dirt);
        }
        for (0..to.y - clamped - 1) |y| { // i guess its one block higher for no reason
            try map.set_tile(x, y, Tile.None);
        }
    }
}

// worms area
// - no ores
// - OMOB, OMECH: unique worms spawn which drop loot
// - OMOB: the higher the better the loot is
//
pub fn worms(map: *Map, from: G.Vec2u, to: G.Vec2u) !void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .perlin,
        .fractal_type = .ping_pong,
        .lacunarity = 1,
        .octaves = 1,
        .frequency = 0.1,
    };
    for (from.x..to.x) |x| {
        for (from.y..to.y) |y| {
            const n = gen.genNoise2D(@floatFromInt(x), @floatFromInt(y));
            if (n > 0.9) {
                try map.set_tile(x, y, Tile.Dirt);
            } else if (n > 0) {
                try map.set_tile(x, y, Tile.Stone);
            }
        }
    }
    for (from.x..to.x) |x| {
        for (from.y..to.y - 8) |y| {
            const tile = try map.get_tile(x, y);
            if (tile.block == .stone) {
                const n = gen.genNoise2D(@floatFromInt(x), @floatFromInt(y));
                if (n < 0.2) continue;

                try map.set_tile(x, y, Tile.Dirt);
                if (x == 0) continue;
                const tile_left = try map.get_tile(x - 1, y);
                if (tile_left.block == .dirt) continue;
                const max_depth = 8;
                var i: usize = 0;
                while (i < max_depth) {
                    i += 1;
                    const tile_under = try map.get_tile(x, y + i);
                    if (tile_under.block != .none) break;

                    try map.set_tile(x, y + i, Tile.Vine);

                    const vine_n = gen.genNoise2D(@floatFromInt(x), @floatFromInt(y + i));
                    if (vine_n < -0.15 and i > 1) break;
                }
            }
        }
    }
}

// the nether
// - OGEN, OTILE: filled with lava
// - OMECH, OTILE: the ground inflicts burning instantly unless you have a specific monolith
// - OGEN, OTILE: there are chests which contain rare stuff, keys are crafted with ores here
// - OMECH: mobs killed while having the monolith will drop stuff that can be used for gear at that stage
//
pub fn nether(map: *Map, from: G.Vec2u, to: G.Vec2u) !void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .domain_warp_type = .simplex_reduced,
        .domain_warp_amp = 3,
        .frequency = 0.05,
    };

    var stonebleeds = std.ArrayList(G.Vec2i).init(map.allocator);
    defer stonebleeds.deinit();

    for (from.x..to.x) |x| {
        const xf = @as(f32, @floatFromInt(x));
        // =====================
        // part 1.1: heights, 1d
        {
            // responsible for making them like go up and down
            const h_mod_raw = gen.genNoise2D(xf, 128); // Y values are arbitrary
            const h_mod: usize = @intFromFloat( // scale to [0, 15]
                @floor((h_mod_raw + 1.0) * 0.5 * 15.0));

            // responsible for the little rough edges
            const raw_top = gen.genNoise2D(xf, 0.0);
            const raw_bottom = gen.genNoise2D(xf, @floatFromInt(to.y - 1));

            const height_top: usize = @intFromFloat( // scale to [7, 15]
                @floor((raw_top + 1.0) * 0.5 * 14.0 + 7.0));
            const height_bottom: usize = @intFromFloat( // scale to [7, 15]
                @floor((raw_bottom + 1.0) * 0.5 * 14.0 + 7.0));

            const clamped_bottom = @min(height_bottom, to.y - 1);
            const clamped_top = @min(height_top, to.y - 1);
            for (0..@as(usize, 170 - h_mod + clamped_top)) |y| {
                try map.set_tile(x, y, Tile.Dirt);
            }
            for (@as(usize, 220 - h_mod - clamped_bottom)..to.y) |y| {
                try map.set_tile(x, y, Tile.Dirt);
            }
            // if (clamped_bottom < 9) {
            //     bleed_buf[bleed_buf_count] = .{
            //         .x = @intCast(x),
            //         .y = @intCast(220 - h_mod - clamped_bottom),
            //     };
            //     bleed_buf_count += 1;
            // }
            if (clamped_bottom < 9) {
                try stonebleeds.append(.{
                    .x = @intCast(x),
                    // or 220 - h_mod - clamped_bottom
                    .y = @intCast(220 + h_mod - clamped_bottom),
                });
            }
        }
        // part 1.2: caves, 2d
        for (from.y..to.y) |y| {
            const tile = try map.get_tile(x, y);
            if (tile.block == .none)
                continue;

            const yf = @as(f32, @floatFromInt(y));
            const n = gen.genNoise2D(xf, yf);
            if (n > 0.7) {
                try map.set_tile(x, y, Tile.None);
            }
        }
    }
    // part II: stonebleeds
    for (stonebleeds.items) |pos| {
        const xf = G.F32(pos.x);
        const yf = G.F32(pos.y);

        var n = gen.genNoise2D(xf, yf);
        const base = n - 0.5;

        var i: i32 = 0;

        while (i < 64) : (i += 1) {
            const sample_yf = yf + G.F32(i);
            n = gen.genNoise2D(xf, sample_yf);
            if (n < base) break;

            const world_x = pos.x + G.I32(n);
            const world_y = pos.y + i;
            if (world_y >= 0 and world_y < to.y) { // clamp to tile bounds
                try map.set_tile(world_x, world_y, Tile.Stone);
            }
        }
    }
}

pub fn caves(map: *Map, from: G.Vec2u, to: G.Vec2u) !void {
    const gen = fastnoise.Noise(f32){
        .seed = 1337,
        .noise_type = .simplex,
        .domain_warp_type = .simplex_reduced,
        .domain_warp_amp = 3,
        .frequency = 0.05,
    };
    for (from.x..to.x) |x| {
        for (from.y..to.y) |y| {
            const n = gen.genNoise2D(@floatFromInt(x), @floatFromInt(y));
            if (n > 0)
                try map.set_tile(x, y, Tile.Stone);
        }
    }
}
