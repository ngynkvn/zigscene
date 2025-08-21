const std = @import("std");

test {
    std.testing.refAllDeclsRecursive(@This());
}

pub const LIGHTGRAY: Color = .from([4]u8{ 200, 200, 200, 255 });
pub const GRAY: Color = .from([4]u8{ 130, 130, 130, 255 });
pub const DARKGRAY: Color = .from([4]u8{ 80, 80, 80, 255 });
pub const YELLOW: Color = .from([4]u8{ 253, 249, 0, 255 });
pub const GOLD: Color = .from([4]u8{ 255, 203, 0, 255 });
pub const ORANGE: Color = .from([4]u8{ 255, 161, 0, 255 });
pub const PINK: Color = .from([4]u8{ 255, 109, 194, 255 });
pub const RED: Color = .from([4]u8{ 230, 41, 55, 255 });
pub const MAROON: Color = .from([4]u8{ 190, 33, 55, 255 });
pub const GREEN: Color = .from([4]u8{ 0, 228, 48, 255 });
pub const LIME: Color = .from([4]u8{ 0, 158, 47, 255 });
pub const DARKGREEN: Color = .from([4]u8{ 0, 117, 44, 255 });
pub const SKYBLUE: Color = .from([4]u8{ 102, 191, 255, 255 });
pub const BLUE: Color = .from([4]u8{ 0, 121, 241, 255 });
pub const DARKBLUE: Color = .from([4]u8{ 0, 82, 172, 255 });
pub const PURPLE: Color = .from([4]u8{ 200, 122, 255, 255 });
pub const VIOLET: Color = .from([4]u8{ 135, 60, 190, 255 });
pub const DARKPURPLE: Color = .from([4]u8{ 112, 31, 126, 255 });
pub const BEIGE: Color = .from([4]u8{ 211, 176, 131, 255 });
pub const BROWN: Color = .from([4]u8{ 127, 106, 79, 255 });
pub const DARKBROWN: Color = .from([4]u8{ 76, 63, 47, 255 });
pub const WHITE: Color = .from([4]u8{ 255, 255, 255, 255 });
pub const BLACK: Color = .from([4]u8{ 0, 0, 0, 255 });
pub const BLANK: Color = .from([4]u8{ 0, 0, 0, 0 });
pub const MAGENTA: Color = .from([4]u8{ 255, 0, 255, 255 });
pub const RAYWHITE: Color = .from([4]u8{ 245, 245, 245, 255 });

// TYPES
pub const Color = @import("color.zig").Color;
pub const vector = @import("vector/vector.zig");
pub const Vector2 = vector.Vector2;
pub const Vector3 = vector.Vector3;
pub const Vector4 = vector.Vector4;
pub const Matrix = vector.Matrix;
pub const Quaternion = vector.Quaternion;
pub const CameraProjection = enum(c_int) { perspective = 0, orthographic = 1 };

pub const Image = extern struct { data: ?*anyopaque = null, width: c_int = 0, height: c_int = 0, mipmaps: c_int = 0, format: c_int = 0 };
pub const Texture = extern struct { id: c_uint = 0, width: c_int = 0, height: c_int = 0, mipmaps: c_int = 0, format: c_int = 0 };
pub const Texture2D = Texture;
pub const TextureCubemap = Texture;
pub const RenderTexture = extern struct { id: c_uint = 0, texture: Texture = .{}, depth: Texture = .{} };
pub const RenderTexture2D = RenderTexture;
pub const NPatchInfo = extern struct { source: Rectangle = .{}, left: c_int = 0, top: c_int = 0, right: c_int = 0, bottom: c_int = 0, layout: c_int = 0 };
pub const GlyphInfo = extern struct { value: c_int = 0, offsetX: c_int = 0, offsetY: c_int = 0, advanceX: c_int = 0, image: Image = .{} };
pub const Font = extern struct { baseSize: c_int = 0, glyphCount: c_int = 0, glyphPadding: c_int = 0, texture: Texture2D = .{}, recs: [*c]Rectangle = null, glyphs: [*c]GlyphInfo = null };
pub const Camera2D = extern struct { offset: Vector2 = .{}, target: Vector2 = .{}, rotation: f32 = 0, zoom: f32 = 0 };
pub const Camera = Camera3D;
pub const Camera3D = extern struct { position: Vector3 = .{}, target: Vector3 = .{}, up: Vector3 = .{}, fovy: f32 = 0, projection: CameraProjection = .perspective };
pub const Mesh = extern struct {
    vertexCount: c_int = 0,
    triangleCount: c_int = 0,
    vertices: [*c]f32 = null,
    texcoords: [*c]f32 = null,
    texcoords2: [*c]f32 = null,
    normals: [*c]f32 = null,
    tangents: [*c]f32 = null,
    colors: [*c]u8 = null,
    indices: [*c]c_ushort = null,
    animVertices: [*c]f32 = null,
    animNormals: [*c]f32 = null,
    boneIds: [*c]u8 = null,
    boneWeights: [*c]f32 = null,
    boneMatrices: [*c]Matrix = null,
    boneCount: c_int = 0,
    vaoId: c_uint = 0,
    vboId: [*c]c_uint = null,
};
pub const Shader = extern struct { id: c_uint = 0, locs: [*c]c_int = null };
pub const MaterialMap = extern struct { texture: Texture2D = .{}, color: Color = .{}, value: f32 = 0 };
pub const Material = extern struct { shader: Shader = .{}, maps: [*c]MaterialMap = null, params: [4]f32 = .{} };
pub const Transform = extern struct { translation: Vector3 = .{}, rotation: Quaternion = .{}, scale: Vector3 = .{} };
pub const BoneInfo = extern struct { name: [32]u8 = .{}, parent: c_int = 0 };
pub const Model = extern struct { transform: Matrix = .{}, meshCount: c_int = 0, materialCount: c_int = 0, meshes: [*c]Mesh = null, materials: [*c]Material = null, meshMaterial: [*c]c_int = null, boneCount: c_int = 0, bones: [*c]BoneInfo = null, bindPose: [*c]Transform = null };
pub const ModelAnimation = extern struct { boneCount: c_int = 0, frameCount: c_int = 0, bones: [*c]BoneInfo = null, framePoses: [*c][*c]Transform = null, name: [32]u8 = .{} };
pub const Ray = extern struct { position: Vector3 = .{}, direction: Vector3 = .{} };
pub const RayCollision = extern struct { hit: bool = false, distance: f32 = 0, point: Vector3 = .{}, normal: Vector3 = .{} };
pub const BoundingBox = extern struct { min: Vector3 = .{}, max: Vector3 = .{} };
pub const Wave = extern struct { frameCount: c_uint = 0, sampleRate: c_uint = 0, sampleSize: c_uint = 0, channels: c_uint = 0, data: ?*anyopaque = null };
pub const rAudioBuffer = opaque {};
pub const rAudioProcessor = opaque {};
pub const AudioStream = extern struct { buffer: ?*rAudioBuffer = null, processor: ?*rAudioProcessor = null, sampleRate: c_uint = 0, sampleSize: c_uint = 0, channels: c_uint = 0 };
pub const AudioCallback = ?*const fn (?*anyopaque, c_uint) callconv(.c) void;
pub const Sound = extern struct { stream: AudioStream = .{}, frameCount: c_uint = 0 };
pub const Music = extern struct { stream: AudioStream = .{}, frameCount: c_uint = 0, looping: bool = false, ctxType: c_int = 0, ctxData: ?*anyopaque = null };
pub const VrDeviceInfo = extern struct { hResolution: c_int = 0, vResolution: c_int = 0, hScreenSize: f32 = 0, vScreenSize: f32 = 0, eyeToScreenDistance: f32 = 0, lensSeparationDistance: f32 = 0, interpupillaryDistance: f32 = 0, lensDistortionValues: [4]f32 = .{}, chromaAbCorrection: [4]f32 = .{} };
pub const VrStereoConfig = extern struct { projection: [2]Matrix = .{}, viewOffset: [2]Matrix = .{}, leftLensCenter: [2]f32 = .{}, rightLensCenter: [2]f32 = .{}, leftScreenCenter: [2]f32 = .{}, rightScreenCenter: [2]f32 = .{}, scale: [2]f32 = .{}, scaleIn: [2]f32 = .{} };
pub const FilePathList = extern struct { capacity: c_uint = 0, count: c_uint = 0, paths: [*c][*c]u8 = null };
pub const AutomationEvent = extern struct { frame: c_uint = 0, type: c_uint = 0, params: [4]c_int = .{} };
pub const AutomationEventList = extern struct { capacity: c_uint = 0, count: c_uint = 0, events: [*c]AutomationEvent = null };
pub const TraceLogCallback = ?*const fn (c_int, [*c]const u8, [*c]u8) callconv(.c) void;
pub const LoadFileDataCallback = ?*const fn ([*c]const u8, [*c]c_int) callconv(.c) [*c]u8;
pub const SaveFileDataCallback = ?*const fn ([*c]const u8, ?*anyopaque, c_int) callconv(.c) bool;
pub const LoadFileTextCallback = ?*const fn ([*c]const u8) callconv(.c) [*c]u8;
pub const SaveFileTextCallback = ?*const fn ([*c]const u8, [*c]u8) callconv(.c) bool;
pub const VertexBuffer = extern struct { elementCount: c_int = 0, vertices: [*c]f32 = null, texcoords: [*c]f32 = null, normals: [*c]f32 = null, colors: [*c]u8 = null, indices: [*c]c_uint = null, vaoId: c_uint = 0, vboId: [5]c_uint = .{} };
pub const DrawCall = extern struct { mode: c_int = 0, vertexCount: c_int = 0, vertexAlignment: c_int = 0, textureId: c_uint = 0 };
pub const RenderBatch = extern struct { bufferCount: c_int = 0, currentBuffer: c_int = 0, vertexBuffer: [*c]VertexBuffer = null, draws: [*c]DrawCall = null, drawCounter: c_int = 0, currentDepth: f32 = 0 };

pub const Rectangle = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
    pub fn from(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return .{ .x = x, .y = y, .width = width, .height = height };
    }
    pub const Modifier = struct {
        width: ?f32 = null,
        height: ?f32 = null,
        x: ?f32 = null,
        y: ?f32 = null,
    };
    pub fn with(self: Rectangle, mod: Modifier) Rectangle {
        return .{
            .x = mod.x orelse self.x,
            .y = mod.y orelse self.y,
            .width = mod.width orelse self.width,
            .height = mod.height orelse self.height,
        };
    }
    pub fn resize(self: Rectangle, width: f32, height: f32) Rectangle {
        return .{ .x = self.x, .y = self.y, .width = width, .height = height };
    }
    pub fn translate(self: Rectangle, dx: f32, dy: f32) Rectangle {
        return .{ .x = self.x + dx, .y = self.y + dy, .width = self.width, .height = self.height };
    }
};

pub const TextureWrap = enum(c_int) { repeat = 0, clamp = 1, mirror_repeat = 2, mirror_clamp = 3 };
pub const CubemapLayout = enum(c_int) { auto_detect = 0, line_vertical = 1, line_horizontal = 2, cross_three_by_four = 3, cross_four_by_three = 4 };
pub const FontType = enum(c_int) { default = 0, bitmap = 1, sdf = 2 };
pub const Gesture = enum(c_int) { none = 0, tap = 1, double_tap = 2, hold = 4, drag = 8, swipe_right = 16, swipe_left = 32, swipe_up = 64, swipe_down = 128, pinch_in = 256, pinch_out = 512 };
pub const CameraMode = enum(c_int) { custom = 0, free = 1, orbital = 2, first_person = 3, third_person = 4 };
pub const NPatchLayout = enum(c_int) { nine_patch = 0, three_patch_vertical = 1, three_patch_horizontal = 2 };
// END TYPES

// ENUMS
pub const GlVersion = enum(c_int) {
    // zig fmt: off
    gl11 = 1, gl21 = 2, gl33 = 3,
    gl43 = 4, glEs20 = 5, glEs30 = 6,
    // zig fmt: on
};

pub const TraceLogLevel = enum(c_int) {
    // zig fmt: off
    all = 0, trace = 1, debug = 2,
    info = 3, warning = 4, @"error" = 5,
    fatal = 6, none = 7,
    // zig fmt: on
};

pub const PixelFormat = enum(c_int) {
    // zig fmt: off
    uncompressed_grayscale = 1, uncompressed_gray_alpha = 2, uncompressed_r5g6b5 = 3,
    uncompressed_r8g8b8 = 4, uncompressed_r5g5b5a1 = 5, uncompressed_r4g4b4a4 = 6,
    uncompressed_r8g8b8a8 = 7, uncompressed_r32 = 8, uncompressed_r32g32b32 = 9,
    uncompressed_r32g32b32a32 = 10, uncompressed_r16 = 11, uncompressed_r16g16b16 = 12,
    uncompressed_r16g16b16a16 = 13, compressed_dxt1_rgb = 14, compressed_dxt1_rgba = 15,
    compressed_dxt3_rgba = 16, compressed_dxt5_rgba = 17, compressed_etc1_rgb = 18,
    compressed_etc2_rgb = 19, compressed_etc2_eac_rgba = 20, compressed_pvrt_rgb = 21,
    compressed_pvrt_rgba = 22, compressed_astc_4x4_rgba = 23, compressed_astc_8x8_rgba = 24,
    // zig fmt: on
};

pub const TextureFilter = enum(c_int) {
    // zig fmt: off
    point = 0, bilinear = 1, trilinear = 2,
    anisotropic_4x = 3, anisotropic_8x = 4, anisotropic_16x = 5,
    // zig fmt: on
};

pub const BlendMode = enum(c_int) {
    // zig fmt: off
    alpha = 0, additive = 1, multiplied = 2, add_colors = 3,
    subtract_colors = 4, alpha_premultiply = 5, custom = 6, custom_separate = 7,
    // zig fmt: on
};

pub const ShaderLocationIndex = enum(c_int) {
    // zig fmt: off
    vertex_position = 0, vertex_texcoord01 = 1, vertex_texcoord02 = 2,
    vertex_normal = 3, vertex_tangent = 4, vertex_color = 5,
    matrix_mvp = 6, matrix_view = 7, matrix_projection = 8,
    matrix_model = 9, matrix_normal = 10, vector_view = 11,
    color_diffuse = 12, color_specular = 13, color_ambient = 14,
    map_albedo = 15, map_metalness = 16, map_normal = 17,
    map_roughness = 18, map_occlusion = 19, map_emission = 20,
    map_height = 21, map_cubemap = 22, map_irradiance = 23,
    map_prefilter = 24, map_brdf = 25,
    // zig fmt: on
};

pub const ShaderUniformDataType = enum(c_int) {
    // zig fmt: off
    float = 0, vec2 = 1, vec3 = 2, vec4 = 3, int = 4, ivec2 = 5,
    ivec3 = 6, ivec4 = 7, uint = 8, uivec2 = 9, uivec3 = 10, uivec4 = 11,
    sampler2d = 12,
    // zig fmt: on
};

pub const ShaderAttributeDataType = enum(c_int) {
    // zig fmt: off
    float = 0, vec2 = 1, vec3 = 2, vec4 = 3,
    // zig fmt: on
};

pub const FramebufferAttachType = enum(c_int) {
    // zig fmt: off
    color_channel0 = 0, color_channel1 = 1, color_channel2 = 2,
    color_channel3 = 3, color_channel4 = 4, color_channel5 = 5,
    color_channel6 = 6, color_channel7 = 7, depth = 100, stencil = 200,
    // zig fmt: on
};

pub const FramebufferAttachTextureType = enum(c_int) {
    // zig fmt: off
    cubemap_positive_x = 0, cubemap_negative_x = 1, cubemap_positive_y = 2,
    cubemap_negative_y = 3, cubemap_positive_z = 4, cubemap_negative_z = 5,
    texture2d = 100, renderbuffer = 200,
    // zig fmt: on
};

pub const CullMode = enum(c_int) { front = 0, back = 1 };

pub const Icon = enum(c_int) {
    // zig fmt: off
    none = 0, folder_file_open = 1, file_save_classic = 2, folder_open = 3, folder_save = 4, file_open = 5,
    file_save = 6, file_export = 7, file_add = 8, file_delete = 9, filetype_text = 10, filetype_audio = 11,
    filetype_image = 12, filetype_play = 13, filetype_video = 14, filetype_info = 15, file_copy = 16, file_cut = 17,
    file_paste = 18, cursor_hand = 19, cursor_pointer = 20, cursor_classic = 21, pencil = 22, pencil_big = 23,
    brush_classic = 24, brush_painter = 25, water_drop = 26, color_picker = 27, rubber = 28, color_bucket = 29,
    text_t = 30, text_a = 31, scale = 32, resize = 33, filter_point = 34, filter_bilinear = 35,
    crop = 36, crop_alpha = 37, square_toggle = 38, symmetry = 39, symmetry_horizontal = 40, symmetry_vertical = 41,
    lens = 42, lens_big = 43, eye_on = 44, eye_off = 45, filter_top = 46, filter = 47,
    target_point = 48, target_small = 49, target_big = 50, target_move = 51, cursor_move = 52, cursor_scale = 53,
    cursor_scale_right = 54, cursor_scale_left = 55, undo = 56, redo = 57, reredo = 58, mutate = 59,
    rotate = 60, repeat = 61, shuffle = 62, emptybox = 63, target = 64, target_small_fill = 65,
    target_big_fill = 66, target_move_fill = 67, cursor_move_fill = 68, cursor_scale_fill = 69, cursor_scale_right_fill = 70, cursor_scale_left_fill = 71,
    undo_fill = 72, redo_fill = 73, reredo_fill = 74, mutate_fill = 75, rotate_fill = 76, repeat_fill = 77,
    shuffle_fill = 78, emptybox_small = 79, box = 80, box_top = 81, box_top_right = 82, box_right = 83,
    box_bottom_right = 84, box_bottom = 85, box_bottom_left = 86, box_left = 87, box_top_left = 88, box_center = 89,
    box_circle_mask = 90, pot = 91, alpha_multiply = 92, alpha_clear = 93, dithering = 94, mipmaps = 95,
    box_grid = 96, grid = 97, box_corners_small = 98, box_corners_big = 99, four_boxes = 100, grid_fill = 101,
    box_multisize = 102, zoom_small = 103, zoom_medium = 104, zoom_big = 105, zoom_all = 106, zoom_center = 107,
    box_dots_small = 108, box_dots_big = 109, box_concentric = 110, box_grid_big = 111, ok_tick = 112, cross = 113,
    arrow_left = 114, arrow_right = 115, arrow_down = 116, arrow_up = 117, arrow_left_fill = 118, arrow_right_fill = 119,
    arrow_down_fill = 120, arrow_up_fill = 121, audio = 122, fx = 123, wave = 124, wave_sinus = 125,
    wave_square = 126, wave_triangular = 127, cross_small = 128, player_previous = 129, player_play_back = 130, player_play = 131,
    player_pause = 132, player_stop = 133, player_next = 134, player_record = 135, magnet = 136, lock_close = 137,
    lock_open = 138, clock = 139, tools = 140, gear = 141, gear_big = 142, bin = 143,
    hand_pointer = 144, laser = 145, coin = 146, explosion = 147, @"1up" = 148, player = 149,
    player_jump = 150, key = 151, demon = 152, text_popup = 153, gear_ex = 154, crack = 155,
    crack_points = 156, star = 157, door = 158, exit = 159, mode_2d = 160, mode_3d = 161,
    cube = 162, cube_face_top = 163, cube_face_left = 164, cube_face_front = 165, cube_face_bottom = 166, cube_face_right = 167,
    cube_face_back = 168, camera = 169, special = 170, link_net = 171, link_boxes = 172, link_multi = 173,
    link = 174, link_broke = 175, text_notes = 176, notebook = 177, suitcase = 178, suitcase_zip = 179,
    mailbox = 180, monitor = 181, printer = 182, photo_camera = 183, photo_camera_flash = 184, house = 185,
    heart = 186, corner = 187, vertical_bars = 188, vertical_bars_fill = 189, life_bars = 190, info = 191,
    crossline = 192, help = 193, filetype_alpha = 194, filetype_home = 195, layers_visible = 196, layers = 197,
    window = 198, hidpi = 199, filetype_binary = 200, hex = 201, shield = 202, file_new = 203,
    folder_add = 204, alarm = 205, cpu = 206, rom = 207, step_over = 208, step_into = 209,
    step_out = 210, restart = 211, breakpoint_on = 212, breakpoint_off = 213, burger_menu = 214, case_sensitive = 215,
    reg_exp = 216, folder = 217, file = 218, sand_timer = 219, warning = 220, help_box = 221,
    info_box = 222, priority = 223, layers_iso = 224, layers2 = 225, mlayers = 226, maps = 227,
    hot = 228, @"229" = 229, @"230" = 230, @"231" = 231, @"232" = 232, @"233" = 233,
    @"234" = 234, @"235" = 235, @"236" = 236, @"237" = 237, @"238" = 238, @"239" = 239,
    @"240" = 240, @"241" = 241, @"242" = 242, @"243" = 243, @"244" = 244, @"245" = 245,
    @"246" = 246, @"247" = 247, @"248" = 248, @"249" = 249, @"250" = 250, @"251" = 251,
    @"252" = 252, @"253" = 253, @"254" = 254, @"255" = 255, 
    // zig fmt: on
};

pub const ConfigFlags = packed struct(c_int) {
    _padding: u1 = 0, // 1
    full_screen: bool = false, // 2
    window_resizable: bool = false, // 4
    window_undecorated: bool = false, // 8
    window_transparent: bool = false, // 16
    msaa_4x_hint: bool = false, // 32
    vsync_hint: bool = false, // 64
    window_hidden: bool = false, // 128
    window_always_run: bool = false, // 256
    window_minimized: bool = false, // 512
    window_maximized: bool = false, // 1024
    window_unfocused: bool = false, // 2048
    window_topmost: bool = false, // 4096
    window_highdpi: bool = false, // 8192
    window_mouse_passthrough: bool = false, // 16384
    borderless_windowed_mode: bool = false, // 32768
    interlaced_hint: bool = false, // 65536
    _padding2: u15 = 0,
    comptime {
        std.debug.assert(@sizeOf(ConfigFlags) == 4);
        std.debug.assert(@as(c_int, @bitCast(ConfigFlags{ .full_screen = true })) == 2);
    }
};

pub const Key = enum(c_int) {
    // zig fmt: off
NULL = 0, APOSTROPHE = 39, COMMA = 44, MINUS = 45, PERIOD = 46, SLASH = 47, 
ZERO = 48, ONE = 49, TWO = 50, THREE = 51, FOUR = 52, FIVE = 53, SIX = 54, 
SEVEN = 55, EIGHT = 56, NINE = 57, SEMICOLON = 59, EQUAL = 61,
A = 65, B = 66, C = 67, D = 68, E = 69, F = 70, G = 71, H = 72, I = 73, J = 74, K = 75, L = 76, M = 77, 
N = 78, O = 79, P = 80, Q = 81, R = 82, S = 83, T = 84, U = 85, V = 86, W = 87, X = 88, Y = 89, Z = 90, 
LEFT_BRACKET = 91, BACKSLASH = 92, RIGHT_BRACKET = 93, GRAVE = 96, SPACE = 32, ESCAPE = 256,
ENTER = 257, TAB = 258, BACKSPACE = 259, INSERT = 260, DELETE = 261, RIGHT = 262,
LEFT = 263, DOWN = 264, UP = 265, PAGE_UP = 266, PAGE_DOWN = 267, HOME = 268,
END = 269, CAPS_LOCK = 280, SCROLL_LOCK = 281, NUM_LOCK = 282, PRINT_SCREEN = 283, PAUSE = 284,
F1 = 290, F2 = 291, F3 = 292, F4 = 293, F5 = 294, F6 = 295,
F7 = 296, F8 = 297, F9 = 298, F10 = 299, F11 = 300, F12 = 301,
LEFT_SHIFT = 340, LEFT_CONTROL = 341, LEFT_ALT = 342, LEFT_SUPER = 343, 
RIGHT_SHIFT = 344, RIGHT_CONTROL = 345, RIGHT_ALT = 346, RIGHT_SUPER = 347, 
KB_MENU = 348, 
KP_0 = 320, KP_1 = 321, KP_2 = 322, 
KP_3 = 323, KP_4 = 324, KP_5 = 325, 
KP_6 = 326, KP_7 = 327, KP_8 = 328, 
KP_9 = 329, KP_DECIMAL = 330, 
KP_DIVIDE = 331, KP_MULTIPLY = 332, KP_SUBTRACT = 333, KP_ADD = 334,
KP_ENTER = 335, KP_EQUAL = 336,
BACK = 4, MENU = 5, VOLUME_UP = 24, VOLUME_DOWN = 25,
// zig fmt: on
};

pub const MouseButton = enum(c_int) {
    // zig fmt: off
    left = 0, right = 1, middle = 2, side = 3, extra = 4, forward = 5, back = 6,
    // zig fmt: on
};

pub const MouseCursor = enum(c_int) {
    // zig fmt: off
    default = 0, arrow = 1, ibeam = 2, crosshair = 3, pointing_hand = 4, resize_ew = 5, resize_ns = 6,
    resize_nwse = 7, resize_nesw = 8, resize_all = 9, not_allowed = 10,
    // zig fmt: on
};

pub const GamepadButton = enum(c_int) {
    // zig fmt: off
    null = 0, left_face_up = 1, left_face_right = 2, left_face_down = 3, left_face_left = 4,
    right_face_up = 5, right_face_right = 6, right_face_down = 7, right_face_left = 8,
    left_trigger_1 = 9, left_trigger_2 = 10, right_trigger_1 = 11, right_trigger_2 = 12,
    middle_left = 13, middle = 14, middle_right = 15, left_thumb = 16, right_thumb = 17,
    // zig fmt: on
};

pub const GamepadAxis = enum(c_int) {
    // zig fmt: off
    left_x = 0, left_y = 1, right_x = 2, right_y = 3, left_trigger = 4, right_trigger = 5,
    // zig fmt: on
};

pub const MaterialMapIndex = enum(c_int) {
    // zig fmt: off
    albedo = 0, metalness = 1, normal = 2, roughness = 3, occlusion = 4, emission = 5, 
    height = 6, cubemap = 7, irradiance = 8, prefilter = 9, brdf = 10,
    // zig fmt: on
};
// END ENUMS
