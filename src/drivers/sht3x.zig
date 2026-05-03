const std = @import("std");

const mz = @import("microzig");
const I2C_Device = mz.drivers.base.I2C_Device;

const Self = @This();

i2c: I2C_Device,
address: I2C_Device.Address,

pub const Reading = struct {
    temperature_c: ?f32,
    relative_humidity: ?f32,
};

pub const Repeatability = enum {
    high,
    medium,
    low,

    pub fn toByte(self: Repeatability) u8 {
        return switch (self) {
            .high => 0x00,
            .medium => 0x0B,
            .low => 0x16,
        };
    }
};

pub fn init(i2c: I2C_Device, address: I2C_Device.Address) Self {
    return .{
        .i2c = i2c,
        .address = address,
    };
}

pub fn measure(self: Self, repeatability: Repeatability) !void {
    try self.i2c.write(
        self.address,
        &[_]u8{ 0x24, repeatability.toByte() },
    );
}

pub fn read(self: Self) !?Reading {
    var data: [6]u8 = undefined;
    const read_len = self.i2c.read(self.address, &data) catch |e| switch (e) {
        error.NoAcknowledge, error.DeviceNotPresent => return null,
        else => return e,
    };

    if (read_len != data.len) {
        return error.InvalidResponseLength;
    }

    const temperature_valid = data[2] == crc8(data[0..2]);
    const humidity_valid = data[5] == crc8(data[3..5]);

    return Reading{
        .temperature_c = if (temperature_valid) to_temperature_c((@as(u16, data[0]) << 8) | data[1]) else null,
        .relative_humidity = if (humidity_valid) to_relative_humidity((@as(u16, data[3]) << 8) | data[4]) else null,
    };
}

pub fn to_temperature_c(raw: u16) f32 {
    return 175 * @as(f32, @floatFromInt(raw)) / 65535 - 45;
}

pub fn to_relative_humidity(raw: u16) f32 {
    return 100 * @as(f32, @floatFromInt(raw)) / 65535;
}

/// x8+x5+x4+1
fn crc8(data: []u8) u8 {
    var crc: u8 = 0xFF;
    for (data) |b| {
        crc ^= b;
        for (0..8) |_| {
            crc = if (crc & 0x80 != 0) (crc << 1) ^ 0x31 else crc << 1;
        }
    }
    return crc;
}
