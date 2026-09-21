//! Bounded stereo PCM queue shared by audio callbacks and the render thread.
//! Callbacks never wait for the consumer or allocate memory.
const std = @import("std");
const N = @import("../core/config.zig").Audio.buffer_size;
const channels = @import("../core/config.zig").Audio.channels;
const Queue = @This();

const buffered_blocks = 8;
pub const capacity_frames = N * buffered_blocks;
pub const Source = enum { none, file, capture };

mutex: std.atomic.Mutex = .unlocked,
source: Source = .none,
samples: [capacity_frames * channels]f32 = undefined,
read_frame: usize = 0,
write_frame: usize = 0,
frame_count: usize = 0,

pub fn submit(self: *Queue, from: Source, stereo: []const f32) void {
    std.debug.assert(stereo.len % channels == 0);
    if (!self.mutex.tryLock()) return;
    defer self.mutex.unlock();
    if (from != self.source) return;

    for (0..stereo.len / channels) |i| {
        const dest = self.write_frame * channels;
        @memcpy(self.samples[dest..][0..channels], stereo[i * channels ..][0..channels]);
        self.write_frame = (self.write_frame + 1) % capacity_frames;
        if (self.frame_count == capacity_frames) {
            self.read_frame = (self.read_frame + 1) % capacity_frames;
        } else {
            self.frame_count += 1;
        }
    }
}

pub fn popBlock(self: *Queue, block: *[N * channels]f32) bool {
    if (!self.mutex.tryLock()) return false;
    defer self.mutex.unlock();
    if (self.frame_count < N) return false;

    for (0..N) |i| {
        const source = ((self.read_frame + i) % capacity_frames) * channels;
        @memcpy(block[i * channels ..][0..channels], self.samples[source..][0..channels]);
    }
    self.read_frame = (self.read_frame + N) % capacity_frames;
    self.frame_count -= N;
    return true;
}

pub fn selectSource(self: *Queue, source: Source) void {
    while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
    defer self.mutex.unlock();
    self.read_frame = 0;
    self.write_frame = 0;
    self.frame_count = 0;
    self.source = source;
}

test "partial callbacks produce one complete analysis block" {
    var queue: Queue = .{};
    queue.selectSource(.file);
    var block: [N * channels]f32 = undefined;
    const first: [N]f32 = @splat(0.25);
    const second: [N]f32 = @splat(0.75);
    queue.submit(.file, &first);
    try std.testing.expect(!queue.popBlock(&block));
    queue.submit(.file, &second);
    try std.testing.expect(queue.popBlock(&block));
    try std.testing.expectEqual(@as(f32, 0.25), block[0]);
    try std.testing.expectEqual(@as(f32, 0.75), block[N]);
    try std.testing.expect(!queue.popBlock(&block));
}

test "overflow keeps the newest frames" {
    var queue: Queue = .{};
    queue.selectSource(.capture);
    var block: [N * channels]f32 = undefined;
    const old: [capacity_frames * channels]f32 = @splat(1);
    const recent: [N * channels]f32 = @splat(2);
    queue.submit(.capture, &old);
    queue.submit(.capture, &recent);
    try std.testing.expect(queue.popBlock(&block));
    try std.testing.expectEqual(@as(f32, 1), block[0]);
    for (0..capacity_frames / N - 2) |_| try std.testing.expect(queue.popBlock(&block));
    try std.testing.expect(queue.popBlock(&block));
    try std.testing.expectEqual(@as(f32, 2), block[0]);
}

test "source switch discards queued frames" {
    var queue: Queue = .{};
    var block: [N * channels]f32 = undefined;
    const old: [N * channels]f32 = @splat(1);
    const recent: [N * channels]f32 = @splat(2);
    queue.selectSource(.file);
    queue.submit(.file, &old);
    queue.selectSource(.capture);
    queue.submit(.file, &old);
    try std.testing.expect(!queue.popBlock(&block));
    queue.submit(.capture, &recent);
    try std.testing.expect(queue.popBlock(&block));
    try std.testing.expectEqual(@as(f32, 2), block[0]);
}
