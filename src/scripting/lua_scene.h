#ifndef ZIGSCENE_LUA_SCENE_H
#define ZIGSCENE_LUA_SCENE_H
#include <stddef.h>
#include <stdint.h>
#define ZS_MAX_SETTINGS 128
#define ZS_MAX_PARAMS 16
#define ZS_MAX_COMMANDS 4096
#define ZS_SOURCE_LIMIT (1024 * 1024)
#define ZS_MEMORY_LIMIT (16 * 1024 * 1024)

typedef struct ZsScene ZsScene;
typedef struct {
    const char *name;
    double value, min, max;
    int boolean;
} ZsSetting;
typedef struct {
    char id[48], label[64];
    float value, min, max;
} ZsParam;
typedef struct {
    float width, height, time, dt;
    float rms, energy, pulse, progress;
    int beat, playing, capturing;
    float mouse_x, mouse_y, wheel;
    int mouse_down;
    const float *samples, *spectrum;
    size_t sample_count, spectrum_count;
} ZsFrame;
typedef enum {
    ZS_CLEAR, ZS_LINE, ZS_CIRCLE, ZS_RING, ZS_RECT, ZS_RECT_LINES,
    ZS_TRIANGLE, ZS_TEXT, ZS_LINE3D, ZS_SPHERE, ZS_CUBE, ZS_CAMERA
} ZsCommandKind;
typedef struct {
    int kind;
    float values[12];
    unsigned char color[4];
    char text[256];
} ZsCommand;

ZsScene *zs_create(const char *source, size_t length, const char *name,
    const ZsSetting *settings, size_t count, const ZsFrame *frame,
    const ZsScene *previous, char *error, size_t error_size);
void zs_destroy(ZsScene *scene);
int zs_step(ZsScene *scene, const ZsSetting *settings, const ZsFrame *frame, char *error, size_t error_size);
const char *zs_name(const ZsScene *scene);
int zs_overlay(const ZsScene *scene);
size_t zs_commands(const ZsScene *scene, const ZsCommand **commands);
int zs_change(const ZsScene *scene, size_t index, double *value);
size_t zs_params(ZsScene *scene, ZsParam **params);
const char *zs_log(const ZsScene *scene);
#endif
