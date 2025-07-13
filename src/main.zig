const std = @import("std");
const rl = @import("raylib");
const root = @import("root.zig");

const G = @import("globals.zig");
const Map = @import("./Map.zig");
const Player = @import("./Player.zig");

pub fn main() !void {
    rl.initWindow(G.ScreenWidth, G.ScreenHeight, "chunks");
    var map = Map.init();
    var player = Player.init();

    defer rl.closeWindow();
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        player.update();
        rl.beginDrawing();
        {
            rl.clearBackground(.black);
            player.camera.begin();
            {
                map.draw(player.draw_rect);
                player.draw();
            }
            player.camera.end();
        }
        rl.endDrawing();
    }
}
