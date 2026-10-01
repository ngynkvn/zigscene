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

    // A callback can exceed the entire queue. Only its newest frames can
    // survive, so bound the work under the lock to the queue's capacity.
    const frames: usize = @min(stereo.len / channels, capacity_frames);
    const recent = stereo[stereo.len - frames * channels ..];
    const first: usize = @min(frames, capacity_frames - self.write_frame);
    @memcpy(self.samples[self.write_frame * channels ..][0 .. first * channels], recent[0 .. first * channels]);
    @memcpy(self.samples[0 .. (frames - first) * channels], recent[first * channels ..]);
    self.write_frame = (self.write_frame + frames) % capacity_frames;
    const total = self.frame_count + frames;
    if (total > capacity_frames) {
        self.read_frame = (self.read_frame + total - capacity_frames) % capacity_frames;
    }
    self.frame_count = @min(total, capacity_frames);
}

pub fn popBlock(self: *Queue, block: *[N * channels]f32) bool {
    if (!self.mutex.tryLock()) return false;
    defer self.mutex.unlock();
    if (self.frame_count < N) return false;

    self.readBlock(block);
    return true;
}

/// Take a bounded snapshot ending at the newest complete block. Discard old
/// whole blocks when the renderer falls behind; retain the partial block so
/// callback boundaries do not change the analysis window alignment.
pub fn popLatestBlocks(self: *Queue, blocks: [][N * channels]f32) usize {
    if (blocks.len == 0 or !self.mutex.tryLock()) return 0;
    defer self.mutex.unlock();
    const available = self.frame_count / N;
    const count = @min(available, blocks.len);
    const skipped = (available - count) * N;
    self.read_frame = (self.read_frame + skipped) % capacity_frames;
    self.frame_count -= skipped;
    for (blocks[0..count]) |*block| self.readBlock(block);
    return count;
}

fn readBlock(self: *Queue, block: *[N * channels]f32) void {
    const first: usize = @min(N, capacity_frames - self.read_frame);
    @memcpy(block[0 .. first * channels], self.samples[self.read_frame * channels ..][0 .. first * channels]);
    @memcpy(block[first * channels ..], self.samples[0 .. (N - first) * channels]);
    self.read_frame = (self.read_frame + N) % capacity_frames;
    self.frame_count -= N;
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

test "wrapped submissions and reads preserve stereo sample order" {
    var queue: Queue = .{};
    queue.selectSource(.file);
    var samples: [(capacity_frames + N) * channels]f32 = undefined;
    for (&samples, 0..) |*sample, i| sample.* = @floatFromInt(i);
    var block: [N * channels]f32 = undefined;

    // Leave the write cursor partway through the final block of the ring.
    const initial = capacity_frames - N / 2;
    queue.submit(.file, samples[0 .. initial * channels]);
    for (0..buffered_blocks - 1) |i| {
        try std.testing.expect(queue.popBlock(&block));
        try std.testing.expectEqualSlices(f32, samples[i * N * channels ..][0..block.len], &block);
    }
    queue.submit(.file, samples[initial * channels ..]);
    // Consume both sides of the wrapped submission in order.
    for (buffered_blocks - 1..buffered_blocks + 1) |i| {
        try std.testing.expect(queue.popBlock(&block));
        try std.testing.expectEqualSlices(f32, samples[i * N * channels ..][0..block.len], &block);
    }
    try std.testing.expect(!queue.popBlock(&block));
}

test "partial overflow discards exactly the oldest frames" {
    var queue: Queue = .{};
    queue.selectSource(.file);
    var samples: [(capacity_frames + N / 2) * channels]f32 = undefined;
    for (&samples, 0..) |*sample, i| sample.* = @floatFromInt(i);
    var block: [N * channels]f32 = undefined;
    queue.submit(.file, samples[0 .. capacity_frames * channels]);
    queue.submit(.file, samples[capacity_frames * channels ..]);
    const retained = samples[N / 2 * channels ..];
    for (0..buffered_blocks) |i| {
        try std.testing.expect(queue.popBlock(&block));
        try std.testing.expectEqualSlices(f32, retained[i * N * channels ..][0..block.len], &block);
    }
    try std.testing.expect(!queue.popBlock(&block));
}

test "oversized submission retains only its newest frames" {
    var queue: Queue = .{};
    queue.selectSource(.capture);
    var samples: [(capacity_frames + N / 2) * channels]f32 = undefined;
    for (&samples, 0..) |*sample, i| sample.* = @floatFromInt(i);
    var block: [N * channels]f32 = undefined;
    // Start with pending data and a cursor that is not block-aligned.
    queue.submit(.capture, samples[0 .. channels * 3]);
    queue.submit(.capture, &samples);
    queue.submit(.capture, &.{});
    const retained = samples[samples.len - capacity_frames * channels ..];
    for (0..buffered_blocks) |i| {
        try std.testing.expect(queue.popBlock(&block));
        try std.testing.expectEqualSlices(f32, retained[i * N * channels ..][0..block.len], &block);
    }
    try std.testing.expect(!queue.popBlock(&block));
    queue.submit(.capture, samples[0..block.len]);
    try std.testing.expect(queue.popBlock(&block));
    try std.testing.expectEqualSlices(f32, samples[0..block.len], &block);
}

test "bounded snapshot catches up through a wrap and preserves partial frames" {
    var queue: Queue = .{};
    queue.selectSource(.capture);
    var input: [capacity_frames * channels]f32 = undefined;
    for (&input, 0..) |*sample, i| sample.* = @floatFromInt(i);
    var block: [N * channels]f32 = undefined;
    // Start at a non-aligned cursor, then wrap the next submission.
    queue.submit(.capture, input[0 .. (3 * N + N / 2) * channels]);
    for (0..3) |_| try std.testing.expect(queue.popBlock(&block));
    queue.submit(.capture, input[0 .. 6 * N * channels]);
    var latest: [4][N * channels]f32 = undefined;
    try std.testing.expectEqual(@as(usize, 4), queue.popLatestBlocks(&latest));
    for (latest, 0..) |actual, i| {
        const start = (N + N / 2 + i * N) * channels;
        try std.testing.expectEqualSlices(f32, input[start..][0..actual.len], &actual);
    }
    try std.testing.expectEqual(@as(usize, 0), queue.popLatestBlocks(&latest));
    queue.submit(.capture, input[6 * N * channels ..][0 .. N / 2 * channels]);
    try std.testing.expect(queue.popBlock(&block));
    try std.testing.expectEqualSlices(f32, input[(5 * N + N / 2) * channels ..][0..block.len], &block);
}
