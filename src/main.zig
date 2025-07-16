const std = @import("std");

const rl = @import("raylib");

const Map = @import("./Map.zig");
const Player = @import("./Player.zig");
const G = @import("globals.zig");
const root = @import("root.zig");

pub fn main() !void {
    rl.initWindow(G.ScreenWidth, G.ScreenHeight, "chunks");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.print("allocator deinit check: {}\n", .{gpa.deinit()});

    const allocator = gpa.allocator();

    var map = try Map.init(allocator);
    // std.debug.print("{}\n", .{map_ptr.get_tile(0, 20)});
    defer map.deinit();

    var player = Player.init(&map);

    defer rl.closeWindow();
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        try player.update();
        rl.beginDrawing();
        {
            rl.clearBackground(.black);
            player.camera.begin();
            {
                try map.draw(player.draw_pos);
                player.draw();
            }
            player.camera.end();
        }
        rl.drawFPS(20, 20);
        rl.drawText(rl.textFormat("%08f, %08f", .{ @floor(player.camera.target.x), @floor(player.camera.target.y) }), 20, 40, 20, .green);
        rl.drawText(rl.textFormat("%08f, %08f", .{ @floor(player.x), @floor(player.y) }), 20, 60, 20, .green);
        rl.endDrawing();
    }
}
