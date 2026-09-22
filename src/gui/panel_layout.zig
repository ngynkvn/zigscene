//! Keeps grouped controls aligned within a settings panel.
const Rectangle = @import("../ext/structs.zig").Rectangle;
const PanelLayout = @This();

anchor: Rectangle,
cursor_y: f32,

pub fn init(anchor: Rectangle, first_row_y: f32) PanelLayout {
    return .{ .anchor = anchor, .cursor_y = first_row_y };
}

pub fn groupLabel(self: *const PanelLayout) Rectangle {
    return self.anchor.resize(self.anchor.width - 10, 8).translate(5, self.cursor_y);
}

pub fn row(self: *PanelLayout, spacing: f32) Rectangle {
    const result = self.anchor.resize(self.anchor.width, 16).translate(0, self.cursor_y);
    self.cursor_y += spacing;
    return result;
}

pub fn advance(self: *PanelLayout, spacing: f32) void {
    self.cursor_y += spacing;
}
