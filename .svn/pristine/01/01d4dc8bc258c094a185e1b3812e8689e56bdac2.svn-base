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

@interface KxMovieFrame()
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@end

@implementation KxMovieFrame
@end

@interface KxVideoFrameYUV()
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
@end

@implementation KxVideoFrameYUV
- (KxVideoFrameFormat) format { return KxVideoFrameFormatYUV; }
@end

@interface KxVideoFrame()
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@end

@implementation KxVideoFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeVideo; }
@end

@interface H264Decoder()
@property CVPixelBufferPoolRef pixelBufferPool;
@end

@implementation H264Decoder {
    
    AVFrame             *_videoFrame;
    AVCodecContext      *_videoCodecCtx;
    KxVideoFrameFormat  _videoFrameFormat;
    
    struct SwsContext   *_img_convert_ctx;
    AVPicture           _picture;
    AVPacket            _packet;
    BOOL                _firtDecoded;
}

- (NSUInteger) frameWidth
{
    return _videoCodecCtx ? _videoCodecCtx->width : 0;
}

- (NSUInteger) frameHeight
{
    return _videoCodecCtx ? _videoCodecCtx->height : 0;
}

- (void)videoDecoder_init {
    
    avcodec_register_all();
//    _videoFrame = av_frame_alloc();
    AVCodec *codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    _videoCodecCtx = avcodec_alloc_context3(codec);
    int ret = avcodec_open2(_videoCodecCtx, codec, nil);
    if (ret != 0){
        NSLog(@"open codec failed :%d",ret);
    }
    
    _videoFrame = av_frame_alloc();
    av_init_packet(&_packet);
}

- (NSArray *)videoDecoder_decode:(uint8_t *)nalBuffer size:(int)inSize {

    NSMutableArray *result = [NSMutableArray array];

    AVPacket packet;
    av_init_packet(&packet);
    packet.size = inSize;
    packet.data = nalBuffer;
    
    while (inSize > 0) {
        
        int gotframe = 0;
        int len = avcodec_decode_video2(_videoCodecCtx,
                                        _videoFrame,
                                        &gotframe,
                                        &packet);
        
        if (len < 0) {
            NSLog(@"decode video error, skip packet");
            break;
        }
        
        if (gotframe) {
            KxVideoFrame *frame = [self handleVideoFrame];
            [result addObject:frame];
        }
        inSize -= len;
    }
    
    av_free_packet(&packet);
    return result;
}

- (KxVideoFrame *) handleVideoFrame{

    if (!_videoFrame->data[0]) {
        return nil;
    }
    
    KxVideoFrame *frame;
    KxVideoFrameYUV *yuvFrame = [[KxVideoFrameYUV alloc] init];
    yuvFrame.luma = copyFrameData(_videoFrame->data[0],
                                  _videoFrame->linesize[0],
                                  _videoCodecCtx->width,
                                  _videoCodecCtx->height);
    
    yuvFrame.chromaB = copyFrameData(_videoFrame->data[1],
                                     _videoFrame->linesize[1],
                                     _videoCodecCtx->width / 2,
                                     _videoCodecCtx->height / 2);
    
    yuvFrame.chromaR = copyFrameData(_videoFrame->data[2],
                                     _videoFrame->linesize[2],
                                     _videoCodecCtx->width / 2,
                                     _videoCodecCtx->height / 2);
    frame = yuvFrame;
    
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;

    return frame;
}

#pragma mark - public

- (BOOL) setupVideoFrameFormat: (KxVideoFrameFormat) format
{
    if (format == KxVideoFrameFormatYUV &&
        _videoCodecCtx &&
        (_videoCodecCtx->pix_fmt == AV_PIX_FMT_YUV420P || _videoCodecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P)) {
        
        _videoFrameFormat = KxVideoFrameFormatYUV;
        return YES;
    }
    
    _videoFrameFormat = KxVideoFrameFormatRGB;
    return _videoFrameFormat == format;
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

#pragma mark 使用CVPixelBufferRef数据
- (CVPixelBufferRef)videoDecoder_decodeToPixel:(uint8_t *)nalBuffer size:(int)inSize {
    
    AVPacket packet;
    av_init_packet(&packet);
    packet.size = inSize;
    packet.data = nalBuffer;
    
    CVPixelBufferRef pixelBuffer = NULL;
    uint8_t *bufferOut = NULL;
    
    while (inSize > 0) {
        
        int gotframe = 0;
        int len = avcodec_decode_video2(_videoCodecCtx,
                                        _videoFrame,
                                        &gotframe,
                                        &packet);
        
        if (len < 0) {
            NSLog(@"decode video error, skip packet");
            break;
        }
        
        if (!gotframe) {
            return nil;
        }
        
        int bufferWidth  = _videoFrame->width;
        int bufferHeight = _videoFrame->height;
        
#pragma mark AVFrame转CVPixelBufferRef
//        法一
//        size_t srcPlaneSize = _videoFrame->linesize[1]*_videoFrame->height;
//        size_t dstPlaneSize = srcPlaneSize *2;
//        uint8_t *dstPlane = malloc(dstPlaneSize);
//        void *planeBaseAddress[2] = { _videoFrame->data[0], dstPlane };
//        
//        // This loop is very naive and assumes that the line sizes are the same.
//        // It also copies padding bytes.
//        assert(_videoFrame->linesize[1] == _videoFrame->linesize[2]);
//        for(size_t i = 0; i<srcPlaneSize; i++){
//            // These might be the wrong way round.
//            dstPlane[2*i  ]=_videoFrame->data[2][i];
//            dstPlane[2*i+1]=_videoFrame->data[1][i];
//        }
//        
//        // This assumes the width and height are even (it's 420 after all).
//        size_t planeWidth[2] = {_videoFrame->width, _videoFrame->width/2};
//        size_t planeHeight[2] = {_videoFrame->height, _videoFrame->height/2};
//        // I'm not sure where you'd get this.
//        size_t planeBytesPerRow[2] = {_videoFrame->linesize[0], _videoFrame->linesize[1]*2};
//        int ret = CVPixelBufferCreateWithPlanarBytes(
//                                                     NULL,
//                                                     _videoFrame->width,
//                                                     _videoFrame->height,
//                                                     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
//                                                     NULL,
//                                                     0,
//                                                     2,
//                                                     planeBaseAddress,
//                                                     planeWidth,
//                                                     planeHeight,
//                                                     planeBytesPerRow,
//                                                     NULL,
//                                                     NULL,
//                                                     NULL,
//                                                     &pixelBuffer);

//        法二
        
        bufferOut = (uint8_t *)malloc(_videoCodecCtx->width * _videoCodecCtx->height * 6 / 4);
        memcpy(bufferOut, _videoFrame->data[0], bufferWidth * bufferHeight);
        for (int i = 0; i < bufferHeight / 2; i ++) {
            for (int j = 0; j < bufferWidth / 2; j ++) {
                memcpy(bufferOut + i*bufferHeight/2 + j * 2, _videoFrame->data[1] + i*bufferHeight/2 + j, 1);
                memcpy(bufferOut + i*bufferHeight/2 + j * 2 + 1, _videoFrame->data[2] + i*bufferHeight/2 + j, 1);
            }
        }
        
        CVReturn theError;
        
        if (!self.pixelBufferPool){
            NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
            [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8Planar] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
            [attributes setObject:[NSNumber numberWithInt:_videoFrame->width] forKey: (NSString*)kCVPixelBufferWidthKey];
            [attributes setObject:[NSNumber numberWithInt:_videoFrame->height] forKey: (NSString*)kCVPixelBufferHeightKey];
            [attributes setObject:@(_videoFrame->linesize[0]) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
            [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
            theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &_pixelBufferPool);
            if (theError != kCVReturnSuccess){
                NSLog(@"CVPixelBufferPoolCreate Failed");
            }
        }
        
        theError = CVPixelBufferPoolCreatePixelBuffer(NULL, _pixelBufferPool, &pixelBuffer);
        if(theError != kCVReturnSuccess){
            NSLog(@"CVPixelBufferPoolCreatePixelBuffer Failed");
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        memcpy(base, bufferOut, bytePerRowY * _videoFrame->height);
        
        size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
        base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        memcpy(base, bufferOut+bufferHeight*bufferWidth, bytesPerRowUV * _videoFrame->height/2);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
//        法三：yuv420P数据
//        bufferOut = (uint8_t *)malloc(_videoCodecCtx->width * _videoCodecCtx->height * 6 / 4);
//        pgm_save(_videoFrame->data[0], _videoFrame->linesize[0], _videoFrame->width, _videoFrame->height, bufferOut);
//        pgm_save(_videoFrame->data[1], _videoFrame->linesize[1], _videoFrame->width / 2, _videoFrame->height / 2, bufferOut + _videoFrame->width * _videoFrame->height);
//        pgm_save(_videoFrame->data[2], _videoFrame->linesize[2], _videoFrame->width / 2, _videoFrame->height / 2, bufferOut + _videoFrame->width * _videoFrame->height * 5 / 4);
//
//        pixelBuffer = [self copyDataFromBuffer:bufferOut width:_videoFrame->width height:_videoFrame->height];
        
//        法四
//        bufferOut = (uint8_t *)malloc(_videoCodecCtx->width * _videoCodecCtx->height * 6 / 4);
//        memcpy(bufferOut, _videoFrame->data[0], bufferWidth * bufferHeight);
//        for (int i = 0; i < bufferHeight / 2; i ++) {
//            for (int j = 0; j < bufferWidth / 2; j ++) {
//                memcpy(bufferOut + i*bufferHeight/2 + j * 2, _videoFrame->data[1] + i*bufferHeight/2 + j, 1);
//                memcpy(bufferOut + i*bufferHeight/2 + j * 2 + 1, _videoFrame->data[2] + i*bufferHeight/2 + j, 1);
//            }
//        }
//        
//        NSDictionary *pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
//        
//        CVReturn theError = CVPixelBufferCreate(kCFAllocatorDefault, _videoFrame->width, _videoFrame->height, kCVPixelFormatType_420YpCbCr8Planar, (__bridge CFDictionaryRef)pixelAttributes, &pixelBuffer);
//        if (theError != kCVReturnSuccess) {
//            NSLog(@"CVPixelBufferCreate Error!!!");
//            return nil;
//        }
//        
//        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//        int bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//        void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//        memcpy(base, bufferOut, bytePerRowY * _videoFrame->height);
//        
//        size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//        base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//        memcpy(base, bufferOut + bufferWidth * bufferHeight, bufferWidth * _videoFrame->height / 2);
        
//        base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
//        memcpy(base, _videoFrame->data[2], bytesPerRowUV * _videoFrame->height / 2);

//        yuv数据memcpy第一次
//        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//        int bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//        const uint8_t *srcY = _videoFrame->data[0];
//        uint8_t *dst = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//        for (int i = 0; i < bufferHeight; i ++, dst += bytePerRowY, srcY += bufferWidth) {
//            memcpy(dst, srcY, bufferWidth);
//        }
//        
//        int bytePerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//        const uint8_t *srcU = _videoFrame->data[1];
//        bufferWidth  = bufferWidth >> 1;
//        bufferHeight = bufferHeight >> 1;
//        for (int i = 0; i < bufferHeight; i ++, dst += bytePerRowUV, srcU += bufferWidth) {
//            memcpy(dst, srcU, bufferWidth);
//        }
//        
//        const uint8_t *srcV = _videoFrame->data[2];
//        for (int i = 0; i < bufferHeight; i ++, dst += bytePerRowUV, srcV += bufferWidth) {
//            memcpy(dst, srcV, bufferWidth);
//        }
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        inSize -= len;
    }
    
    if (pixelBuffer) {
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        int aHeight = CVPixelBufferGetHeight(pixelBuffer);
        UIImage *uiImage = [UIImage imageWithCIImage:ciImage];
        NSLog(@"%@", uiImage);
    }
    
    av_free_packet(&packet);
    free(bufferOut);
    bufferOut = NULL;
    return pixelBuffer;
}

void pgm_save(unsigned char *buf,int wrap, int xsize,int ysize,uint8_t *pDataOut)
{
    for(int i=0;i<ysize;i++)
    {
        memcpy(pDataOut+i*xsize, buf + i * wrap, xsize);
    }
}

- (CVPixelBufferRef) copyDataFromBuffer:(uint8_t *)buffer width:(int)bufferWidth height:(int)bufferHeight {
    
    CVReturn theError;
    
    NSDictionary *pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    
    theError = CVPixelBufferCreate(kCFAllocatorDefault, _videoFrame->width, _videoFrame->height, kCVPixelFormatType_420YpCbCr8Planar, (__bridge CFDictionaryRef)pixelAttributes, &pixelBuffer);
    if (theError != kCVReturnSuccess) {
        NSLog(@"CVPixelBufferCreate Error!!!");
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    const uint8_t *src = buffer;
    uint8_t *dst = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    for (unsigned int rIdx = 0; rIdx < bufferHeight; rIdx ++, dst += d, src += bufferWidth) {
        memcpy(dst, src, bufferWidth);
    }
    
    d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    dst = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    bufferHeight = bufferHeight >> 1;
    bufferWidth  = bufferWidth >> 1;
    for (unsigned int rIdx = 0; rIdx < bufferHeight; rIdx ++, dst += d, src += bufferWidth) {
        memcpy(dst, src, bufferWidth);
    }
    
    d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    dst = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    for (unsigned int i = 0; i < bufferHeight; i ++, dst += d, src += bufferWidth) {
        memcpy(dst, src, bufferWidth);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
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
- (CGSize)videoDecoder_decodeToImage:(uint8_t *)nalBuffer size:(int)inSize {
    
    _packet.size = inSize;
    _packet.data = nalBuffer;

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
