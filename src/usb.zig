const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;
const core = microzig.core;

const USB_Device = hal.usb.Polled(.{});
const USB_Serial = core.usb.drivers.CDC;

var device: USB_Device = undefined;

var controller: core.usb.DeviceController(.{
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
        .Drivers = struct { serial: core.usb.drivers.CDC, reset: hal.usb.ResetDriver(null, 0) },
    }},
}, .{.{
    .serial = .{ .itf_notifi = "Board CDC", .itf_data = "Board CDC Data" },
    .reset = "",
}}) = .init;

var tx_buf: [1024]u8 = undefined;
var head: usize = 0;

pub fn init() void {
    device = .init();
}

pub fn poll() void {
    device.poll(&controller);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    head += (std.fmt.bufPrint(tx_buf[head..], fmt, args) catch &.{}).len;
}

pub fn flush() bool {
    if (controller.drivers()) |drivers| {
        var tx = tx_buf[0..head];

        while (tx.len > 0) {
            tx = tx[drivers.serial.write(tx)..];
            poll();
        }

        while (!drivers.serial.flush()) {
            poll();
        }

        head = 0;
        return true;
    }

    return false;
}
