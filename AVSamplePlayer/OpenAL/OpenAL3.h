//
//  OpenAL3.h
//  AVSamplePlayer
//
//  Created by xiechuang on 16/8/4.
//  Copyright © 2016年 sharetronic. All rights reserved.
//
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <OpenAL/oalMacOSX_OALExtensions.h>
#import <Foundation/Foundation.h>

@interface OpenAL3 : NSObject
{
    ALCcontext *mContext;
    ALCdevice *mDevicde;
    ALuint outSourceId;
    NSMutableDictionary *soundDictionary;
    NSMutableArray *bufferStorageArray;
    ALuint buff;
    NSTimer *updateBufferTimer;
    
}

@property(nonatomic)ALCcontext *mContext;
@property(nonatomic)ALCdevice *mDevice;
@property(nonatomic,retain)NSMutableDictionary *soundDictionary;
@property(nonatomic,retain)NSMutableArray *bufferStorageArray;


-(void)initOpenAL;
-(void)openAudioFromQueue:(NSData *)data dataSize:(UInt32)dataSize;
-(BOOL)updataQueueBuffer;
-(void)playSound;
-(void)stopSound;
-(void)cleanUpOpenAL;


@end
