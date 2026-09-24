/* Lua errors and allocation failures stay entirely inside this C boundary.
 * Zig receives validated settings and drawing commands, never a Lua longjmp. */
#include "lua_scene.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct ZsScene {
    lua_State *L;
    size_t memory_used, setting_count, command_count, param_count;
    ZsSetting settings[ZS_MAX_SETTINGS];
    unsigned char dirty[ZS_MAX_SETTINGS];
    ZsCommand commands[ZS_MAX_COMMANDS];
    ZsParam params[ZS_MAX_PARAMS];
    char name[96], log[256];
    int overlay, drawing, remaining, context_ref, setup_ref, update_ref, draw_ref;
    const char *source, *chunk_name;
    size_t source_length;
    const ZsFrame *frame;
    const ZsScene *previous;
};

static ZsScene *owner(lua_State *L) { return *(ZsScene **)lua_getextraspace(L); }
static void *limited_alloc(void *ud, void *ptr, size_t old, size_t size) {
    ZsScene *s = ud;
    if (!ptr) old = 0;
    if (!size) { free(ptr); s->memory_used -= old; return NULL; }
    if (size > ZS_MEMORY_LIMIT || s->memory_used - old > ZS_MEMORY_LIMIT - size) return NULL;
    void *result = realloc(ptr, size);
    if (result) s->memory_used = s->memory_used - old + size;
    return result;
}
static void budget(lua_State *L, lua_Debug *ar) {
    (void)ar;
    ZsScene *s = owner(L);
    s->remaining -= 1000;
    if (s->remaining <= 0) {
        /* Keep raising on every instruction, including after a script pcall. */
        lua_sethook(L, budget, LUA_MASKCOUNT, 1);
        luaL_error(L, "scene instruction budget exceeded");
    }
}
static double number(lua_State *L, int index) {
    luaL_checktype(L, index, LUA_TNUMBER);
    double value = lua_tonumber(L, index);
    if (!isfinite(value) || fabs(value) > 1000000) luaL_error(L, "argument %d must be finite and within +/-1000000", index);
    return value;
}
static void copy_string(lua_State *L, int index, char *out, size_t capacity) {
    size_t length;
    luaL_checktype(L, index, LUA_TSTRING);
    const char *str = lua_tolstring(L, index, &length);
    if (length >= capacity || memchr(str, 0, length)) luaL_error(L, "string must be shorter than %d bytes and contain no NUL", (int)capacity);
    memcpy(out, str, length); out[length] = 0;
}
static int setting_index(lua_State *L, const char *path) {
    ZsScene *s = owner(L);
    for (size_t i = 0; i < s->setting_count; i++) if (!strcmp(s->settings[i].name, path)) return (int)i;
    return luaL_error(L, "unknown setting '%s'", path);
}
static void set_value(lua_State *L, int index, int value_index) {
    ZsScene *s = owner(L);
    ZsSetting *setting = &s->settings[index];
    double value;
    if (setting->boolean) { luaL_checktype(L, value_index, LUA_TBOOLEAN); value = lua_toboolean(L, value_index); }
    else value = number(L, value_index);
    if (value < setting->min || value > setting->max) luaL_error(L, "setting '%s' is outside its supported range", setting->name);
    setting->value = value; s->dirty[index] = 1;
}
static int scene_get(lua_State *L) {
    int i = setting_index(L, luaL_checkstring(L, 1));
    ZsSetting *setting = &owner(L)->settings[i];
    if (setting->boolean) lua_pushboolean(L, setting->value != 0); else lua_pushnumber(L, setting->value);
    return 1;
}
static int scene_set(lua_State *L) { set_value(L, setting_index(L, luaL_checkstring(L, 1)), 2); return 0; }
static int scene_param(lua_State *L) {
    ZsScene *s = owner(L);
    const char *id = luaL_checkstring(L, 1);
    for (size_t i = 0; i < s->param_count; i++) if (!strcmp(id, s->params[i].id)) { lua_pushnumber(L, s->params[i].value); return 1; }
    return luaL_error(L, "unknown parameter '%s'", id);
}
static int scene_log(lua_State *L) { copy_string(L, 1, owner(L)->log, sizeof(owner(L)->log)); return 0; }
static void read_config(lua_State *L, int table, const char *prefix, int depth) {
    if (depth > 8) luaL_error(L, "config nesting is too deep");
    table = lua_absindex(L, table);
    lua_pushnil(L);
    while (lua_next(L, table)) {
        luaL_checktype(L, -2, LUA_TSTRING);
        char key[96], path[128];
        copy_string(L, -2, key, sizeof(key));
        int length = snprintf(path, sizeof(path), "%s%s%s", prefix, *prefix ? "." : "", key);
        if (length < 0 || (size_t)length >= sizeof(path)) luaL_error(L, "config path is too long");
        if (lua_istable(L, -1)) read_config(L, -1, path, depth + 1);
        else set_value(L, setting_index(L, path), -1);
        lua_pop(L, 1);
    }
}
static void read_params(lua_State *L, int table) {
    ZsScene *s = owner(L);
    table = lua_absindex(L, table);
    size_t count = lua_rawlen(L, table);
    if (count > ZS_MAX_PARAMS) luaL_error(L, "at most %d parameters are supported", ZS_MAX_PARAMS);
    for (size_t i = 0; i < count; i++) {
        ZsParam *p = &s->params[i];
        lua_rawgeti(L, table, (lua_Integer)i + 1); luaL_checktype(L, -1, LUA_TTABLE);
        lua_getfield(L, -1, "id"); copy_string(L, -1, p->id, sizeof(p->id)); lua_pop(L, 1);
        if (!p->id[0]) luaL_error(L, "parameter id cannot be empty");
        for (size_t j = 0; j < i; j++) if (!strcmp(p->id, s->params[j].id)) luaL_error(L, "duplicate parameter '%s'", p->id);
        lua_getfield(L, -1, "label");
        if (lua_isnil(L, -1)) snprintf(p->label, sizeof(p->label), "%s", p->id); else copy_string(L, -1, p->label, sizeof(p->label));
        lua_pop(L, 1);
        lua_getfield(L, -1, "min"); p->min = (float)number(L, -1); lua_pop(L, 1);
        lua_getfield(L, -1, "max"); p->max = (float)number(L, -1); lua_pop(L, 1);
        lua_getfield(L, -1, "default"); p->value = (float)number(L, -1); lua_pop(L, 1);
        if (p->max <= p->min || p->value < p->min || p->value > p->max) luaL_error(L, "invalid range/default for parameter '%s'", p->id);
        if (s->previous) for (size_t j = 0; j < s->previous->param_count; j++) {
            const ZsParam *old = &s->previous->params[j];
            if (!strcmp(p->id, old->id)) p->value = fmaxf(p->min, fminf(p->max, old->value));
        }
        lua_pop(L, 1);
    }
    s->param_count = count;
}
static void color(lua_State *L, int index, unsigned char out[4]) {
    for (int i = 0; i < 4; i++) out[i] = 255;
    if (lua_isnoneornil(L, index)) return;
    luaL_checktype(L, index, LUA_TTABLE);
    for (int i = 0; i < 4; i++) {
        lua_rawgeti(L, index, i + 1);
        if (i == 3 && lua_isnil(L, -1)) { lua_pop(L, 1); continue; }
        double value = number(L, -1);
        if (value < 0 || value > 1) luaL_error(L, "color components must be in [0, 1]");
        out[i] = (unsigned char)round(value * 255); lua_pop(L, 1);
    }
}
static int hsv(lua_State *L) {
    double h = fmod(number(L, 1), 360); if (h < 0) h += 360;
    double s = number(L, 2), v = number(L, 3), a = lua_isnoneornil(L, 4) ? 1 : number(L, 4);
    if (s < 0 || s > 1 || v < 0 || v > 1 || a < 0 || a > 1) return luaL_error(L, "HSV saturation/value/alpha must be in [0, 1]");
    lua_createtable(L, 4, 0);
    const int offsets[] = {5, 3, 1};
    for (int i = 0; i < 3; i++) {
        double k = fmod(offsets[i] + h / 60, 6);
        double component = v * (1 - s * fmax(0, fmin(1, fmin(k, 4 - k))));
        lua_pushnumber(L, component); lua_rawseti(L, -2, i + 1);
    }
    lua_pushnumber(L, a); lua_rawseti(L, -2, 4); return 1;
}
static void vector(lua_State *L, int table, const char *field, float *out, int optional) {
    lua_getfield(L, table, field);
    if (optional && lua_isnil(L, -1)) { lua_pop(L, 1); return; }
    luaL_checktype(L, -1, LUA_TTABLE);
    for (int i = 0; i < 3; i++) { lua_rawgeti(L, -1, i + 1); out[i] = (float)number(L, -1); lua_pop(L, 1); }
    lua_pop(L, 1);
}
static int emit(lua_State *L) {
    ZsScene *s = owner(L);
    if (!s->drawing) return luaL_error(L, "gfx drawing functions are only available inside draw(ctx)");
    if (s->command_count == ZS_MAX_COMMANDS) return luaL_error(L, "scene drawing command limit exceeded (%d)", ZS_MAX_COMMANDS);
    ZsCommand *command = &s->commands[s->command_count];
    memset(command, 0, sizeof(*command));
    command->kind = (int)lua_tointeger(L, lua_upvalueindex(1));
    int numbers = 0, first = 1, color_arg = 0;
    switch (command->kind) {
        case ZS_CLEAR: color_arg = 1; break;
        case ZS_LINE: numbers = 5; color_arg = 6; break;
        case ZS_CIRCLE: numbers = 3; color_arg = 4; break;
        case ZS_RING: case ZS_RECT: numbers = 4; color_arg = 5; break;
        case ZS_RECT_LINES: numbers = 5; color_arg = 6; break;
        case ZS_TRIANGLE: case ZS_LINE3D: numbers = 6; color_arg = 7; break;
        case ZS_TEXT: copy_string(L, 1, command->text, sizeof(command->text)); first = 2; numbers = 3; color_arg = 5; break;
        case ZS_SPHERE: numbers = 4; color_arg = 5; command->values[10] = lua_toboolean(L, 6); break;
        case ZS_CUBE: numbers = 6; color_arg = 7; command->values[10] = lua_toboolean(L, 8); break;
        case ZS_CAMERA: {
            luaL_checktype(L, 1, LUA_TTABLE);
            command->values[7] = 1;
            vector(L, 1, "position", command->values, 0);
            vector(L, 1, "target", command->values + 3, 0);
            vector(L, 1, "up", command->values + 6, 1);
            lua_getfield(L, 1, "fov"); command->values[9] = lua_isnil(L, -1) ? 45 : (float)number(L, -1); lua_pop(L, 1);
            float *v = command->values;
            float x = v[3] - v[0], y = v[4] - v[1], z = v[5] - v[2];
            float cx = y*v[8]-z*v[7], cy = z*v[6]-x*v[8], cz = x*v[7]-y*v[6];
            if (cx*cx+cy*cy+cz*cz < 0.000001f || v[9] < 1 || v[9] > 150) return luaL_error(L, "invalid camera direction, up vector or field of view");
            s->command_count++; return 0;
        }
    }
    for (int i = 0; i < numbers; i++) command->values[i] = (float)number(L, first + i);
    float *v = command->values;
    if ((command->kind == ZS_LINE && v[4] <= 0) ||
        (command->kind == ZS_CIRCLE && v[2] < 0) ||
        (command->kind == ZS_RING && (v[2] < 0 || v[3] < v[2])) ||
        ((command->kind == ZS_RECT || command->kind == ZS_RECT_LINES) && (v[2] < 0 || v[3] < 0)) ||
        (command->kind == ZS_RECT_LINES && v[4] <= 0) ||
        (command->kind == ZS_TEXT && (v[2] < 1 || v[2] > 512)) ||
        (command->kind == ZS_SPHERE && v[3] < 0) ||
        (command->kind == ZS_CUBE && (v[3] < 0 || v[4] < 0 || v[5] < 0))) return luaL_error(L, "invalid drawing dimensions");
    color(L, color_arg, command->color);
    s->command_count++; return 0;
}
static void field_number(lua_State *L, const char *name, double value) { lua_pushnumber(L, value); lua_setfield(L, -2, name); }
static void field_bool(lua_State *L, const char *name, int value) { lua_pushboolean(L, value); lua_setfield(L, -2, name); }
static void array(lua_State *L, const char *name, const float *values, size_t count) {
    lua_getfield(L, -1, name);
    if (!lua_istable(L, -1)) { lua_pop(L, 1); lua_createtable(L, (int)count, 0); lua_pushvalue(L, -1); lua_setfield(L, -3, name); }
    size_t old = lua_rawlen(L, -1);
    for (size_t i = 0; i < count; i++) { lua_pushnumber(L, values[i]); lua_rawseti(L, -2, (lua_Integer)i + 1); }
    for (size_t i = count; i < old; i++) { lua_pushnil(L); lua_rawseti(L, -2, (lua_Integer)i + 1); }
    lua_pop(L, 1);
}
static void context(lua_State *L) {
    ZsScene *s = owner(L); const ZsFrame *f = s->frame;
    lua_rawgeti(L, LUA_REGISTRYINDEX, s->context_ref);
    field_number(L, "width", f->width); field_number(L, "height", f->height);
    field_number(L, "time", f->time); field_number(L, "dt", f->dt);
    lua_getfield(L, -1, "audio"); luaL_checktype(L, -1, LUA_TTABLE);
    field_number(L, "rms", f->rms); field_number(L, "energy", f->energy); field_number(L, "pulse", f->pulse);
    field_number(L, "progress", f->progress); field_bool(L, "beat", f->beat);
    field_bool(L, "playing", f->playing); field_bool(L, "capturing", f->capturing);
    array(L, "samples", f->samples, f->sample_count); array(L, "spectrum", f->spectrum, f->spectrum_count);
    lua_pop(L, 1);
    lua_getfield(L, -1, "mouse"); luaL_checktype(L, -1, LUA_TTABLE);
    field_number(L, "x", f->mouse_x); field_number(L, "y", f->mouse_y); field_number(L, "wheel", f->wheel);
    field_bool(L, "down", f->mouse_down); lua_pop(L, 2);
}
static void callback(lua_State *L, int ref) {
    if (ref == LUA_REFNIL) return;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
    lua_rawgeti(L, LUA_REGISTRYINDEX, owner(L)->context_ref);
    lua_call(L, 1, 0);
}
static int function_ref(lua_State *L, const char *name) {
    lua_getfield(L, -1, name);
    if (!lua_isnil(L, -1) && !lua_isfunction(L, -1)) luaL_error(L, "'%s' must be a function", name);
    return luaL_ref(L, LUA_REGISTRYINDEX);
}
static int initialize(lua_State *L) {
    ZsScene *s = owner(L);
    luaL_requiref(L, "_G", luaopen_base, 1); lua_pop(L, 1);
    luaL_requiref(L, LUA_MATHLIBNAME, luaopen_math, 1); lua_pop(L, 1);
    luaL_requiref(L, LUA_STRLIBNAME, luaopen_string, 1); lua_pop(L, 1);
    luaL_requiref(L, LUA_TABLIBNAME, luaopen_table, 1); lua_pop(L, 1);
    luaL_requiref(L, LUA_UTF8LIBNAME, luaopen_utf8, 1); lua_pop(L, 1);
    const char *removed[] = { "dofile", "loadfile", "load", "collectgarbage", "print", "setmetatable", "getmetatable" };
    for (size_t i = 0; i < sizeof(removed)/sizeof(*removed); i++) { lua_pushnil(L); lua_setglobal(L, removed[i]); }
    lua_newtable(L);
    const luaL_Reg scene_api[] = {{"get", scene_get}, {"set", scene_set}, {"param", scene_param}, {"log", scene_log}, {NULL, NULL}};
    luaL_setfuncs(L, scene_api, 0); lua_setglobal(L, "scene");
    lua_newtable(L);
    const char *draw_names[] = {"clear", "line", "circle", "ring", "rect", "rect_lines", "triangle", "text", "line3d", "sphere", "cube", "camera"};
    for (int i = 0; i <= ZS_CAMERA; i++) { lua_pushinteger(L, i); lua_pushcclosure(L, emit, 1); lua_setfield(L, -2, draw_names[i]); }
    lua_pushcfunction(L, hsv); lua_setfield(L, -2, "hsv"); lua_setglobal(L, "gfx");
    lua_newtable(L); lua_newtable(L); lua_setfield(L, -2, "audio"); lua_newtable(L); lua_setfield(L, -2, "mouse");
    s->context_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    context(L);
    if (luaL_loadbufferx(L, s->source, s->source_length, s->chunk_name, "t") != LUA_OK) return lua_error(L);
    lua_call(L, 0, 1); luaL_checktype(L, -1, LUA_TTABLE);
    lua_getfield(L, -1, "name"); if (!lua_isnil(L, -1)) copy_string(L, -1, s->name, sizeof(s->name)); lua_pop(L, 1);
    lua_getfield(L, -1, "mode");
    if (!lua_isnil(L, -1)) {
        const char *mode = luaL_checkstring(L, -1);
        if (!strcmp(mode, "overlay")) s->overlay = 1;
        else if (!strcmp(mode, "replace")) s->overlay = 0;
        else return luaL_error(L, "mode must be 'overlay' or 'replace'");
    }
    lua_pop(L, 1);
    lua_getfield(L, -1, "params"); if (!lua_isnil(L, -1)) { luaL_checktype(L, -1, LUA_TTABLE); read_params(L, -1); } lua_pop(L, 1);
    lua_getfield(L, -1, "config"); if (!lua_isnil(L, -1)) { luaL_checktype(L, -1, LUA_TTABLE); read_config(L, -1, "", 0); } lua_pop(L, 1);
    s->setup_ref = function_ref(L, "setup"); s->update_ref = function_ref(L, "update"); s->draw_ref = function_ref(L, "draw");
    lua_pop(L, 1); callback(L, s->setup_ref); return 0;
}
static int step(lua_State *L) {
    ZsScene *s = owner(L); context(L); callback(L, s->update_ref);
    s->drawing = 1; callback(L, s->draw_ref); s->drawing = 0;
    return 0;
}
static int traceback(lua_State *L) {
    const char *message = lua_tostring(L, 1);
    luaL_traceback(L, L, message ? message : "scene raised a non-string error", 1); return 1;
}
static int protected_call(ZsScene *s, lua_CFunction fn, int instructions, char *error, size_t error_size) {
    lua_State *L = s->L;
    lua_settop(L, 0); lua_pushcfunction(L, traceback); lua_pushcfunction(L, fn);
    s->remaining = instructions; lua_sethook(L, budget, LUA_MASKCOUNT, 1000);
    int status = lua_pcall(L, 0, 0, 1);
    lua_sethook(L, NULL, 0, 0); s->drawing = 0;
    if (status != LUA_OK) {
        const char *message = lua_tostring(L, -1);
        snprintf(error, error_size, "%s", message ? message : "Lua memory limit exceeded");
        s->command_count = 0; memset(s->dirty, 0, sizeof(s->dirty));
    }
    lua_settop(L, 0); return status == LUA_OK;
}
ZsScene *zs_create(const char *source, size_t length, const char *name, const ZsSetting *settings, size_t count,
                   const ZsFrame *frame, const ZsScene *previous, char *error, size_t error_size) {
    if (length > ZS_SOURCE_LIMIT || count > ZS_MAX_SETTINGS) { snprintf(error, error_size, "scene source or settings limit exceeded"); return NULL; }
    ZsScene *s = calloc(1, sizeof(*s));
    if (!s) { snprintf(error, error_size, "out of memory creating scene"); return NULL; }
    s->overlay = 1; snprintf(s->name, sizeof(s->name), "%s", name);
    s->source = source; s->source_length = length; s->chunk_name = name; s->frame = frame; s->previous = previous;
    s->setting_count = count; memcpy(s->settings, settings, count * sizeof(*settings));
    s->L = lua_newstate(limited_alloc, s);
    if (!s->L) { snprintf(error, error_size, "out of memory creating Lua state"); free(s); return NULL; }
    *(ZsScene **)lua_getextraspace(s->L) = s;
    if (!protected_call(s, initialize, 500000, error, error_size)) { zs_destroy(s); return NULL; }
    s->source = NULL; s->chunk_name = NULL; s->frame = NULL; s->previous = NULL;
    return s;
}
void zs_destroy(ZsScene *s) { if (s) { if (s->L) lua_close(s->L); free(s); } }
int zs_step(ZsScene *s, const ZsSetting *settings, const ZsFrame *frame, char *error, size_t error_size) {
    memcpy(s->settings, settings, s->setting_count * sizeof(*settings));
    memset(s->dirty, 0, sizeof(s->dirty)); s->command_count = 0; s->frame = frame;
    int ok = protected_call(s, step, 200000, error, error_size); s->frame = NULL; return ok;
}
const char *zs_name(const ZsScene *s) { return s->name; }
int zs_overlay(const ZsScene *s) { return s->overlay; }
size_t zs_commands(const ZsScene *s, const ZsCommand **commands) { *commands = s->commands; return s->command_count; }
int zs_change(const ZsScene *s, size_t index, double *value) { if (index >= s->setting_count || !s->dirty[index]) return 0; *value = s->settings[index].value; return 1; }
size_t zs_params(ZsScene *s, ZsParam **params) { *params = s->params; return s->param_count; }
const char *zs_log(const ZsScene *s) { return s->log; }
