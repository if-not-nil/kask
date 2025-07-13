const std = @import("std");
const rl = @import("raylib");
const root = @import("root.zig");
const rvec2 = rl.Vector2.init;

const BSIZE = 16;

pub fn pos_to_tile(pos: f32) f32 {
    return @floor(pos / BSIZE);
}

pub const Map = struct {
    data: [256][256]u32,
    fn init() Map {
        var map = Map{ .data = undefined };
        for (0..256) |x| {
            for (0..256) |y| {
                map.data[x][y] = 1;
            }
        }
        return map;
    }
    // x/y params are for the box of drawn tiles
    fn draw(self: *Map, area: rl.Rectangle) void {
        const x_start = @as(usize, @intFromFloat(area.x));
        const y_start = @as(usize, @intFromFloat(area.y));
        const x_end = x_start + @as(usize, @intFromFloat(area.width));
        const y_end = y_start + @as(usize, @intFromFloat(area.height));

        for (x_start..@min(x_end, self.data.len)) |x| {
            for (y_start..@min(y_end, self.data.len)) |y| {
                rl.drawRectangle(
                    @as(i32, @intCast(x)) * BSIZE,
                    @as(i32, @intCast(y)) * BSIZE,
                    BSIZE,
                    BSIZE,
                    rl.Color.init(@intCast(x), @intCast(y), @intCast(x), 255),
                );
            }
        }
    }
};

pub fn F32(T: anytype) f32 {
    return @floatFromInt(T);
}

const Player = struct {
    rect: rl.Rectangle,
    camera: rl.Camera2D,
    draw_rect: rl.Rectangle,
    speed: f32 = 5,
    fn init() Player {
        const p = Player{
            .rect = rl.Rectangle.init(240, -64, BSIZE * 2, BSIZE * 3),
            .camera = rl.Camera2D{
                .offset = rvec2(ScreenWidth / 2, ScreenHeight / 2),
                .target = rvec2(0, 0),
                .rotation = 0.0,
                .zoom = 1.0,
            },
            .draw_rect = rl.Rectangle.init(0, 0, 80, 60),
        };
        return p;
    }
    pub fn update(self: *Player) void {
        const direction: @Vector(2, f32) = .{
            F32(@intFromBool(rl.isKeyDown(.d))) - F32(@intFromBool(rl.isKeyDown(.a))),
            F32(@intFromBool(rl.isKeyDown(.s))) - F32(@intFromBool(rl.isKeyDown(.w))),
        };
        self.rect.x += direction[0] * self.speed;
        self.rect.y += direction[1] * self.speed;
        self.draw_rect.x = @max(0, pos_to_tile(self.rect.x) - self.draw_rect.width / 2);
        self.draw_rect.y = @max(0, pos_to_tile(self.rect.y) - self.draw_rect.height / 2);
        self.camera.target = rvec2(self.rect.x, self.rect.y);
    }
    pub fn draw(self: *Player) void {
        rl.drawRectangleRec(self.rect, .red);
    }
};

const ScreenWidth = 1080;
const ScreenHeight = 720;

pub fn main() !void {
    rl.initWindow(ScreenWidth, ScreenHeight, "chunks");
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
