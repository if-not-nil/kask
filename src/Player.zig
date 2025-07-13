const rl = @import("raylib");

const G = @import("globals.zig");

const Player = @This();
rect: rl.Rectangle,
camera: rl.Camera2D,
draw_rect: rl.Rectangle,
speed: f32 = 5,
pub fn init() Player {
    const p = Player{
        .rect = rl.Rectangle.init(240, -64, G.BSIZE * 2, G.BSIZE * 3),
        .camera = rl.Camera2D{
            .offset = rl.Vector2.init(G.ScreenWidth / 2, G.ScreenHeight / 2),
            .target = rl.Vector2.init(0, 0),
            .rotation = 0.0,
            .zoom = 1.0,
        },
        .draw_rect = rl.Rectangle.init(0, 0, 80, 60),
    };
    return p;
}
pub fn update(self: *Player) void {
    const direction: @Vector(2, f32) = .{
        G.F32(@intFromBool(rl.isKeyDown(.d))) - G.F32(@intFromBool(rl.isKeyDown(.a))),
        G.F32(@intFromBool(rl.isKeyDown(.s))) - G.F32(@intFromBool(rl.isKeyDown(.w))),
    };
    self.rect.x += direction[0] * self.speed;
    self.rect.y += direction[1] * self.speed;
    self.draw_rect.x = @max(0, G.pos_to_tile(self.rect.x) - self.draw_rect.width / 2);
    self.draw_rect.y = @max(0, G.pos_to_tile(self.rect.y) - self.draw_rect.height / 2);
    self.camera.target = rl.Vector2.init(self.rect.x, self.rect.y);
}
pub fn draw(self: *Player) void {
    rl.drawRectangleRec(self.rect, .red);
}
