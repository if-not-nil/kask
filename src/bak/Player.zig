const rl = @import("raylib");

const G = @import("./globals.zig");

fn pos_to_tile(pos: f32) f32 {
    return @floor(pos / G.BSIZE);
}

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
            .target = rl.Vector2.zero(),
            .rotation = 0.0,
            .zoom = 1.0,
        },
        .draw_rect = rl.Rectangle.init(0, 0, 80, 60),
    };
    return p;
}

// you should've seen how it looks without the function
fn key_to_f32(key: rl.KeyboardKey) f32 {
    return @floatFromInt(@intFromBool(rl.isKeyDown(key)));
}
pub fn update(self: *Player) void {
    const dir_x: f32 =
        key_to_f32(.d) - key_to_f32(.a);
    const dir_y: f32 =
        key_to_f32(.s) - key_to_f32(.w);

    self.rect.x += dir_x * self.speed;
    self.rect.y += dir_y * self.speed;
    self.draw_rect.x = @max(0, pos_to_tile(self.rect.x) - self.draw_rect.width / 2);
    self.draw_rect.y = @max(0, pos_to_tile(self.rect.y) - self.draw_rect.height / 2);
    self.camera.target = rl.Vector2.init(self.rect.x, self.rect.y);
}
pub fn draw(self: *Player) void {
    rl.drawRectangleRec(self.rect, .red);
}
