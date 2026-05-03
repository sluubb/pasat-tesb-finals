const std = @import("std");

const mz = @import("microzig");
const hal = mz.hal;

const usb = @import("usb.zig");

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_prefix = comptime "[{}.{:0>6}] " ++ level.asText();
    const prefix = comptime level_prefix ++ switch (scope) {
        .default => ": ",
        else => " (" ++ @tagName(scope) ++ "): ",
    };

    const current_time = hal.time.get_time_since_boot();
    const seconds = current_time.to_us() / std.time.us_per_s;
    const microseconds = current_time.to_us() % std.time.us_per_s;

    usb.print(prefix ++ format ++ "\r\n", .{ seconds, microseconds } ++ args);
}
