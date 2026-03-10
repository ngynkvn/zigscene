// Thin wrapper around miniaudio capture device API.
// miniaudio symbols are provided by raylib (raudio.c compiles with MINIAUDIO_IMPLEMENTATION).
#include "miniaudio.h"
#include <string.h>

static ma_device capture_device;
static ma_bool32 capture_initialized = MA_FALSE;

// Callback function pointer set from Zig
static void (*zig_capture_callback)(const float* frames, unsigned int frame_count) = NULL;

static void capture_data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    (void)pDevice;
    (void)pOutput;
    if (zig_capture_callback && pInput) {
        zig_capture_callback((const float*)pInput, frameCount);
    }
}

int capture_init(unsigned int device_index, unsigned int sample_rate, unsigned int channels) {
    if (capture_initialized) return -1;

    ma_device_config config = ma_device_config_init(ma_device_type_capture);
    config.capture.format = ma_format_f32;
    config.capture.channels = channels;
    config.sampleRate = sample_rate;
    config.dataCallback = capture_data_callback;

    // If device_index > 0, enumerate and select that device
    if (device_index > 0) {
        ma_context context;
        if (ma_context_init(NULL, 0, NULL, &context) == MA_SUCCESS) {
            ma_device_info* pCaptureInfos;
            ma_uint32 captureCount;
            if (ma_context_get_devices(&context, NULL, NULL, &pCaptureInfos, &captureCount) == MA_SUCCESS) {
                if (device_index < captureCount) {
                    config.capture.pDeviceID = &pCaptureInfos[device_index].id;
                }
            }
            // Note: context must stay alive while config references pDeviceID,
            // but ma_device_init copies the ID, so this is safe.
            ma_result result = ma_device_init(NULL, &config, &capture_device);
            ma_context_uninit(&context);
            if (result != MA_SUCCESS) return (int)result;
            capture_initialized = MA_TRUE;
            return 0;
        }
        return -2;
    }

    ma_result result = ma_device_init(NULL, &config, &capture_device);
    if (result != MA_SUCCESS) return (int)result;
    capture_initialized = MA_TRUE;
    return 0;
}

void capture_deinit(void) {
    if (!capture_initialized) return;
    ma_device_uninit(&capture_device);
    capture_initialized = MA_FALSE;
}

int capture_start(void) {
    if (!capture_initialized) return -1;
    return (int)ma_device_start(&capture_device);
}

int capture_stop(void) {
    if (!capture_initialized) return -1;
    return (int)ma_device_stop(&capture_device);
}

int capture_is_started(void) {
    if (!capture_initialized) return 0;
    return ma_device_is_started(&capture_device);
}

void capture_set_callback(void (*cb)(const float*, unsigned int)) {
    zig_capture_callback = cb;
}

// Enumerate capture devices. Returns count, fills names/max_name_len buffer.
unsigned int capture_enumerate_devices(char* name_buf, unsigned int name_buf_size, unsigned int max_devices) {
    ma_context context;
    if (ma_context_init(NULL, 0, NULL, &context) != MA_SUCCESS) return 0;

    ma_device_info* pCaptureInfos;
    ma_uint32 captureCount;
    if (ma_context_get_devices(&context, NULL, NULL, &pCaptureInfos, &captureCount) != MA_SUCCESS) {
        ma_context_uninit(&context);
        return 0;
    }

    unsigned int count = captureCount < max_devices ? captureCount : max_devices;
    unsigned int offset = 0;
    unsigned int entry_size = name_buf_size / max_devices;

    for (unsigned int i = 0; i < count && offset + entry_size <= name_buf_size; i++) {
        unsigned int len = (unsigned int)strlen(pCaptureInfos[i].name);
        if (len >= entry_size) len = entry_size - 1;
        memcpy(name_buf + offset, pCaptureInfos[i].name, len);
        name_buf[offset + len] = '\0';
        offset += entry_size;
    }

    ma_context_uninit(&context);
    return count;
}
