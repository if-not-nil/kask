pub const BSIZE = 16;
pub const ScreenWidth = 1080;
pub const ScreenHeight = 720;

pub fn pos_to_tile(pos: f32) f32 {
    return @floor(pos / BSIZE);
}

pub fn F32(T: anytype) f32 {
    return @floatFromInt(T);
}

pub fn I32(T: anytype) i32 {
    return @intFromFloat(T);
}
