//
//  PCMAudioRecorder.m
//  AVSamplePlayer
//
//  Created by bingcai on 16/8/23.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import "PCMAudioRecorder.h"

#define kDefaultBufferDurationSeconds 0.1279   //调整这个值使得录音的缓冲区大小为2048bytes
#define kDefaultSampleRate 8000   //定义采样率为8000

@implementation PCMAudioRecorder {

    AudioStreamBasicDescription _audioDescription;
    AudioQueueRef               _audioQueue;
    AudioQueueBufferRef         _audioQueueBuffers[QUEUE_BUFFER_SIZE];
    
    FILE *_recordFile;
}

static void AQInputCallback (
                             void * __nullable               inUserData,
                             AudioQueueRef                   inAQ,
                             AudioQueueBufferRef             inBuffer,
                             const AudioTimeStamp *          inStartTime,
                             UInt32                          inNumberPacketDescriptions,
                             const AudioStreamPacketDescription * __nullable inPacketDescs) {

    PCMAudioRecorder *recorder = (__bridge PCMAudioRecorder *)inUserData;
    if (inBuffer->mAudioDataByteSize > 0) {
        [recorder processAudioBuffer:inBuffer];
    }
}

- (instancetype)init {

    self = [super init];
    if (self) {
        _audioDescription.mSampleRate = kDefaultSampleRate;
        _audioDescription.mFormatID = kAudioFormatLinearPCM;
        _audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _audioDescription.mFramesPerPacket = 1;
        _audioDescription.mChannelsPerFrame = 1;
        _audioDescription.mBitsPerChannel = 16;
        _audioDescription.mBytesPerPacket = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;
        _audioDescription.mBytesPerFrame = _audioDescription.mBytesPerPacket;
        
        AudioQueueNewInput(&_audioDescription, AQInputCallback, (__bridge void *)self, NULL, kCFRunLoopCommonModes, 0, &_audioQueue);
        
        //计算估算的缓存区大小
        int frames = (int)ceil(kDefaultBufferDurationSeconds * _audioDescription.mSampleRate); //返回大于或者等于指定表达式的最小整数
        int bufferSize = frames *_audioDescription.mBytesPerFrame;  //缓冲区大小在这里设置，这个很重要，在这里设置的缓冲区有多大，那么在回调函数的时候得到的inbuffer的大小就是多大。
        bufferSize = 320;  //必须是80的倍数
        for (int i = 0; i < QUEUE_BUFFER_SIZE; i ++) {
            AudioQueueAllocateBuffer(_audioQueue, bufferSize, &_audioQueueBuffers[i]);
            AudioQueueEnqueueBuffer(_audioQueue, _audioQueueBuffers[i], 0, NULL);
        }
        
//        _recordFile = fopen("/Users/XCHF-ios/Documents/phone.pcm", "w");
    }
    return self;
}

- (void)startRecord {
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    OSStatus status = AudioQueueStart(_audioQueue, NULL);
    if (status  != noErr) {
        NSLog(@"AudioQueueStart Error: %d", status);
    }
}

- (void) stopRecord
{
    AudioQueueStop(_audioQueue, true);
}

- (void)processAudioBuffer:(AudioQueueBufferRef)buffer {

//    NSLog(@"processAudioData :%u",buffer->mAudioDataByteSize);
//    fwrite(buffer->mAudioData, 1, buffer->mAudioDataByteSize, _recordFile);
    if ([self.delegate respondsToSelector:@selector(DidGetAudioData:size:)]) {
        [self.delegate DidGetAudioData:buffer->mAudioData size:buffer->mAudioDataByteSize];
    }
    AudioQueueEnqueueBuffer(_audioQueue, buffer, 0, NULL);
}

@end
