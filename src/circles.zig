const std = @import("std");
const stdout = std.io.getStdOut().writer();

const WIDTH: usize = 120;
const HEIGHT: usize = 40;

const Ball = struct {
    x: isize = @divTrunc(WIDTH, 2), // x centre mass
    y: isize = @divTrunc(HEIGHT, 2), // y centre mass
    r: isize = 8, // radius
    dx: isize = 1, // current velocity X direction
    dy: isize = 1, // current velocity Y direction
    gravity: isize = 0, // accumulated gravity accelleration
    inertia: isize = 2, // how sluggish it is - number of frame refreshes needed to render the image
    boingo: isize = 0, // how bouncy is it ? gets added to the rebound effect when it hits the floor
    ticks: isize = 0, // accumulated frames for the inertia calc
    display: []const u8 = "@O#$%*=:+~-.", // string of digits to do the rendering -

    pub fn move(self: *Ball) void {

        // if the ball has inertia - thats a divisor to limit the speed a bit
        if (self.inertia > 0) {
            self.ticks += 1;
            if (self.ticks < self.inertia) {
                return;
            }
        }
        self.ticks = 0;

        // add some accelleration due to gravity first - at 0.10 per frame
        self.gravity += 1;
        if (self.gravity >= 10) {
            self.gravity = 0;
            self.dy += 1;
        }
        // limit the speed of the ball, due to aerodynamics
        if (self.dy > 3) self.dy = 3;
        self.x += self.dx;
        self.y += self.dy;

        // hit the left wall - bounce +x
        if (self.x + 4 <= 0) {
            if (self.dx < 0) self.dx = -self.dx;
        }
        // hit the roof - bounce +y
        if (self.y + 4 <= 0) {
            if (self.dy < 0) self.dy = -self.dy;
        }
        // hit the right wall - bounce -x
        if (self.x + 4 >= WIDTH) {
            if (self.dx > 0) self.dx = -self.dx;
        }
        // hit the floor - bounce -y
        if (self.y + self.r >= HEIGHT) {
            if (self.dy > 0) self.dy = -self.dy;
            self.dy -= (self.boingo + @divFloor(HEIGHT, 4));
        }
    }

    pub fn render(self: Ball, buffer: *[HEIGHT][WIDTH]u8) void {
        const r: usize = @intCast(self.r);
        for (0..(r * 2 + 1)) |i| {
            for (0..(r * 2 + 1)) |j| {
                const rel_x = @as(isize, @intCast(j)) - @as(isize, @intCast(self.r));
                const rel_y = @as(isize, @intCast(i)) - @as(isize, @intCast(self.r));
                const dist2 = rel_x * rel_x + rel_y * rel_y;
                if (dist2 <= self.r * self.r) {
                    const x = self.x + rel_x;
                    const y = self.y + rel_y;
                    const len: isize = @intCast(self.display.len);
                    if (x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT) {
                        const dist2_shade: isize = @intCast(dist2 * len);
                        const dist2_ratio: isize = @divFloor(dist2_shade, self.r * self.r);
                        var shade_index: usize = @intCast(dist2_ratio);
                        if (shade_index >= self.display.len) shade_index = self.display.len;
                        if (shade_index < 1) shade_index = 1;
                        buffer[@intCast(y)][@intCast(x)] = self.display[shade_index - 1];
                    }
                }
            }
        }
    }
};

fn print(comptime fmt: []const u8, params: anytype) void {
    stdout.print(fmt, params) catch {};
}

fn clear_screen() void {
    print("\x1B[H\x1B[J", .{});
}

fn render_scene(balls: []Ball) void {
    var buffer: [HEIGHT][WIDTH]u8 = undefined;
    for (0..WIDTH + 2) |_| {
        print("_", .{});
    }
    print("\n", .{});
    for (0..HEIGHT) |y| {
        for (0..WIDTH) |x| {
            buffer[y][x] = ' ';
        }
    }

    for (balls) |ball| ball.render(&buffer);

    for (buffer) |row| {
        print("|{s}|\n", .{row});
    }

    for (0..WIDTH + 2) |_| {
        print("‾", .{});
    }
    print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var balls = std.ArrayList(Ball).init(allocator);
    try balls.append(Ball{});

    // a gas giant !
    try balls.append(Ball{
        .r = 22,
        .x = 1,
        .y = 1,
        .dx = -1,
        .dy = -1,
        .inertia = 8,
        .display = "X==----.......",
        .boingo = -2,
    });
    try balls.append(Ball{
        .r = 12,
        .dx = -1,
        .dy = -1,
    });

    try balls.append(Ball{
        .r = 5,
        .dx = -1,
        .dy = 1,
        .boingo = 2,
        .inertia = 0,
    });
    try balls.append(Ball{
        .r = 7,
        .x = 11,
        .y = 10,
        .dx = -1,
        .dy = 1,
        .inertia = 2,
    });
    try balls.append(Ball{
        .r = 13,
        .y = 8,
        .dx = 1,
        .dy = 1,
        .inertia = 3,
    });

    while (true) {
        const start_time = try std.time.Instant.now();
        clear_screen();
        render_scene(balls.items);

        for (balls.items) |*ball| {
            ball.move();
        }

        const end_time = try std.time.Instant.now();
        const elapsed = end_time.since(start_time);
        const framecap: usize = 33_000_000;

        // print("cyt: {: >5} | ", .{elapsed});
        // print("rsc: {: >5} | ", .{framecap / elapsed});
        for (balls.items, 1..) |ball, i| {
            print("Ball {:0>3}: {: >3}:{: >3} | ", .{ i, ball.dx, ball.dy });
        }

        std.time.sleep(framecap - elapsed);
    }
}
