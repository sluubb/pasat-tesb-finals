const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;

pub fn main() !void {
    const pins = board.pin_config.apply();

    while (true) {
        pins.user_led_r.toggle();
        hal.time.sleep_ms(250);
        pins.user_led_g.toggle();
        hal.time.sleep_ms(250);
        pins.user_led_b.toggle();
        hal.time.sleep_ms(250);
    }
}
