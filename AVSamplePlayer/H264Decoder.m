//
//  H264Decoder.m
//  AVSamplePlayer
//
//  Created by bingcai on 16/7/1.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import "H264Decoder.h"
#import "libavcodec/avcodec.h"
#include <libswscale/swscale.h>
#import <libswresample/swresample.h>
#import "avformat.h"


@interface H264Decoder()
@property CVPixelBufferPoolRef pixelBufferPool;
@end

@implementation H264Decoder {
    
    AVFrame             *_videoFrame;
    AVCodecContext      *_videoCodecCtx;

    struct SwsContext   *_img_convert_ctx;
    AVPicture           _picture;
    AVPacket            _packet;
    BOOL                _firtDecoded;
}

#pragma mark 参考kxmovie中的解码
- (void)videoDecoder_init {
    
    avcodec_register_all();
    
    //video
    AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    _videoCodecCtx = avcodec_alloc_context3(codec);
    int ret = avcodec_open2(_videoCodecCtx, codec, nil);
    if (ret != 0){
        NSLog(@"open codec failed :%d",ret);
    }
    
    _videoFrame = av_frame_alloc();
    av_init_packet(&_packet);
}


#pragma mark 参考DFURTSPPlayer 解码成image
- (void)setOutputHeight:(int)outputHeight {

    if (_outputHeight != outputHeight) {
        _outputHeight = outputHeight;
        [self setupScale];
    }
}

- (void)setOutputWidth:(int)outputWidth {

    if (_outputWidth != outputWidth) {
        _outputWidth = outputWidth;
        [self setupScale];
    }
}

- (void)setupScale {

    avpicture_free(&_picture);
    sws_freeContext(_img_convert_ctx);
    
    //alloc rgb picture
    avpicture_alloc(&_picture, PIX_FMT_RGB24, _outputWidth, _outputHeight);
    
    //setup scaler
    static int sws_flags = SWS_FAST_BILINEAR;
    _img_convert_ctx = sws_getContext(_videoCodecCtx->width, _videoCodecCtx->height, _videoCodecCtx->pix_fmt, _outputWidth, _outputHeight, PIX_FMT_RGB24, sws_flags, NULL, NULL, NULL);
}

//原始方法
- (UIImage *)decodeToImage:(uint8_t *)nalBuffer size:(int)inSize {

    _packet.size = inSize;
    _packet.data = nalBuffer;
    
    UIImage *image;
    
    while (inSize > 0) {
        
        int gotframe = 0;
        int len = avcodec_decode_video2(_videoCodecCtx,
                                        _videoFrame,
                                        &gotframe,
                                        &_packet);
        
        if (len < 0) {
            NSLog(@"decode video error, skip packet");
            return nil;
        }
        
        inSize -= len;
    }
    
    if (!_firtDecoded) {
        _firtDecoded = YES;
        _outputWidth = 426;
        self.outputHeight = 320;
    }
    
    [self convertFrameToRGB];
    return [self imageFromAVPicture:_picture width:_outputWidth height:_outputHeight];
    
    return image;
}

//升级版
- (CGSize)videoDecoder_decodeToImage:(uint8_t *)nalBuffer size:(int)inSize timeStamp:(unsigned int)pts{
    
    _packet.size = inSize;
    _packet.data = nalBuffer;
    _packet.pts  = pts;
    _packet.dts  = pts;

    CGSize frameSize = {0, 0};
    
    while (inSize > 0) {
        
        int gotframe = 0;
        int len = avcodec_decode_video2(_videoCodecCtx,
                                        _videoFrame,
                                        &gotframe,
                                        &_packet);
        
        if (len < 0) {
            NSLog(@"decode video error, skip packet");
            return frameSize;
        }
        
        inSize -= len;
    }
    frameSize.width = _videoCodecCtx->width;
    frameSize.height = _videoCodecCtx->height;
    
    _outputWidth = _videoCodecCtx->width;
    self.outputHeight = _videoCodecCtx->height;
    
    return frameSize;
}

- (UIImage *)currentImage {

    if (!_videoFrame->data[0]) {
        return nil;
    }
    
    [self convertFrameToRGB];
    return [self imageFromAVPicture:_picture width:_outputWidth height:_outputHeight];
}

- (void)convertFrameToRGB {

    sws_scale(_img_convert_ctx, (const uint8_t * const*)_videoFrame->data, _videoFrame->linesize, 0, _videoCodecCtx->height, _picture.data, _picture.linesize);
}

- (UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0] * height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       YES,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [[UIImage alloc]initWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

- (void)dealloc {
    
    sws_freeContext(_img_convert_ctx);
    avpicture_free(&_picture);
    av_free_packet(&_packet);
    av_free(_videoFrame);
    
    if (_videoCodecCtx) {
        avcodec_close(_videoCodecCtx);
    }
}

@end
