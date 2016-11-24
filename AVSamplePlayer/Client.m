//
//  Client.m
//  Sample_AVAPIs
//
//  Created by tutk on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Client.h"
#import "IOTCAPIs.h"
#import "AVAPIs.h"
#import "AVIOCTRLDEFs.h"
#import "AVFRAMEINFO.h"
#import <sys/time.h>
#import <pthread.h>
#import "TEST.h"
#import "PCMDataPlayer.h"

#define AUDIO_BUF_SIZE	1024
#define VIDEO_BUF_SIZE	100000

@implementation Client

unsigned int _getTickCount() {
    
    struct timeval tv;
    
    if (gettimeofday(&tv, NULL) != 0)
        return 0;
    
    return (tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

void *thread_ReceiveAudio(void *arg)
{
    NSLog(@"[thread_ReceiveAudio] Starting...");
    
    int avIndex = *(int *)arg;
//    char buf[AUDIO_BUF_SIZE];
    char *buf = malloc(AUDIO_BUF_SIZE);
    unsigned int frmNo;
    int ret;
    FRAMEINFO_t frameInfo;
    __block int sequenceNumber = 0;
    
//    FILE *pcmFile = fopen("/Users/XCHF-ios/Documents/avSample.pcm", "w");
    PCMDataPlayer *_pcmPlayer = [[PCMDataPlayer alloc] init];
    while (1)
    {
        ret = avCheckAudioBuf(avIndex);
        if (ret < 0) break;
        if (ret < 3) // determined by audio frame rate
        {
            usleep(120000);
            continue;
        }
        
        ret = avRecvAudioData(avIndex, buf, AUDIO_BUF_SIZE, (char *)&frameInfo, sizeof(FRAMEINFO_t), &frmNo);
//        NSLog(@"%d", frameInfo.timestamp);
        
        if(ret == AV_ER_SESSION_CLOSE_BY_REMOTE)
        {
            NSLog(@"[thread_ReceiveAudio] AV_ER_SESSION_CLOSE_BY_REMOTE");
            break;
        }
        else if(ret == AV_ER_REMOTE_TIMEOUT_DISCONNECT)
        {
            NSLog(@"[thread_ReceiveAudio] AV_ER_REMOTE_TIMEOUT_DISCONNECT");
            break;
        }
        else if(ret == IOTC_ER_INVALID_SID)
        {
            NSLog(@"[thread_ReceiveAudio] Session cant be used anymore");
            break;
        }
        else if (ret == AV_ER_LOSED_THIS_FRAME)
        {
            continue;
        }
        
        if (ret>0) {
            
            short  requestBuf[ret * 2];
            int l = G711Decode(requestBuf, (unsigned char*)buf, ret);
//            fwrite(requestBuf, 1, l, pcmFile);
            
            [_pcmPlayer play:requestBuf length:l];
        }
        
        // Now the data is ready in audioBuffer[0 ... ret - 1]
        // Do something here
        
//        NSString *string1 = @"";
//        int dataLength = ret > 100 ? 100 : ret;
//        for (int i = 0; i < dataLength; i ++) {
//            NSString *temp = [NSString stringWithFormat:@"%x", buf[i]&0xff];
//            if ([temp length] == 1) {
//                temp = [NSString stringWithFormat:@"0%@", temp];
//            }
//            string1 = [string1 stringByAppendingString:temp];
//        }
//        NSLog(@"%@", string1);

//        最初用的是main thread，此时视频会出现的严重的卡顿。所以，把声音放在单独的线程中
//        short  requestBuf[ret * 2];
//        int l = G711Decode(requestBuf, (unsigned char*)buf, ret);
//        fwrite(requestBuf, 1, l, pcmFile);
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
////            NSData *data = [NSData dataWithBytes:buf length:ret];
//            
//            NSDictionary *dict = @{@"data":[NSData dataWithBytes:buf length:ret],
//                                   @"sequence":[NSNumber numberWithInt:sequenceNumber ++]};
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"audio" object:dict];
//        });
    }
    
    NSLog(@"[thread_ReceiveAudio] thread exit");
    return 0;
}


void *thread_ReceiveVideo(void *arg)
{
    NSLog(@"[thread_ReceiveVideo] Starting...");
    
    int avIndex = *(int *)arg;
    char *buf = malloc(VIDEO_BUF_SIZE);
    unsigned int frmNo;
    int ret;
    FRAMEINFO_t frameInfo;
    
    int pActualFrameSize[] = {0};
    int pExpectedFameSize[] = {0};
    int pActualFrameInfoSize[] = {0};
    
    __block int videoOrder = 0;
    
    while (1)
    {

//        ret = avRecvFrameData(avIndex, buf, VIDEO_BUF_SIZE, (char *)&frameInfo, sizeof(FRAMEINFO_t), &frmNo);
        ret = avRecvFrameData2(avIndex, buf, VIDEO_BUF_SIZE, pActualFrameSize, pExpectedFameSize, (char *)&frameInfo, sizeof(FRAMEINFO_t), pActualFrameInfoSize, &frmNo);

//        if(frameInfo.flags == IPC_FRAME_FLAG_IFRAME)

        if (ret > 0)
        {
            // got an IFrame, draw it.
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dict = @{@"data":[NSData dataWithBytes:buf length:ret],
                                       @"timestamp":[NSNumber numberWithUnsignedInt:frameInfo.timestamp]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"client" object:dict];
            });
            usleep(30000);
        }
        else if(ret == AV_ER_DATA_NOREADY)
        {
            usleep(10000);
            continue;
        }
        else if(ret == AV_ER_LOSED_THIS_FRAME)
        {
//            NSLog(@"Lost video frame NO[%d]", frmNo);
            continue;
        }
        else if(ret == AV_ER_INCOMPLETE_FRAME)
        {
//            NSLog(@"Incomplete video frame NO[%d]", frmNo);
            continue;
        }
        else if(ret == AV_ER_SESSION_CLOSE_BY_REMOTE)
        {
            NSLog(@"[thread_ReceiveVideo] AV_ER_SESSION_CLOSE_BY_REMOTE");
            break;
        }
        else if(ret == AV_ER_REMOTE_TIMEOUT_DISCONNECT)
        {
            NSLog(@"[thread_ReceiveVideo] AV_ER_REMOTE_TIMEOUT_DISCONNECT");
            break;
        }
        else if(ret == IOTC_ER_INVALID_SID)
        {
            NSLog(@"[thread_ReceiveVideo] Session cant be used anymore");
            break;
        }
        
        
    }
    free(buf);
    NSLog(@"[thread_ReceiveVideo] thread exit");
    return 0;
}

int start_ipcam_stream (int avIndex) {
    
    int ret;
        unsigned short val = 0;
    
    if ((ret = avSendIOCtrl(avIndex, IOTYPE_INNER_SND_DATA_DELAY, (char *)&val, sizeof(unsigned short)) < 0))
    {
        NSLog(@"start_ipcam_stream_failed[%d]", ret);
        return 0;
    }
    
    SMsgAVIoctrlAVStream ioMsg;
    memset(&ioMsg, 0, sizeof(SMsgAVIoctrlAVStream));
    if ((ret = avSendIOCtrl(avIndex, IOTYPE_USER_IPCAM_START, (char *)&ioMsg, sizeof(SMsgAVIoctrlAVStream)) < 0))
    {
        NSLog(@"start_ipcam_stream_failed[%d]", ret);
        return 0;
    }
    
    if ((ret = avSendIOCtrl(avIndex, IOTYPE_USER_IPCAM_AUDIOSTART, (char *)&ioMsg, sizeof(SMsgAVIoctrlAVStream)) < 0))
    {
        NSLog(@"start_ipcam_stream_failed[%d]", ret);
        return 0;
    }
    
    return 1;
}

void *start_main (NSString *UID) {
    int ret, SID;
    
    NSLog(@"AVStream Client Start");
    
//    ret = IOTC_Initialize2(0);
    ret = IOTC_Initialize(0, "46.137.188.54", "122.226.84.253", "m2.iotcplatform.com", "m5.iotcplatform.com");
    NSLog(@"IOTC_Initialize() ret = %d", ret);
    
    if (ret != IOTC_ER_NoERROR) {
        NSLog(@"IOTCAPIs exit...");
        return NULL;
    }
    
    // alloc 4 sessions for video and two-way audio
    avInitialize(4);
    
    SID = IOTC_Get_SessionID();
    ret = IOTC_Connect_ByUID_Parallel((char *)[UID UTF8String], SID);
    
    printf("Step 2: call IOTC_Connect_ByUID_Parallel(%s) ret(%d).......\n", [UID UTF8String], ret);
    struct st_SInfo Sinfo;
    ret = IOTC_Session_Check(SID, &Sinfo);
    
    if (ret >= 0)
    {
        if(Sinfo.Mode == 0)
            printf("Device is from %s:%d[%s] Mode=P2P\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
        else if (Sinfo.Mode == 1)
            printf("Device is from %s:%d[%s] Mode=RLY\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
        else if (Sinfo.Mode == 2)
            printf("Device is from %s:%d[%s] Mode=LAN\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
    }
    
    unsigned int srvType;
    int avIndex = avClientStart(SID, "admin", "12345678", 20000, &srvType, 0);
    //    int nResend;
    //    unsigned int srvType;
//     int avIndex = avClientStart2(SID, "admin", "12345678", 20000, &srvType, 0, &nResend);
    printf("Step 3: call avClientStart(%d).......\n", avIndex);

    if(avIndex < 0)
    {
        printf("avClientStart failed[%d]\n", avIndex);
        return NULL;
    }

    if (start_ipcam_stream(avIndex)>0)
    {
        pthread_t ThreadVideo_ID, ThreadAudio_ID;
        pthread_create(&ThreadVideo_ID, NULL, &thread_ReceiveVideo, (void *)&avIndex);
        pthread_create(&ThreadAudio_ID, NULL, &thread_ReceiveAudio, (void *)&avIndex);
        pthread_join(ThreadVideo_ID, NULL);
        pthread_join(ThreadAudio_ID, NULL);
    }
    
    avClientStop(avIndex);
    NSLog(@"avClientStop OK");
    IOTC_Session_Close(SID);
    NSLog(@"IOTC_Session_Close OK");
    avDeInitialize();
    IOTC_DeInitialize();
    
    NSLog(@"StreamClient exit...");
    return nil;
}

- (void)start:(NSString *)UID {
    pthread_t main_thread;
    pthread_create(&main_thread, NULL, &start_main, (__bridge void *)UID);
    pthread_detach(main_thread);
    
}

@end