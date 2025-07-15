const G = @import("./globals.zig");
const Map = @import("Map.zig");
// should be a light source
const Light = @This();

map: *Map,
x: usize,
y: usize,
area: u8,
tiles: [][]u8,

pub fn init(map: *Map, x: usize, y: usize, area: anytype) Light {
    var light = Light{
        .x = x,
        .y = y,
        .area = @intCast(area),
        .map = map,
        .tiles = [area + 1][area + 1]u8,
    };
    light.propagate();
    return light;
}
pub fn propagate(self: Light) void {
    self.map.get_tile(self.x, self.y);
}
