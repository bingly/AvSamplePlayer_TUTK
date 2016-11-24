//
//  OpenAL2.h
//  AVSamplePlayer
//
//  Created by xiechuang on 16/8/4.
//  Copyright © 2016年 sharetronic. All rights reserved.
//
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <Foundation/Foundation.h>

@interface OpenAL2 : NSObject
{
    ALCcontext         *m_Context;           //内容，相当于给音频播放器提供一个环境描述
    ALCdevice          *m_Device;             //硬件，获取电脑或者ios设备上的硬件，提供支持
    ALuint                   m_sourceID;           //音源，相当于一个ID,用来标识音源
    
    NSCondition        *m_DecodeLock;


}

-(BOOL)initOpenAl;
-(void)playSound;
-(void)stopSound;
-(void)openAudio:(NSData *)pBuffer length:(UInt32)pLength;
-(void)clearOpenAL;


@end
