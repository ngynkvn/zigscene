const std = @import("std");
const Allocator = @import("std").mem.Allocator;
const assert = @import("std").debug.assert;
const copyForwards = @import("std").mem.copyForwards;

pub fn RingBuffer(comptime T: type) type {
    return struct {
        const Self = @This();
        data: []T,
        read_index: usize,
        write_index: usize,

        pub const Error = error{ Full, ReadLengthInvalid };

        /// Allocate a new `RingBuffer`; `deinit()` should be called to free the buffer.
        pub fn init(allocator: Allocator, capacity: usize) Allocator.Error!Self {
            const bytes = try allocator.alloc(T, capacity);
            return Self{
                .data = bytes,
                .write_index = 0,
                .read_index = 0,
            };
        }

        /// Free the data backing a `RingBuffer`; must be passed the same `Allocator` as
        /// `init()`.
        pub fn deinit(self: *Self, allocator: Allocator) void {
            allocator.free(self.data);
            self.* = undefined;
        }

        /// Returns `index` modulo the length of the backing slice.
        pub fn mask(self: Self, index: usize) usize {
            return index % self.data.len;
        }

        /// Returns `index` modulo twice the length of the backing slice.
        pub fn mask2(self: Self, index: usize) usize {
            return index % (2 * self.data.len);
        }

        /// Write `byte` into the ring buffer. Returns `error.Full` if the ring
        /// buffer is full.
        pub fn write(self: *Self, byte: T) Error!void {
            if (self.isFull()) return error.Full;
            self.writeAssumeCapacity(byte);
        }

        /// Write `byte` into the ring buffer. If the ring buffer is full, the
        /// oldest byte is overwritten.
        pub fn writeAssumeCapacity(self: *Self, byte: T) void {
            self.data[self.mask(self.write_index)] = byte;
            self.write_index = self.mask2(self.write_index + 1);
        }

        /// Write `bytes` into the ring buffer. Returns `error.Full` if the ring
        /// buffer does not have enough space, without writing any data.
        /// Uses memcpy and so `bytes` must not overlap ring buffer data.
        pub fn writeSlice(self: *Self, bytes: []const T) Error!void {
            if (self.len() + bytes.len > self.data.len) return error.Full;
            self.writeSliceAssumeCapacity(bytes);
        }

        /// Write `bytes` into the ring buffer. If there is not enough space, older
        /// bytes will be overwritten.
        /// Uses memcpy and so `bytes` must not overlap ring buffer data.
        pub fn writeSliceAssumeCapacity(self: *Self, bytes: []const T) void {
            assert(bytes.len <= self.data.len);
            const data_start = self.mask(self.write_index);
            const part1_data_end = @min(data_start + bytes.len, self.data.len);
            const part1_len = part1_data_end - data_start;
            @memcpy(self.data[data_start..part1_data_end], bytes[0..part1_len]);

            const remaining = bytes.len - part1_len;
            const to_write = @min(remaining, remaining % self.data.len + self.data.len);
            const part2_bytes_start = bytes.len - to_write;
            const part2_bytes_end = @min(part2_bytes_start + self.data.len, bytes.len);
            const part2_len = part2_bytes_end - part2_bytes_start;
            @memcpy(self.data[0..part2_len], bytes[part2_bytes_start..part2_bytes_end]);
            if (part2_bytes_end != bytes.len) {
                const part3_len = bytes.len - part2_bytes_end;
                @memcpy(self.data[0..part3_len], bytes[part2_bytes_end..bytes.len]);
            }
            self.write_index = self.mask2(self.write_index + bytes.len);
        }

        /// Write `bytes` into the ring buffer. Returns `error.Full` if the ring
        /// buffer does not have enough space, without writing any data.
        /// Uses copyForwards and can write slices from this RingBuffer into itself.
        pub fn writeSliceForwards(self: *Self, bytes: []const T) Error!void {
            if (self.len() + bytes.len > self.data.len) return error.Full;
            self.writeSliceForwardsAssumeCapacity(bytes);
        }

        /// Write `bytes` into the ring buffer. If there is not enough space, older
        /// bytes will be overwritten.
        /// Uses copyForwards and can write slices from this RingBuffer into itself.
        pub fn writeSliceForwardsAssumeCapacity(self: *Self, bytes: []const T) void {
            assert(bytes.len <= self.data.len);
            const data_start = self.mask(self.write_index);
            const part1_data_end = @min(data_start + bytes.len, self.data.len);
            const part1_len = part1_data_end - data_start;
            copyForwards(T, self.data[data_start..], bytes[0..part1_len]);

            const remaining = bytes.len - part1_len;
            const to_write = @min(remaining, remaining % self.data.len + self.data.len);
            const part2_bytes_start = bytes.len - to_write;
            const part2_bytes_end = @min(part2_bytes_start + self.data.len, bytes.len);
            copyForwards(T, self.data[0..], bytes[part2_bytes_start..part2_bytes_end]);
            if (part2_bytes_end != bytes.len)
                copyForwards(T, self.data[0..], bytes[part2_bytes_end..bytes.len]);
            self.write_index = self.mask2(self.write_index + bytes.len);
        }

        /// Consume a byte from the ring buffer and return it. Returns `null` if the
        /// ring buffer is empty.
        pub fn read(self: *Self) ?T {
            if (self.isEmpty()) return null;
            return self.readAssumeLength();
        }

        /// Consume a byte from the ring buffer and return it; asserts that the buffer
        /// is not empty.
        pub fn readAssumeLength(self: *Self) T {
            assert(!self.isEmpty());
            const byte = self.data[self.mask(self.read_index)];
            self.read_index = self.mask2(self.read_index + 1);
            return byte;
        }

        /// Reads first `length` bytes written to the ring buffer into `dest`; Returns
        /// Error.ReadLengthInvalid if length greater than ring or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        pub fn readFirst(self: *Self, dest: []T, length: usize) Error!void {
            if (length > self.len() or length > dest.len) return error.ReadLengthInvalid;
            self.readFirstAssumeLength(dest, length);
        }

        /// Reads first `length` bytes written to the ring buffer into `dest`;
        /// Asserts that length not greater than ring buffer or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        pub fn readFirstAssumeLength(self: *Self, dest: []T, length: usize) void {
            assert(length <= self.len() and length <= dest.len);
            const slice = self.sliceAt(self.read_index, length);
            slice.copyTo(dest);
            self.read_index = self.mask2(self.read_index + length);
        }

        /// Reads last `length` bytes written to the ring buffer into `dest`; Returns
        /// Error.ReadLengthInvalid if length greater than ring or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        /// Reduces write index by `length`.
        pub fn readLast(self: *Self, dest: []T, length: usize) Error!void {
            if (length > self.len() or length > dest.len) return error.ReadLengthInvalid;
            self.readLastAssumeLength(dest, length);
        }

        /// Reads last `length` bytes written to the ring buffer into `dest`;
        /// Asserts that length not greater than ring buffer or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        /// Reduces write index by `length`.
        pub fn readLastAssumeLength(self: *Self, dest: []T, length: usize) void {
            assert(length <= self.len() and length <= dest.len);
            const slice = self.sliceLast(length);
            slice.copyTo(dest);
            self.write_index = if (self.write_index >= self.data.len)
                self.write_index - length
            else
                self.mask(self.write_index + self.data.len - length);
        }

        /// Returns `true` if the ring buffer is empty and `false` otherwise.
        pub fn isEmpty(self: Self) bool {
            return self.write_index == self.read_index;
        }

        /// Returns `true` if the ring buffer is full and `false` otherwise.
        pub fn isFull(self: Self) bool {
            return self.mask2(self.write_index + self.data.len) == self.read_index;
        }

        /// Returns the length of data available for reading
        pub fn len(self: Self) usize {
            const wrap_offset = 2 * self.data.len * @intFromBool(self.write_index < self.read_index);
            const adjusted_write_index = self.write_index + wrap_offset;
            return adjusted_write_index - self.read_index;
        }

        /// A `Slice` represents a region of a ring buffer. The region is split into two
        /// sections as the ring buffer data will not be contiguous if the desired
        /// region wraps to the start of the backing slice.
        pub const Slice = struct {
            first: []T,
            second: []T,

            /// Copy data from `self` into `dest`
            pub fn copyTo(self: Slice, dest: []T) void {
                @memcpy(dest[0..self.first.len], self.first);
                @memcpy(dest[self.first.len..][0..self.second.len], self.second);
            }
        };

        /// Returns a `Slice` for the region of the ring buffer starting at
        /// `self.mask(start_unmasked)` with the specified length.
        pub fn sliceAt(self: Self, start_unmasked: usize, length: usize) Slice {
            assert(length <= self.data.len);
            const slice1_start = self.mask(start_unmasked);
            const slice1_end = @min(self.data.len, slice1_start + length);
            const slice1 = self.data[slice1_start..slice1_end];
            const slice2 = self.data[0 .. length - slice1.len];
            return Slice{
                .first = slice1,
                .second = slice2,
            };
        }

        /// Returns a `Slice` for the last `length` bytes written to the ring buffer.
        /// Does not check that any bytes have been written into the region.
        pub fn sliceLast(self: Self, length: usize) Slice {
            return self.sliceAt(self.write_index + self.data.len - length, length);
        }
    };
}

test "Writing" {
    const allocator = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expectEqualSlices = std.testing.expectEqualSlices;
    const expectError = std.testing.expectError;
    inline for (&.{ u8, i8, f32, usize }) |T| {
        const Ring = RingBuffer(T);
        {
            const data = [5]T{ 1, 2, 3, 4, 5 };
            var RB = try Ring.init(allocator, 5);
            defer RB.deinit(allocator);
            try RB.writeSlice(&data);

            var output = [5]T{ 0, 0, 0, 0, 0 };
            try RB.readFirst(&output, 5);
            try expectEqualSlices(T, &data, &output);
        }
        {
            const data = [5]T{ 1, 2, 3, 4, 5 };
            var RB = try Ring.init(allocator, 3);
            try expectEqual(null, RB.read());
            defer RB.deinit(allocator);
            try expectError(Ring.Error.Full, RB.writeSlice(&data));

            var output = [5]T{ 0, 0, 0, 0, 0 };
            try expectError(Ring.Error.ReadLengthInvalid, RB.readFirst(&output, 5));
            try expectEqualSlices(T, &std.mem.zeroes([5]T), &output);
        }
        {
            const data = [5]T{ 1, 2, 3, 4, 5 };
            var RB = try Ring.init(allocator, 7);
            defer RB.deinit(allocator);
            RB.writeSliceAssumeCapacity(&data);
            RB.writeSliceAssumeCapacity(&data);

            var output = [5]T{ 0, 0, 0, 0, 0 };
            try RB.readFirst(&output, 5);
            try expectEqualSlices(T, &[5]T{ 3, 4, 5, 4, 5 }, &output);
            const expected = [7]T{ 3, 4, 5, 4, 5, 1, 2 };
            try expectEqualSlices(T, &expected, RB.data);
        }
    }
}
