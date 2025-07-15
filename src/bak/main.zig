const std = @import("std");

const rl = @import("raylib");
const rvec2 = rl.Vector2.init;
const Player = @import("./Player.zig");

const World = @import("./World.zig");
const root = @import("root.zig");
const G = @import("./globals.zig");

pub fn main() !void {
    rl.initWindow(G.ScreenWidth, G.ScreenHeight, "chunks");

    var world = World.init();
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
                world.draw();
                // try map.draw(
                //     @intFromFloat(@max(0, player.draw_rect.x)),
                //     @intFromFloat(@max(0, player.draw_rect.y)),
                //     @intFromFloat(@max(0, player.draw_rect.width)),
                //     @intFromFloat(@max(0, player.draw_rect.height)),
                // );
                player.draw();
            }
            player.camera.end();
        }
        rl.endDrawing();
    }
}
