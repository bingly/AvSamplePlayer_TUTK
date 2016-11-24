#ifndef AVCODEC_H
#define AVCODEC_H

#include "common.h"

//the following defines might change, so dont expect compatibility if u use them
#define MB_TYPE_INTRA4x4   0x0001
#define MB_TYPE_INTRA16x16 0x0002 //FIXME h264 specific
#define MB_TYPE_INTRA_PCM  0x0004 //FIXME h264 specific
#define MB_TYPE_16x16      0x0008
#define MB_TYPE_16x8       0x0010
#define MB_TYPE_8x16       0x0020
#define MB_TYPE_8x8        0x0040
#define MB_TYPE_INTERLACED 0x0080
#define MB_TYPE_DIRECT2     0x0100 //FIXME
#define MB_TYPE_ACPRED     0x0200
#define MB_TYPE_GMC        0x0400
#define MB_TYPE_SKIP       0x0800
#define MB_TYPE_P0L0       0x1000
#define MB_TYPE_P1L0       0x2000
#define MB_TYPE_P0L1       0x4000
#define MB_TYPE_P1L1       0x8000
#define MB_TYPE_L0         (MB_TYPE_P0L0 | MB_TYPE_P1L0)
#define MB_TYPE_L1         (MB_TYPE_P0L1 | MB_TYPE_P1L1)
#define MB_TYPE_L0L1       (MB_TYPE_L0   | MB_TYPE_L1)
#define MB_TYPE_QUANT      0x00010000
#define MB_TYPE_CBP        0x00020000
//Note bits 24-31 are reserved for codec specific use (h264 ref0, mpeg1 0mv, ...)

typedef struct AVFrame 
{
    uint8_t *data[4];
    int linesize[4];
    uint8_t *base[4];
    int key_frame;
    int pict_type;
    int reference;
    int8_t *qscale_table;
    int16_t (*motion_val[2])[2];
    uint32_t *mb_type;
}AVFrame;

typedef struct AVCodecContext
{
    int width, height;

    int hurry_up;

    void *priv_data;

    AVFrame *coded_frame;

    int internal_buffer_count;

    void *internal_buffer;
}AVCodecContext;

int decode_init(AVCodecContext *avctx);
int decode_frame(AVCodecContext *avctx, void *data, int *data_size,uint8_t *buf, int buf_size);
int decode_end(AVCodecContext *avctx);

void avcodec_get_context_defaults(AVCodecContext *s);
AVCodecContext *avcodec_alloc_context(void);
void avcodec_get_frame_defaults(AVFrame *pic);
AVFrame *avcodec_alloc_frame(void);

int avcodec_default_get_buffer(AVCodecContext *s, AVFrame *pic);
void avcodec_default_release_buffer(AVCodecContext *s, AVFrame *pic);
void avcodec_default_free_buffers(AVCodecContext *s);

int avcodec_open(AVCodecContext *avctx);
int avcodec_close(AVCodecContext *avctx);

/* memory */
void *av_malloc(unsigned int size);
void *av_mallocz(unsigned int size);
void *av_realloc(void *ptr, unsigned int size);
void av_free(void *ptr);
char *av_strdup(const char *s);
void av_freep(void *ptr);
void *av_fast_realloc(void *ptr, int *size, int min_size);

#endif
