//
//  OpenAL3.m
//  AVSamplePlayer
//
//  Created by xiechuang on 16/8/4.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import "OpenAL3.h"

@implementation OpenAL3

@synthesize mDevice,mContext,soundDictionary,bufferStorageArray;

#pragma make - openal function


-(void)initOpenAL
{
    NSLog(@"=======initOpenAl===");
    mDevice=alcOpenDevice(NULL);
    if (mDevice) {
        mContext=alcCreateContext(mDevice, NULL);
        alcMakeContextCurrent(mContext);
    }
    
    alGenSources(1, &outSourceId);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(outSourceId, AL_PITCH, 1.0f);
    alSourcef(outSourceId, AL_GAIN, 1.0f);
    alSourcei(outSourceId, AL_LOOPING, AL_FALSE);
    alSourcef(outSourceId, AL_SOURCE_TYPE, AL_STREAMING);
    
}


- (void) openAudioFromQueue:(NSData *)data dataSize:(UInt32)dataSize
{
    NSCondition* ticketCondition= [[NSCondition alloc] init];
    [ticketCondition lock];
    
    ALuint bufferID = 0;
    alGenBuffers(1, &bufferID);
    // NSLog(@"bufferID = %d",bufferID);
    //NSData * tmpData = [NSData dataWithBytes:data length:dataSize];
   
    // NSLog(@"%d,%d,%d",aSampleRate,aBit,aChannel);
   

    alBufferData(bufferID,AL_FORMAT_MONO16, (char*)[data bytes], (ALsizei)[data length],8000);
    alSourceQueueBuffers(outSourceId, 1, &bufferID);
    
    [self updataQueueBuffer];
    
    ALint stateVaue;
    alGetSourcei(outSourceId, AL_SOURCE_STATE, &stateVaue);
    
    [ticketCondition unlock];
    ticketCondition = nil;
    
}


- (BOOL)updataQueueBuffer
{
    ALint stateVaue;
    int processed, queued;
    
    alGetSourcei(outSourceId, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(outSourceId, AL_BUFFERS_QUEUED, &queued);
    
    //NSLog(@"Processed = %d\n", processed);
    //NSLog(@"Queued = %d\n", queued);
    
    alGetSourcei(outSourceId, AL_SOURCE_STATE, &stateVaue);
    
    if (stateVaue == AL_STOPPED ||
        stateVaue == AL_PAUSED ||
        stateVaue == AL_INITIAL)
    {
        if (queued < processed || queued == 0 ||(queued == 1 && processed ==1)) {
            NSLog(@"Audio Stop");
            [self stopSound];
            [self cleanUpOpenAL];
        }
        
        // NSLog(@"===statevaue ========================%d",stateVaue);
        [self playSound];
        return NO;
    }
    
    while(processed--)
    {
        // NSLog(@"queue = %d",queued);
        alSourceUnqueueBuffers(outSourceId, 1, &buff);
        alDeleteBuffers(1, &buff);
    }
    //NSLog(@"queue = %d",queued);
    return YES;
}


#pragma make - play/stop/clean function
-(void)playSound
{
    alSourcePlay(outSourceId);
}
-(void)stopSound
{
    alSourceStop(outSourceId);
}
-(void)cleanUpOpenAL
{
    [updateBufferTimer invalidate];
    updateBufferTimer = nil;
    alDeleteSources(1, &outSourceId);
    alDeleteBuffers(1, &buff);
    alcDestroyContext(mContext);
    alcCloseDevice(mDevicde);
}



-(void)dealloc
{
    NSLog(@"openal sound dealloc");
}
@end
