#include "miniaudio.h"
#include <string.h>

static ma_context context;
static ma_device device;
static int context_ready;
static int device_ready;
static void (*on_frames)(const float *, unsigned int);
enum { device_capacity = 32, selected_device = -2 };
static ma_device_id listed_ids[2][device_capacity];
static unsigned int listed_count[2];
static ma_device_id selected_id;
static int selected_mode;
static int selection_ready;

int zigscene_capture_select(int mode, int index) {
    if (mode < 0 || mode > 1) return 0;
    if (index == -1) { selection_ready = 0; return 1; }
    if (index < 0 || (unsigned int)index >= listed_count[mode]) return 0;
    selected_id = listed_ids[mode][index];
    selected_mode = mode;
    selection_ready = 1;
    return 1;
}

// -1 = automatic, -2 = selected device is no longer present.
int zigscene_capture_selected_index(int mode) {
    if (!selection_ready || selected_mode != mode) return -1;
    for (unsigned int i = 0; i < listed_count[mode]; ++i)
        if (ma_device_id_equal(&selected_id, &listed_ids[mode][i])) return (int)i;
    return -2;
}

static void data_callback(ma_device *unused, void *output, const void *input, ma_uint32 count) {
    (void)unused;
    (void)output;
    if (input && on_frames) on_frames((const float *)input, count);
}

// mode: 0 = input device, 1 = system playback. index: -1 = default/auto.
int zigscene_capture_start(int mode, int index, unsigned int channels, unsigned int sample_rate, void (*callback)(const float *, unsigned int)) {
    if (device_ready) return -1;
    const int use_selected = index == selected_device;
    if (use_selected && (!selection_ready || selected_mode != mode)) return MA_NO_DEVICE;
    if (use_selected) index = -1;
    ma_result result = ma_context_init(NULL, 0, NULL, &context);
    if (result != MA_SUCCESS) return result;
    context_ready = 1;

    ma_device_info *playback = NULL, *capture = NULL;
    ma_uint32 playback_count = 0, capture_count = 0;
    result = ma_context_get_devices(&context, &playback, &playback_count, &capture, &capture_count);
    if (result != MA_SUCCESS) goto fail;

#if defined(_WIN32)
    ma_device_config config = ma_device_config_init(mode ? ma_device_type_loopback : ma_device_type_capture);
    if (mode && index >= 0) {
        if ((ma_uint32)index >= playback_count) { result = MA_INVALID_ARGS; goto fail; }
        config.capture.pDeviceID = &playback[index].id;
    }
#else
    ma_device_config config = ma_device_config_init(ma_device_type_capture);
    if (mode && index < 0 && !use_selected) {
        for (ma_uint32 i = 0; i < capture_count; ++i) {
            if (strstr(capture[i].name, "monitor") || strstr(capture[i].name, "Monitor")) {
                index = (int)i;
                break;
            }
        }
        if (index < 0) { result = MA_NO_DEVICE; goto fail; }
    }
#endif
    if (index >= 0 && !mode) {
        if ((ma_uint32)index >= capture_count) { result = MA_INVALID_ARGS; goto fail; }
        config.capture.pDeviceID = &capture[index].id;
    }
#if !defined(_WIN32)
    if (index >= 0 && mode) {
        if ((ma_uint32)index >= capture_count) { result = MA_INVALID_ARGS; goto fail; }
        config.capture.pDeviceID = &capture[index].id;
    }
#endif
    if (use_selected) config.capture.pDeviceID = &selected_id;
    config.capture.format = ma_format_f32;
    config.capture.channels = channels;
    config.sampleRate = sample_rate;
    config.dataCallback = data_callback;
    on_frames = callback;
    result = ma_device_init(&context, &config, &device);
    if (result != MA_SUCCESS) goto fail;
    device_ready = 1;
    result = ma_device_start(&device);
    if (result == MA_SUCCESS) return 0;
    ma_device_uninit(&device);
    device_ready = 0;
fail:
    ma_context_uninit(&context);
    context_ready = 0;
    on_frames = NULL;
    return result;
}

void zigscene_capture_stop(void) {
    if (device_ready) {
        ma_device_uninit(&device);
        device_ready = 0;
    }
    if (context_ready) {
        ma_context_uninit(&context);
        context_ready = 0;
    }
    on_frames = NULL;
}

// Copies NUL-terminated device names into count fixed-size entries.
unsigned int zigscene_capture_list(int mode, char *names, unsigned int capacity, unsigned int stride) {
    if (mode < 0 || mode > 1 || stride == 0) return 0;
    listed_count[mode] = 0;
    ma_context temp;
    if (ma_context_init(NULL, 0, NULL, &temp) != MA_SUCCESS) return 0;
    ma_device_info *playback = NULL, *capture = NULL;
    ma_uint32 playback_count = 0, capture_count = 0;
    if (ma_context_get_devices(&temp, &playback, &playback_count, &capture, &capture_count) != MA_SUCCESS) {
        ma_context_uninit(&temp);
        return 0;
    }
#if defined(_WIN32)
    ma_device_info *devices = mode ? playback : capture;
    ma_uint32 count = mode ? playback_count : capture_count;
#else
    (void)mode;
    ma_device_info *devices = capture;
    ma_uint32 count = capture_count;
#endif
    if (count > capacity) count = capacity;
    if (count > device_capacity) count = device_capacity;
    for (ma_uint32 i = 0; i < count; ++i) {
        listed_ids[mode][i] = devices[i].id;
        strncpy(names + i * stride, devices[i].name, stride - 1);
        names[i * stride + stride - 1] = '\0';
    }
    listed_count[mode] = count;
    ma_context_uninit(&temp);
    return count;
}

#ifdef ZIGSCENE_CAPTURE_TEST
// No hardware access: exercise the same selection state used by the picker.
int zigscene_test_capture_selection(void) {
    int result = 0;
    ma_device_id a = {0}, b = {0};
    a.nullbackend = 10;
    b.nullbackend = 20;
    listed_ids[1][0] = a;
    listed_ids[1][1] = b;
    listed_count[1] = 2;
    selection_ready = 0;
    if (zigscene_capture_selected_index(1) != -1) { result = 1; goto done; }
    if (!zigscene_capture_select(1, 1)) { result = 2; goto done; }
    // Refresh reorders the devices. Selection must follow B, not the old index 1.
    listed_ids[1][0] = b;
    listed_ids[1][1] = a;
    if (zigscene_capture_selected_index(1) != 0) { result = 3; goto done; }
    if (!ma_device_id_equal(&selected_id, &b)) { result = 4; goto done; }
    // A missing device must not silently select another input or the default.
    listed_ids[1][0] = a;
    listed_count[1] = 1;
    if (zigscene_capture_selected_index(1) != -2) { result = 5; goto done; }
    if (zigscene_capture_select(1, 99)) { result = 6; goto done; }
    if (!ma_device_id_equal(&selected_id, &b)) { result = 7; goto done; }
    listed_ids[1][1] = b;
    listed_count[1] = 2;
    if (zigscene_capture_selected_index(1) != 1) { result = 8; goto done; }
    // Input and playback device lists must not share an index selection.
    if (zigscene_capture_selected_index(0) != -1) { result = 9; goto done; }
    if (!zigscene_capture_select(0, -1) || zigscene_capture_selected_index(1) != -1) result = 10;
done:
    selection_ready = 0;
    listed_count[0] = listed_count[1] = 0;
    return result;
}
#endif
