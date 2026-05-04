const std = @import("std");

pub const RollingParser = struct {
    const Self = @This();

    buf: [256]u8,
    head: usize,

    pub fn init() Self {
        return .{
            .buf = undefined,
            .head = 0,
        };
    }

    pub fn encode(self: *Self, byte: u8) void {
        if (self.head >= self.buf.len) unreachable;

        self.buf[self.head] = byte;
        self.head += 1;

        if (byte != '\n') return;

        self.buf[self.head] = 0;
        const sentence = self.buf[0..self.head];

        _ = parse_nmea(sentence.ptr);

        self.head = 0;
    }
};

pub fn parse_nmea(sentence: [*:0]u8) ?void {
    const c = @cImport({
        @cInclude("minmea.h");
    });

    const sentence_id = c.minmea_sentence_id(sentence, false);

    switch (sentence_id) {
        c.MINMEA_SENTENCE_RMC => {
            var frame: c.minmea_sentence_rmc = undefined;
            if (!c.minmea_parse_rmc(&frame, sentence)) return null;
            // TODO: handle gps data
        },
        else => {},
    }
}
