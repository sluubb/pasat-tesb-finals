const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const core = microzig.core;

const usb = @import("usb.zig");

var uart_writer: ?hal.uart.UART.Writer = null;

pub fn init_uart(uart: hal.uart.UART) void {
    uart_writer = uart.writer(.no_deadline);
}

pub fn deinit_uart() void {
    uart_writer = null;
}

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

    if (uart_writer) |uart| {
        uart.print(prefix ++ format ++ "\r\n", .{ seconds, microseconds } ++ args) catch {};
    }

    usb.print(prefix ++ format ++ "\r\n", .{ seconds, microseconds } ++ args);
}
