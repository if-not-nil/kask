const std = @import("std");

const rl = @import("raylib");

const Map = @import("./Map.zig");
const Player = @import("./Player.zig");
const G = @import("globals.zig");
const root = @import("root.zig");

pub fn main() !void {
    rl.initWindow(G.ScreenWidth, G.ScreenHeight, "chunks");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var map_ptr = try Map.init(allocator);
    std.debug.print("{}\n", .{map_ptr.get_tile(0, 20)});
    defer allocator.destroy(map_ptr);

    var player = Player.init(map_ptr);

    defer rl.closeWindow();
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        player.update();
        rl.beginDrawing();
        {
            rl.clearBackground(.black);
            player.camera.begin();
            {
                map_ptr.draw(player.draw_rect);
                player.draw();
            }
            player.camera.end();
        }
        rl.drawFPS(20, 20);
        rl.endDrawing();
    }
}
