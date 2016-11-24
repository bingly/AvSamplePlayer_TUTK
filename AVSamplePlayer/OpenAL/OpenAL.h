//
//  OpenAL.h
//  AVSamplePlayer
//
//  Created by xiechuang on 16/7/26.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import <Foundation/Foundation.h>

@interface OpenAL : NSObject
{
    ALCcontext *mContext;
    ALCdevice *mDevice;
    ALuint outSourceID;
    
    NSMutableDictionary* soundDictionary;
    NSMutableArray* bufferStorageArray;
    
    ALuint buff;
    NSTimer* updataBufferTimer;

}

@property (nonatomic) ALCcontext *mContext;
@property (nonatomic) ALCdevice *mDevice;
@property (nonatomic,retain)NSMutableDictionary* soundDictionary;
@property (nonatomic,retain)NSMutableArray* bufferStorageArray;

-(void)initOpenAL;
- (void)openAudioFromQueue:(NSData *)data dataSize:(UInt32)dataSize;
//- (void)openAudioFromQueue:(short*)data dataSize:(UInt32)dataSize;
- (void)openAudioFromQueue:(NSData *)data dataSize:(UInt32)dataSize index:(int)aIndex;
-(void)playSound;
- (void)playSound:(NSString*)soundKey;
//如果声音不循环，那么它将会自然停止。如果是循环的，你需要停止
-(void)stopSound;
- (void)stopSound:(NSString*)soundKey;

-(void)cleanUpOpenAL;
-(void)cleanUpOpenAL:(id)sender;@end
