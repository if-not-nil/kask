const std = @import("std");

test "map init/deinit" {
    const Map = @import("./Map.zig");
    var map = try Map.init(std.testing.allocator);
    defer map.deinit();
}
