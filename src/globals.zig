const rl = @import("raylib");

// TODO: make mutable
pub const BSIZE = 16;
pub const ScreenWidth = 1080;
pub const ScreenHeight = 720;
pub const gravity = 640.0;
pub const Vec2i = struct {
    x: i32,
    y: i32,
    const zero = Vec2i{ .x = 0, .y = 0 };
};
pub const Vec2u = struct {
    x: usize,
    y: usize,
};
pub const Vec3i = struct {
    x: i32,
    y: i32,
    z: i32,
    const zero = Vec2i{ .x = 0, .y = 0 };
};

pub fn which_chunk(x: usize, y: usize) struct { x: usize, y: usize } {
    return .{
        .x = @divTrunc(x, CHUNK_SIZE),
        .y = @divTrunc(y, CHUNK_SIZE),
    };
}

pub const NOCLIP = true;
pub const CHUNK_NUM = 16;
pub const CHUNK_SIZE = 256;
pub const WORLD_SIZE = CHUNK_NUM * CHUNK_SIZE;

// there are two places where it would be calculating it 60 times per second if not for this
pub var HalfScreenWidth = ScreenWidth / 2;
pub var HalfScreenHeight = ScreenHeight / 2;

// could break something: screen size is mutable but this isnt
pub const CameraBounds = .{
    .left = ScreenWidth / 2,
    .right = (CHUNK_NUM * CHUNK_SIZE * BSIZE) - ScreenWidth / 2,
    .top = ScreenWidth / 2,
    .bottom = (CHUNK_NUM * CHUNK_SIZE * BSIZE) - ScreenWidth / 2,
};

pub fn input_vector_1d(left: rl.KeyboardKey, right: rl.KeyboardKey) f32 {
    return F32(@intFromBool(rl.isKeyDown(right))) - F32(@intFromBool(rl.isKeyDown(left)));
}

pub fn pos_to_tile(pos: f32) f32 {
    return @floor(pos / BSIZE);
}

pub fn F32(T: anytype) f32 {
    return @floatFromInt(T);
}

pub fn I32(T: anytype) i32 {
    return @intFromFloat(T);
}

pub fn USIZE(T: anytype) usize {
    return @intCast(T);
}
