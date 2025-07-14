// ideally, all client side logic should be in this file for the future
const rl = @import("raylib");

const std = @import("std");
const Map = @import("./Map.zig");
const G = @import("globals.zig");
const Collider = @import("./Collider.zig");
const Vec2 = rl.Vector2;

const Cursor = struct {
    pos: Vec2 = .{ .x = 0, .y = 0 },

    fn draw(self: *Cursor, cam: *rl.Camera2D) void {
        self.pos = rl.getScreenToWorld2D(rl.getMousePosition(), cam.*);

        rl.drawRectangle(
            G.I32(self.pos.x / 16) * 16,
            G.I32(self.pos.y / 16) * 16,
            16,
            16,
            rl.Color.init(255, 255, 255, 128),
        );
    }
};

const Player = @This();
w: f32,
h: f32,
x: f32,
y: f32,
velocity: Vec2 = Vec2{ .x = 0, .y = 0 },
camera: rl.Camera2D,
draw_rect: rl.Rectangle,
collider: Collider,
cursor: Cursor,

speed: f32 = 0.05,
decceleration: f32 = 2,
max_speed: f32 = 1.0,

const MAX_SPEED = 11.0 * G.BSIZE;
const TIME_TO_MAX = 0.5; // seconds
const TIME_TO_STOP = 0.15; // seconds

const ACCEL = MAX_SPEED / TIME_TO_MAX;
const DECCEL = MAX_SPEED / TIME_TO_STOP;

// horizontal input
fn apply_movement(self: *Player, input: f32, delta_time: f32) void {
    if (input != 0) {
        self.velocity.x += input * ACCEL * delta_time;
    } else if (self.velocity.x != 0) {
        const sign = self.velocity.x / @abs(self.velocity.x);
        self.velocity.x -= sign * DECCEL * delta_time;

        if (@abs(self.velocity.x) < DECCEL * delta_time)
            self.velocity.x = 0;
    }

    self.velocity.x = std.math.clamp(self.velocity.x, -MAX_SPEED, MAX_SPEED);

    if (self.collider.left == .solid or self.collider.right == .solid) {
        self.velocity.x = 0;
    }

    self.x += self.velocity.x * delta_time;
    self.y += self.velocity.y * delta_time;
}

pub fn update(self: *Player) void {
    const delta_time = rl.getFrameTime();
    const input = G.F32(@intFromBool(rl.isKeyDown(.d))) - G.F32(@intFromBool(rl.isKeyDown(.a)));

    self.collider.check_collisions();

    // gravity
    if (self.collider.bottom == .none) {
        self.velocity.y = ACCEL;
    } else {
        self.y = @floor(self.y / 16) * 16;
        self.velocity.y = 0;
    }

    self.apply_movement(input, delta_time);

    self.draw_rect.x = @max(0, G.pos_to_tile(self.x) - self.draw_rect.width / 2);
    self.draw_rect.y = @max(0, G.pos_to_tile(self.y) - self.draw_rect.height / 2);
    self.collider.x = self.x;
    self.collider.y = self.y;
    self.camera.target = Vec2.init(self.x, self.y);
}

pub fn init(map_ptr: *Map) Player {
    const spawn_x = 64;
    const spawn_y = 64;
    const p = Player{
        .x = spawn_x,
        .y = spawn_y,
        .w = G.BSIZE * 2,
        .h = G.BSIZE * 3,
        .cursor = Cursor{},
        .camera = rl.Camera2D{
            .offset = rl.Vector2.init(G.ScreenWidth / 2, G.ScreenHeight / 2),
            .target = rl.Vector2.init(spawn_x, spawn_y),
            .rotation = 0.0,
            .zoom = 1.0,
        },
        .collider = Collider{
            .x = spawn_x,
            .y = spawn_y,
            .w = G.BSIZE * 2,
            .h = G.BSIZE * 3,
            .map = map_ptr,
        },
        .draw_rect = rl.Rectangle.init(0, 0, 80, 60),
    };
    return p;
}

pub fn draw(self: *Player) void {
    rl.drawRectangleRec(self.collider.rect, .yellow);
    self.cursor.draw(&self.camera);
}
