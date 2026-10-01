const std = @import("std");

/// Emscripten owns the shared C/JavaScript heap. Its malloc refreshes the JS
/// typed-array views when memory grows; Zig's wasm page allocator cannot.
pub const allocator = if (@import("builtin").os.tag == .emscripten)
    std.heap.c_allocator
else
    std.heap.page_allocator;
