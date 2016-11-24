//
//  OpenAL.m
//  AVSamplePlayer
//
//  Created by xiechuang on 16/7/26.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import "OpenAL.h"

@implementation OpenAL

@synthesize mDevice;
@synthesize mContext;
@synthesize soundDictionary;
@synthesize bufferStorageArray;

#pragma mark - openal function
-(void)initOpenAL
{
    //processed =0;
    //queued =0;
    
    //init the device and context
    mDevice=alcOpenDevice(NULL);
    if (mDevice) {
        mContext=alcCreateContext(mDevice, NULL);
        alcMakeContextCurrent(mContext);
    }
    
    soundDictionary = [[NSMutableDictionary alloc]init];// not used
    bufferStorageArray = [[NSMutableArray alloc]init];// not used
    
    alGenSources(1, &outSourceID);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(outSourceID, AL_PITCH, 1.0f);
    alSourcef(outSourceID, AL_GAIN, 1.0f);
    alSourcei(outSourceID, AL_LOOPING, AL_FALSE);
    alSourcef(outSourceID, AL_SOURCE_TYPE, AL_STREAMING);
    
//    updataBufferTimer = [NSTimer scheduledTimerWithTimeInterval: 1/100.0
//                                                         target:self
//                                                       selector:@selector(updataQueueBuffer)
//                                                       userInfo: nil
//                                                        repeats:YES];
}


- (BOOL) updataQueueBuffer
{
    ALint stateVaue;
    int processed, queued;
    
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
    
    if (stateVaue == AL_STOPPED ||
        stateVaue == AL_PAUSED ||
        stateVaue == AL_INITIAL)
    {
       // [self playSound];
        return NO;
    }
    
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(outSourceID, AL_BUFFERS_QUEUED, &queued);
    
    NSLog(@"Processed = %d\n", processed);
    NSLog(@"Queued = %d\n", queued);
    
    while(processed--)
    {
        alSourceUnqueueBuffers(outSourceID, 1, &buff);
        alDeleteBuffers(1, &buff);
    }
    
    return YES;
}

- (void)openAudioFromQueue:(NSData *)data dataSize:(UInt32)dataSize
//- (void)openAudioFromQueue:(short*)data dataSize:(UInt32)dataSize
{
   
    
    NSCondition* ticketCondition= [[NSCondition alloc] init];
    [ticketCondition lock];
    
    ALuint bufferID = 0;
    alGenBuffers(1, &bufferID);
    
   // NSData * tmpData = [NSData dataWithBytes:data length:dataSize];
    alBufferData(bufferID, AL_FORMAT_MONO8, (char*)[data bytes], (ALsizei)[data length], 8000);
    alSourceQueueBuffers(outSourceID, 1, &bufferID);
    
    [self updataQueueBuffer];
    
    ALint stateVaue;
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
    
    [ticketCondition unlock];
    
    ticketCondition = nil;
    
}





- (void)openAudioFromQueue:(NSData *)data dataSize:(UInt32)dataSize index:(int)aIndex
{
    ALenum  error = AL_NO_ERROR;
    
    if (data == NULL) {
        return;
    }
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSCondition* ticketCondition= [[NSCondition alloc] init];
    
    [ticketCondition lock];
    [self updataQueueBuffer];
    
    ALuint bufferID = 0;
    alGenBuffers(1, &bufferID);
    if((error = alGetError()) != AL_NO_ERROR) {
        NSLog(@"error alGenBuffers: %x\n", error);
    }
    else {
        NSLog(@"suc alGenBuffers: %x\n", error);
       // NSLog(@"%s",data);
      
        alBufferData(bufferID, AL_FORMAT_MONO16, (const ALvoid*)[data bytes], (ALsizei)[data length], 8000);
        if((error = alGetError()) != AL_NO_ERROR)
        {
            NSLog(@"error sucalBufferData: %x\n", error);
        }
        else
        {
            NSLog(@"sucalBufferData: %x\n", error);
            alSourceQueueBuffers(outSourceID, 1, &bufferID);
            if((error = alGetError()) != AL_NO_ERROR)
            {
                NSLog(@"error alSourceQueueBuffers: %x\n", error);
            }
            else
            {
                NSLog(@"suc alSourceQueueBuffers: %x\n", error);
                [self playSound];
                if((error = alGetError()) != AL_NO_ERROR)
                {
                    NSLog(@"error alSourcePlay: %x\n", error);
                    alDeleteBuffers(1, &bufferID);
                }
                else
                {
                    NSLog(@"suc alSourcePlay: %x\n", error);
                }
            }
        }
    }
    
    [ticketCondition unlock];
  
    ticketCondition = nil;
    
}



#pragma mark - play/stop/clean function
-(void)playSound
{
    ALint value;
    alGetSourcei(outSourceID,AL_SOURCE_STATE,&value);
    if (value != AL_PLAYING)
    {
        NSLog(@"------------->%u",outSourceID);
        alSourcePlay(outSourceID);
    }
}

-(void)stopSound
{
    alSourceStop(outSourceID);
}

-(void)cleanUpOpenAL
{
    //    while(processed--)
    //    {
    //        alSourceUnqueueBuffers(outSourceID, 1, &buff);
    //        alDeleteBuffers(1, &buff);
    //    }
    [updataBufferTimer invalidate];
    updataBufferTimer = nil;
    alDeleteSources(1, &outSourceID);
    alDeleteBuffers(1, &buff);
    alcDestroyContext(mContext);
    alcCloseDevice(mDevice);
}

#pragma mark - 供参考  play/stop/clean

// the main method: grab the sound ID from the library
// and start the source playing
- (void)playSound:(NSString*)soundKey
{
    NSNumber* numVal = [soundDictionary objectForKey:soundKey];
    if (numVal == nil)
        return;
    
    NSUInteger sourceID = [numVal unsignedIntValue];
    alSourcePlay(sourceID);
}

- (void)stopSound:(NSString*)soundKey
{
    NSNumber* numVal = [soundDictionary objectForKey:soundKey];
    if (numVal == nil)
        return;
    
    NSUInteger sourceID = [numVal unsignedIntValue];
    alSourceStop(sourceID);
}


-(void)cleanUpOpenAL:(id)sender
{
    // delete the sources
    for (NSNumber* sourceNumber in [soundDictionary allValues])
    {
        NSUInteger sourceID = [sourceNumber unsignedIntegerValue];
        alDeleteSources(1, &sourceID);
    }
    
    [soundDictionary removeAllObjects];
    // delete the buffers
    for (NSNumber* bufferNumber in bufferStorageArray)
    {
        NSUInteger bufferID = [bufferNumber unsignedIntegerValue];
        alDeleteBuffers(1, &bufferID);
    }
    [bufferStorageArray removeAllObjects];
    
    // destroy the context
    alcDestroyContext(mContext);
    // close the device
    alcCloseDevice(mDevice);
}


#pragma mark - unused function
////////////////////////////////////////////
//crespo study openal function,need import audiotoolbox framework and 2 header file
////////////////////////////////////////////


// open the audio file
// returns a big audio ID struct
-(AudioFileID)openAudioFile:(NSString*)filePath
{
    AudioFileID outAFID;
    // use the NSURl instead of a cfurlref cuz it is easier
    NSURL * afUrl = [NSURL fileURLWithPath:filePath];
    // do some platform specific stuff..
#if TARGET_OS_IPHONE
    OSStatus result = AudioFileOpenURL((__bridge CFURLRef)afUrl, kAudioFileReadPermission, 0, &outAFID);
#else
    OSStatus result = AudioFileOpenURL((CFURLRef)afUrl, fsRdPerm, 0, &outAFID);
#endif
    if (result != 0)
        NSLog(@"cannot openf file: %@",filePath);
    
    return outAFID;
}


// find the audio portion of the file
// return the size in bytes
-(UInt32)audioFileSize:(AudioFileID)fileDescriptor
{
    UInt64 outDataSize = 0;
    UInt32 thePropSize = sizeof(UInt64);
    OSStatus result = AudioFileGetProperty(fileDescriptor, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outDataSize);
    if(result != 0)
        NSLog(@"cannot find file size");
    
    return (UInt32)outDataSize;
}





@end
