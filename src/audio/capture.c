#include "miniaudio.h"
#include <string.h>

static ma_context context;
static ma_device device;
static int context_ready;
static int device_ready;
static void (*on_frames)(const float *, unsigned int);

static void data_callback(ma_device *unused, void *output, const void *input, ma_uint32 count) {
    (void)unused;
    (void)output;
    if (input && on_frames) on_frames((const float *)input, count);
}

// mode: 0 = input device, 1 = system playback. index: -1 = default/auto.
int zigscene_capture_start(int mode, int index, unsigned int channels, unsigned int sample_rate, void (*callback)(const float *, unsigned int)) {
    if (device_ready) return -1;
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
    if (mode && index < 0) {
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
    for (ma_uint32 i = 0; i < count; ++i) {
        strncpy(names + i * stride, devices[i].name, stride - 1);
        names[i * stride + stride - 1] = '\0';
    }
    ma_context_uninit(&temp);
    return count;
}
