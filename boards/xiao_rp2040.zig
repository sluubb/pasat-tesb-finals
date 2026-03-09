const microzig = @import("microzig");
const hal = microzig.hal;

pub const flash = 2 * 1024 * 1024;
pub const ram = 264 * 1024;
pub const xosc_freq = 12_000_000;

pub const bootrom = @import("shared/rp2040_bootrom.zig");

comptime {
    _ = bootrom;
}

pub const pin_config = hal.pins.GlobalConfiguration{
    .GPIO12 = .{ .name = "rgb_led", .direction = .out },
    .GPIO17 = .{ .name = "user_led_r", .direction = .out },
    .GPIO16 = .{ .name = "user_led_g", .direction = .out },
    .GPIO25 = .{ .name = "user_led_b", .direction = .out },
};
