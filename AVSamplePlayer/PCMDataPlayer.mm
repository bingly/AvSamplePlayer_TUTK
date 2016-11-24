//
//  PCMDataPlayer.m
//  PCMDataPlayerDemo
//
//  Created by Android88 on 15-2-10.
//  Copyright (c) 2015年 Android88. All rights reserved.
//

#import "PCMDataPlayer.h"

//audio queue运行流程：
//1、新建AudioQueueNewOutput，设置每个buffer用完后的回调，新建audio queue buffer（AudioQueueAllocateBuffer）
//2、外界传来一帧音频数据，找到闲置的一个buffer，将数据塞到buffer里，然后enqueue到audio queue中

@implementation PCMDataPlayer

- (id)init
{
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)dealloc
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
    }
    audioQueue = nil;

    sysnLock = nil;

    NSLog(@"PCMDataPlayer dealloc...");
}

static void AudioPlayerAQInputCallback(void* inUserData, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    PCMDataPlayer* player = (__bridge PCMDataPlayer*)inUserData;
    [player playerCallback:outQB];
}

- (void)reset
{
    [self stop];

    sysnLock = [[NSLock alloc] init];

    ///设置音频参数
    audioDescription.mSampleRate = 8000; //采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = 1; ///单声道
    audioDescription.mFramesPerPacket = 1; //每一个packet一侦数据
    audioDescription.mBitsPerChannel = 16; //每个采样点16bit量化
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel / 8) * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame;

    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void*)self, nil, nil, 0, &audioQueue); //使用player的内部线程播放

    //初始化音频缓冲区
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        int result = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]); ///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
//        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d", i, result);
    }

    NSLog(@"PCMDataPlayer reset");
}

- (void)stop
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
        AudioQueueReset(audioQueue);
    }

    audioQueue = nil;
}

- (void)play:(void*)pcmData length:(unsigned int)length
{
    if (audioQueue == nil || ![self checkBufferHasUsed]) {
        [self reset];
        AudioQueueStart(audioQueue, NULL);
    }

    [sysnLock lock];

    AudioQueueBufferRef audioQueueBuffer = NULL;

    while (true) {
        audioQueueBuffer = [self getNotUsedBuffer];
        if (audioQueueBuffer != NULL) {
            break;
        }
        usleep(1000);
    }

    audioQueueBuffer->mAudioDataByteSize = length;
    Byte* audiodata = (Byte*)audioQueueBuffer->mAudioData;
    for (int i = 0; i < length; i++) {
        audiodata[i] = ((Byte*)pcmData)[i];
    }

    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, NULL);

//    NSLog(@"PCMDataPlayer play dataSize:%d", length);

    [sysnLock unlock];
}

- (BOOL)checkBufferHasUsed
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (YES == audioQueueUsed[i]) {
            return YES;
        }
    }
//    NSLog(@"PCMDataPlayer 播放中断............");
    return NO;
}

- (AudioQueueBufferRef)getNotUsedBuffer
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (NO == audioQueueUsed[i]) {
            audioQueueUsed[i] = YES;
//            NSLog(@"PCMDataPlayer play buffer index:%d", i);
            return audioQueueBuffers[i];
        }
    }
    return NULL;
}

- (void)playerCallback:(AudioQueueBufferRef)outQB
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (outQB == audioQueueBuffers[i]) {   //现存的buffer与回调的buffer一致，就表示没用过
            audioQueueUsed[i] = NO;
        }
    }
}

@end
