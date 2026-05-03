const std = @import("std");

const mz = @import("microzig");
const hal = mz.hal;

const log = @import("log.zig");
const usb = @import("usb.zig");

const drivers = @import("drivers.zig");
const SHT3x = drivers.SHT3x;

pub fn panic(_: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    while (true) {}
}

pub const microzig_options = mz.Options{
    .log_level = .debug,
    .log_scope_levels = &.{
        .{ .scope = .usb_dev, .level = .warn },
        .{ .scope = .usb_ctrl, .level = .warn },
        .{ .scope = .usb_cdc, .level = .warn },
    },
    .logFn = log.log,
};

const pin_config: hal.pins.GlobalConfiguration = .{
    .GPIO16 = .{
        .name = "user_led_green",
        .function = .SIO,
        .direction = .out,
    },
    .GPIO17 = .{
        .name = "user_led_red",
        .function = .SIO,
        .direction = .out,
    },
    .GPIO25 = .{
        .name = "user_led_blue",
        .function = .SIO,
        .direction = .out,
    },
    .GPIO26 = .{
        .function = .I2C1_SDA,
        .pull = .up,
        .slew_rate = .slow,
        .schmitt_trigger = .enabled,
    },
    .GPIO27 = .{
        .function = .I2C1_SCL,
        .pull = .up,
        .slew_rate = .slow,
        .schmitt_trigger = .enabled,
    },
};

const i2c = hal.i2c.instance.num(1);

pub fn main() !void {
    _ = pin_config.apply();

    usb.init();

    defer i2c.reset();
    i2c.apply(.{
        .clock_config = hal.clock_config,
    });

    var i2c_device = hal.drivers.I2C_Device.init(i2c, .from_ms(100));
    var sht3x = SHT3x.init(i2c_device.i2c_device(), @enumFromInt(0x44));

    hal.time.sleep_ms(3000);

    sht3x.measure(.high) catch |e| std.log.scoped(.sht3x).err("failed to start measure: {any}", .{e});

    var old: u64 = hal.time.get_time_since_boot().to_us();
    var new: u64 = 0;

    while (true) {
        usb.ensure_updated();

        new = hal.time.get_time_since_boot().to_us();
        if (new - old < 1000) continue;

        old = new;

        if (sht3x.read() catch |e| blk: {
            std.log.scoped(.sht3x).err("failed to read: {any}", .{e});
            break :blk null;
        }) |reading| {
            if (reading.temperature_c) |t| std.log.info("temperature: {}", .{t});
            if (reading.relative_humidity) |h| std.log.info("relative humidity: {}", .{h});

            sht3x.measure(.high) catch |e| std.log.scoped(.sht3x).err("failed to start measure: {any}", .{e});
        }
    }
}
