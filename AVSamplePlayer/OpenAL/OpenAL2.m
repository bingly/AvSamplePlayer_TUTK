//
//  OpenAL2.m
//  AVSamplePlayer
//
//  Created by xiechuang on 16/8/4.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import "OpenAL2.h"

@implementation OpenAL2

-(BOOL)initOpenAl
{
    if (m_Device ==nil)
    {
        m_Device = alcOpenDevice(NULL);                      //参数为NULL , 让ALC 使用默认设备
    }
    
    if (m_Device==nil)
    {
        return NO;
    }
    if (m_Context==nil)
    {
        if (m_Device)
        {
            m_Context =alcCreateContext(m_Device, NULL);      //与初始化device是同样的道理
            alcMakeContextCurrent(m_Context);
        }
    }
    
    alGenSources(1, &m_sourceID);                                                           //初始化音源ID
    alSourcei(m_sourceID, AL_LOOPING, AL_FALSE);                         // 设置音频播放是否为循环播放，AL_FALSE是不循环
    alSourcef(m_sourceID, AL_SOURCE_TYPE, AL_STREAMING);  // 设置声音数据为流试，（openAL 针对PCM格式数据流）
    alSourcef(m_sourceID, AL_GAIN, 1.0f);                                               //设置音量大小，1.0f表示最大音量。openAL动态调节音量大小就用这个方法
    //    alDopplerVelocity(1.0);                                                                         //多普勒效应，这属于高级范畴，不是做游戏开发，对音质没有苛刻要求的话，一般无需设置
    //    alDopplerFactor(1.0);                                                                            //同上
    alSpeedOfSound(1.0);                                                                            //设置声音的播放速度
    
    m_DecodeLock =[[NSCondition alloc] init];
    if (m_Context==nil)
    {
        return NO;
    }
    //counts =0;
    
    
    
    /*这里有我注释掉的监测方法，alGetError()用来监测环境搭建过程中是否有错误
     在这里，可以说是是否出错都可以，为什么这样说呢？ 因为运行到这里之前，
     如果加上了alSourcef(m_sourceID, AL_SOURCE_TYPE, AL_STREAMING);
     这个方法，这里就会监测到错误，注释掉这个方法就不会有错误。（具体为什么，我
     也不知道～～～，知道的大神麻烦说下～～～），加上这个方法，在这里监测出错误
     对之后播放声音无影响，所以，这里可以注释掉下面的alGetError()。
     */
    //    ALenum  error;
    //    if ((error=alGetError())!=AL_NO_ERROR)
    //    {
    //        return NO;
    //    }
    return YES;
}

//清楚已存在的buffer，这个函数其实没什么的，就只是用来清空缓存而已，我只是多一步将播放声音放到这个函数里。
-(BOOL)updataQueueBuffer
{
    ALint  state;
    int processed ,queued;
    
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &state);
    if (state !=AL_PLAYING)
    {
        [self playSound];
        return NO;
    }
    
    alGetSourcei(m_sourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(m_sourceID, AL_BUFFERS_QUEUED, &queued);
    
    
    NSLog(@"Processed = %d\n", processed);
    NSLog(@"Queued = %d\n", queued);
    while (processed--)
    {
        ALuint  buffer;
        alSourceUnqueueBuffers(m_sourceID, 1, &buffer);
        alDeleteBuffers(1, &buffer);
    }
    return YES;
}

//这个函数就是比较重要的函数了， 将收到的pcm数据放到缓存器中，再拿出来播放
-(void)openAudio:(NSData *)pBuffer length:(UInt32)pLength
{
    
    [m_DecodeLock lock];
    
    ALenum  error =AL_NO_ERROR;
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        [m_DecodeLock unlock];
        return ;
    }
    if (pBuffer ==NULL)
    {
        return ;
    }
    
    [self updataQueueBuffer];                                  //在这里调用了刚才说的清除缓存buffer函数，也附加声音播放
    
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        [m_DecodeLock unlock];
        return ;
    }
    
    ALuint    bufferID =0;                                             //存储声音数据，建立一个pcm数据存储器，初始化一块区域用来保存声音数据
    alGenBuffers(1, &bufferID);
    
    if ((error = alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"Create buffer failed");
        [m_DecodeLock unlock];
        return;
    }
    
    //NSData  *data =[NSData dataWithBytes:pBuffer length:pLength];                                                                    //将PCM格式数据转换成NSData ,
    alBufferData(bufferID, AL_FORMAT_MONO16,(char *)[pBuffer bytes] , (ALsizei)[pBuffer length], 8000 );         //将转好的NSData存放到之前初始化好的一块buffer区域中并设置好相应的播放格式 ，（本人使用的播放格式: 单声道16bit(AL_FORMAT_MONO16) , 采样率 8000HZ）
    error =alGetError();
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"create bufferData failed");
        [m_DecodeLock unlock];
        return;
    }
    
    //添加到缓冲区
    alSourceQueueBuffers(m_sourceID, 1, &bufferID);
    
    if ((error =alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"add buffer to queue failed");
        [m_DecodeLock unlock];
        return;
    }
    if ((error=alGetError())!=AL_NO_ERROR)
    {
        NSLog(@"play failed");
        alDeleteBuffers(1, &bufferID);
        [m_DecodeLock unlock];
        return;
    }
    
    [m_DecodeLock unlock];
    
}
-(void)playSound
{
    ALint  state;
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &state);
    if (state != AL_PLAYING)
    {
        alSourcePlay(m_sourceID);
    }
}

-(void)stopSound
{
    ALint  state;
    alGetSourcei(m_sourceID, AL_SOURCE_STATE, &state);
    if (state != AL_STOPPED)
    {
        
        alSourceStop(m_sourceID);
    }
}

-(void)clearOpenAL
{
    alDeleteSources(1, &m_sourceID);
    if (m_Context != nil)
    {
        alcDestroyContext(m_Context);
        m_Context=nil;
    }
    if (m_Device !=nil)
    {
        alcCloseDevice(m_Device);
        m_Device=nil; 
    } 
}
@end
