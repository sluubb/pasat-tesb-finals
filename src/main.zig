const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;
const core = microzig.core;

const log = @import("log.zig");

const USB_Device = hal.usb.Polled(.{});
const USB_Serial = core.usb.drivers.CDC;

var usb_device: USB_Device = undefined;

var usb_controller: core.usb.DeviceController(.{
    .bcd_usb = USB_Device.max_supported_bcd_usb,
    .device_triple = .unspecified,
    .vendor = USB_Device.default_vendor_id,
    .product = USB_Device.default_product_id,
    .bcd_device = .v1_00,
    .serial = "someserial",
    .max_supported_packet_size = USB_Device.max_supported_packet_size,
    .configurations = &.{.{
        .attributes = .{ .self_powered = false },
        .max_current_ma = 50,
        .Drivers = struct { serial: USB_Serial, reset: hal.usb.ResetDriver(null, 0) },
    }},
}, .{.{
    .serial = .{ .itf_notifi = "Board CDC", .itf_data = "Board CDC Data" },
    .reset = "",
}}) = .init;

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
    const pins = board.pin_config.apply();

    const uart_log = hal.uart.instance.num(0);
    uart_log.apply(.{
        .clock_config = hal.clock_config,
    });
    log.init_uart(uart_log);

    usb_device = .init();

    while (true) {
        usb_device.poll(&usb_controller);

        std.log.info("Test message.", .{});

        pins.user_led_r.toggle();
        pins.user_led_g.toggle();
        pins.user_led_b.toggle();
    }
}
