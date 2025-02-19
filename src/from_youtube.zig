pub fn main() !void {
    const height: u64 = 20;
    const width: u64 = 50;
    const framecap: u64 = 33_000_000;
    const wor_w: i64 = 1_000_000;
    const wor_h: i64 = 1_000_000;
    var camx: i64 = 100_000;
    var camy: i64 = 100_000;
    var camzoom: i64 = 2_000_000;
    camx = camx;
    camy = camy;
    camzoom = camzoom;
    var camdir: u8 = 1;
    var camout: u1 = 1;
    camdir = camdir;
    camout = camout;
    var drawp: u64 = 0;

    // ball1 geometry
    const ball1r: i64 = 5;
    var ball1x: i64 = 10;
    var ball1y: i64 = 10;
    var ball1dx: i64 = 1;
    var ball1dy: i64 = 1;

    while (true) {
        const cyclebegin = try std.time.Instant.now();
        print("{c}[2J\n", .{27});
        for (0..width + 2) |_| {
            print("_", .{});
        }
        print("\n", .{});
        const pisec: i64 = @divFloor(camzoom, width);
        var sectw: i64 = 0;
        var secth: i64 = 0;
        for (0..height) |_| {
            const a: i64 = camx + sectw - ball1x;
            const b: i64 = camy + secth - ball1y;
            const h: f64 = @floatFromInt((a * a) + (b * b));
            const d: f64 = @sqrt(h);
            if (d < ball1r) {
                drawp = 2;
            }
            print("|", .{});
            for (0..width) |_| {
                if (camx + sectw > 0 and camx + sectw < wor_w and camy + secth > 0 and camy + secth < wor_h) {
                    drawp = 1;
                }
                switch (drawp) {
                    1 => print(".", .{}),
                    2 => print("*", .{}),
                    else => print(" ", .{}),
                }
                drawp = 0;
                sectw += pisec;
            }
            sectw = 0;
            secth += pisec;
            print("|\n", .{});
        }
        for (0..width + 2) |_| {
            print("_", .{});
        }
        print("\n", .{});

        // move the ball and bounce off the wall
        ball1x += ball1dx;
        ball1y += ball1dy;
        if (ball1x > wor_w) {
            ball1dx = -1;
        }
        if (ball1x < 1) {
            ball1dx = 1;
        }
        if (ball1y > wor_h) {
            ball1dy = -1;
        }
        if (ball1y < 1) {
            ball1dy = 1;
        }

        const cycleend = try std.time.Instant.now();
        const elap: u64 = cycleend.since(cyclebegin);
        print("cyt: {} | ", .{elap});
        print("rsc: {} | ", .{framecap / elap});
        std.time.sleep(framecap - elap);
    }
}

fn print(comptime fmt: []const u8, params: anytype) void {
    stdout.print(fmt, params) catch unreachable;
}

const std = @import("std");
const stdout = std.io.getStdOut().writer();
