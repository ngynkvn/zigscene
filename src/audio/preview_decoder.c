// Reuse raylib's decoder implementations; this translation unit adds no globals.
#include <stdint.h>
#include <stdlib.h>
#include "dr_mp3.h"
#include "dr_wav.h"
#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c"

typedef struct {
    int kind;
    unsigned int channels;
    union { drmp3 mp3; drwav wav; stb_vorbis *ogg; } data;
} PreviewDecoder;

void zigscene_preview_close(PreviewDecoder *decoder) {
    if (!decoder) return;
    if (decoder->kind == 0) drmp3_uninit(&decoder->data.mp3);
    else if (decoder->kind == 1) drwav_uninit(&decoder->data.wav);
    else stb_vorbis_close(decoder->data.ogg);
    free(decoder);
}

// kind: 0 = MP3, 1 = WAV, 2 = OGG. Frame counts and decoding use the same handle.
PreviewDecoder *zigscene_preview_open(const char *path, int kind,
        uint64_t *frames, unsigned int *channels, unsigned int *rate) {
    PreviewDecoder *decoder = calloc(1, sizeof(*decoder));
    if (!decoder) return NULL;
    decoder->kind = kind;
    if (kind == 0) {
        if (!drmp3_init_file(&decoder->data.mp3, path, NULL)) goto fail;
        *frames = drmp3_get_pcm_frame_count(&decoder->data.mp3);
        *channels = decoder->data.mp3.channels;
        *rate = decoder->data.mp3.sampleRate;
        if (!drmp3_seek_to_pcm_frame(&decoder->data.mp3, 0)) goto invalid;
    } else if (kind == 1) {
        if (!drwav_init_file(&decoder->data.wav, path, NULL)) goto fail;
        *frames = decoder->data.wav.totalPCMFrameCount;
        *channels = decoder->data.wav.channels;
        *rate = decoder->data.wav.sampleRate;
    } else if (kind == 2) {
        decoder->data.ogg = stb_vorbis_open_filename(path, NULL, NULL);
        if (!decoder->data.ogg) goto fail;
        stb_vorbis_info info = stb_vorbis_get_info(decoder->data.ogg);
        *frames = stb_vorbis_stream_length_in_samples(decoder->data.ogg);
        *channels = info.channels;
        *rate = info.sample_rate;
        if (!stb_vorbis_seek_start(decoder->data.ogg)) goto invalid;
    } else goto fail;
    if (!*frames || !*rate || !*channels || *channels > 256) goto invalid;
    decoder->channels = *channels;
    return decoder;
invalid:
    zigscene_preview_close(decoder);
    return NULL;
fail:
    free(decoder);
    return NULL;
}

// Fixed scratch space, independent of track length. Preserve LoadWave's 16-bit
// WAV/OGG conversion so the seek preview uses the same samples as before.
unsigned int zigscene_preview_read(PreviewDecoder *decoder, float *out,
        unsigned int sample_capacity) {
    short pcm[8192];
    if (sample_capacity > 8192) sample_capacity = 8192;
    unsigned int requested = sample_capacity / decoder->channels;
    unsigned int frames;
    if (decoder->kind == 0)
        return (unsigned int)drmp3_read_pcm_frames_f32(&decoder->data.mp3, requested, out);
    if (decoder->kind == 1)
        frames = (unsigned int)drwav_read_pcm_frames_s16(&decoder->data.wav, requested, pcm);
    else
        frames = (unsigned int)stb_vorbis_get_samples_short_interleaved(decoder->data.ogg,
                decoder->channels, pcm, requested * decoder->channels);
    for (unsigned int i = 0; i < frames * decoder->channels; ++i) out[i] = pcm[i] / 32768.0f;
    return frames;
}
