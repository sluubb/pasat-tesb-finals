const std = @import("std");

pub fn RingBuffer(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        buf: [capacity]T,
        tail: usize,
        head: usize,
        full: bool,

        pub fn init() Self {
            return .{
                .buf = undefined,
                .tail = 0,
                .head = 0,
                .full = false,
            };
        }

        pub fn push(self: *Self, value: T) void {
            if (self.full) unreachable;

            self.buf[self.head] = value;

            self.head = (self.head + 1) % capacity;
            self.full = self.tail == self.head;
        }

        pub fn pop(self: *Self) ?T {
            if (self.is_empty()) return null;

            const value = self.buf[self.tail];
            self.full = false;
            self.tail = (self.tail + 1) % capacity;

            return value;
        }

        pub fn view(self: *Self, scratch: []T) []T {
            if (self.tail < self.head) return self.buf[self.tail..self.head];

            const l = self.len();
            if (scratch.len < l) unreachable;

            var j: usize = self.tail;
            for (0..l) |i| {
                scratch[i] = self.buf[j];
                j = (j + 1) % capacity;
            }

            return scratch[0..l];
        }

        pub fn clear(self: *Self) void {
            self.full = false;
            self.tail = self.head;
        }

        pub fn len(self: *const Self) usize {
            if (self.full) return capacity;
            if (self.head >= self.tail)
                return self.head - self.tail;
            return capacity + self.head - self.tail;
        }

        pub fn is_empty(self: *const Self) bool {
            return (!self.full and self.tail == self.head);
        }
    };
}
