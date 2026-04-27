const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;
const core = microzig.core;

const log = @import("log.zig");
const usb = @import("usb.zig");

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    std.log.err("panic: {s}", .{message});
    @breakpoint();
    while (true) {}
}

pub const microzig_options = microzig.Options{
    .log_level = .debug,
    .log_scope_levels = &.{
        .{ .scope = .usb_dev, .level = .warn },
        .{ .scope = .usb_ctrl, .level = .warn },
        .{ .scope = .usb_cdc, .level = .warn },
    },
    .logFn = log.log,
};

pub fn main() !void {
    const uart_log = hal.uart.instance.num(0);
    uart_log.apply(.{
        .clock_config = hal.clock_config,
    });
    log.init_uart(uart_log);

    usb.init();

    var old: u64 = hal.time.get_time_since_boot().to_us();
    var new: u64 = 0;

    while (true) {
        usb.poll();

        new = hal.time.get_time_since_boot().to_us();
        if (new - old > 500000) {
            old = new;
            std.log.info("Test message.", .{});
            _ = usb.flush();
        }
    }
}
