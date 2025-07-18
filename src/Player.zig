const rl = @import("raylib");

const std = @import("std");
const Map = @import("./Map.zig");
const G = @import("globals.zig");
const Collider = @import("./Collider.zig");
const Vec2 = rl.Vector2;
const Vec2i = struct { x: i32, y: i32 };
const Tile = @import("./Tile.zig");

const Cursor = struct {
    pos: Vec2 = .{ .x = 0, .y = 0 },
    const signals = enum {
        // TODO: dont break them instantly
        BreakTile,
    };
    const input_res = struct {
        t: signals,
        pos: Vec2i,
    };

    // only for input
    fn input(self: *Cursor) ?input_res {
        // !TEMP
        const pos = Vec2i{
            .x = G.I32(self.pos.x / G.BSIZE),
            .y = G.I32(self.pos.y / G.BSIZE),
        };
        if (rl.isMouseButtonPressed(.left))
            return .{ .t = signals.BreakTile, .pos = pos };
        return null;
    }
    fn draw(self: *Cursor, cam: *rl.Camera2D) void {
        self.pos = rl.getScreenToWorld2D(rl.getMousePosition(), cam.*);

        rl.drawRectangle(
            G.I32(self.pos.x / G.BSIZE) * G.BSIZE,
            G.I32(self.pos.y / G.BSIZE) * G.BSIZE,
            G.BSIZE,
            G.BSIZE,
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
draw_pos: Vec2 = Vec2{ .x = 0, .y = 0 },
collider: Collider,
cursor: Cursor,

map_ptr: *Map,
speed: f32 = 0.05,
decceleration: f32 = 2,
max_speed: f32 = 1.0,

const MAX_SPEED = 11.0 * G.BSIZE;
const TIME_TO_MAX = 0.5;
const TIME_TO_STOP = 0.15;

const ACCEL = MAX_SPEED / TIME_TO_MAX;
const DECCEL = MAX_SPEED / TIME_TO_STOP;

fn apply_horizontal_movement(self: *Player, delta_time: f32) void {
    const input = G.input_vector_1d(.a, .d);
    if (input != 0) {
        self.velocity.x += input * ACCEL * delta_time;
    } else if (self.velocity.x != 0) {
        const sign = self.velocity.x / @abs(self.velocity.x);
        self.velocity.x -= sign * DECCEL * delta_time;
        if (@abs(self.velocity.x) < DECCEL * delta_time)
            self.velocity.x = 0;
    }

    self.velocity.x = std.math.clamp(self.velocity.x, -MAX_SPEED, MAX_SPEED);

    self.x += self.velocity.x * delta_time;
    self.collider.x = self.x;
    self.collider.check_collisions();

    if (self.velocity.x < 0 and self.collider.left == .solid) {
        self.velocity.x = 0;
        self.x = @ceil(self.x / G.BSIZE) * G.BSIZE;
    } else if (self.velocity.x > 0 and self.collider.right == .solid) {
        self.velocity.x = 0;
        self.x = @floor(self.x / G.BSIZE) * G.BSIZE;
    }
}

fn apply_vertical_movement(self: *Player, delta_time: f32) void {
    self.velocity.y += G.gravity * delta_time;
    self.y += self.velocity.y * delta_time;

    self.collider.y = self.y;
    self.collider.check_collisions();

    if (self.velocity.y > 0 and self.collider.bottom == .solid) {
        self.velocity.y = 0;
        self.y = @floor(self.y / G.BSIZE) * G.BSIZE;
    } else if (self.velocity.y < 0 and self.collider.top == .solid) {
        self.velocity.y = 0;
        self.y = @ceil(self.y / G.BSIZE) * G.BSIZE;
    }
}

pub fn update(self: *Player) !void {
    //
    // cursor input
    {
        const res_tmp = self.cursor.input();
        if (res_tmp != null) {
            const res = res_tmp.?;
            // std.debug.print("{}\n", .{res});
            switch (res.t) {
                .BreakTile => {
                    try self.map_ptr.set_tile_client(res.pos.x, res.pos.y, Tile.None);
                },
            }
        }
    }

    if (comptime G.NOCLIP) {
        self.camera.target.x += G.input_vector_1d(.a, .d) * 50;
        self.camera.target.y += G.input_vector_1d(.w, .s) * 50;
        if (rl.isKeyDown(.minus))
            self.camera.zoom -= 0.01;

        if (rl.isKeyDown(.equal))
            self.camera.zoom += 0.01;
    } else {
        const delta_time = rl.getFrameTime();
        self.apply_horizontal_movement(delta_time);
        self.apply_vertical_movement(delta_time);

        self.camera.target = Vec2.init(
            std.math.clamp(self.x, G.CameraBounds.left, G.CameraBounds.right),
            std.math.clamp(self.y, G.CameraBounds.top, G.CameraBounds.bottom),
        );
    }

    self.draw_pos.x = @max(0, self.camera.target.x - self.camera.offset.x);
    self.draw_pos.y = @max(0, self.camera.target.y - self.camera.offset.y);
    self.collider.x = self.x;
    self.collider.y = self.y;
}

pub fn init(map_ptr: *Map) Player {
    const spawn_x = 8500;
    const spawn_y = 4500;
    const p = Player{
        .map_ptr = map_ptr,
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
    };
    return p;
}

pub fn draw(self: *Player) void {
    rl.drawRectangleRec(self.collider.rect, .yellow);
    self.cursor.draw(&self.camera);
}
