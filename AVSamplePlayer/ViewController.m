//
//  ViewController.m
//  AVSamplePlayer
//
//  Created by bingcai on 16/6/27.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "Client.h"
#import "H264Decoder.h"

#import "TEST.h"
#import "OpenAL2.h"
#import "PCMDataPlayer.h"
#import "PCMAudioRecorder.h"

#import "AVAPIs.h"
#import "AVIOCTRLDEFs.h"
#import "IOTCAPIs.h"
#import "AVFRAMEINFO.h"

#define MAX_SIZE_IOCTRL_BUF		1024

@interface ViewController () <PCMAudioRecorderDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation ViewController {

    BOOL                isFindIFrame;
    BOOL                _firstDecoded;
    CGRect              rect;
    
    H264Decoder         *_decoder;
//    openal
    OpenAL2 *_openAl2;
    PCMDataPlayer *_pcmDataPlayer;
    PCMAudioRecorder *_pcmRecorder;
    int  _avchannelForSendAudioData;
    FILE *_pcmFile;
    unsigned int _timeStamp;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    Client *client = [[Client alloc] init];

#warning 换成自己摄像头的UID
    [client start:@"CHPA9X74URV4UNPGYHEJ"]; // Put your device's UID here.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveBuffer:) name:@"client" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveAudioData:) name:@"audio" object:nil];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    rect = CGRectMake(0, 20, screenWidth, screenWidth * 3 / 4);
    UIView *containerView = [[UIView alloc] initWithFrame:rect];
    
    self.imageView = [[UIImageView alloc] initWithFrame:rect];
    self.imageView.image = [self getBlackImage];
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicatorView.frame = CGRectMake(rect.size.width / 2, rect.size.height / 2, self.indicatorView.frame.size.width, self.indicatorView.frame.size.height);
    
    [containerView addSubview:self.imageView];
    [containerView addSubview:self.indicatorView];
    [self.view addSubview:containerView];
    [self.indicatorView startAnimating];
    
    [self initData];
    [self testButton];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        [self receiveIOCtrl];
//    });

//     _pcmFile = fopen("/Users/XCHF-ios/Documents/first.pcm", "w");
}

- (void)initData {
    
    _decoder = [[H264Decoder alloc] init];
    [_decoder videoDecoder_init];
    
//    音频播放
    _openAl2     = [[OpenAL2 alloc] init];
    [_openAl2 initOpenAl];
    
    _pcmDataPlayer = [[PCMDataPlayer alloc] init];
    _pcmRecorder   = [[PCMAudioRecorder alloc] init];
    _pcmRecorder.delegate = self;
    _timeStamp = 750492;
}

- (void)testButton {

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20, 300, 100, 44)];
    button.backgroundColor = [UIColor greenColor];
    [button setTitle:@"Record" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(200, 300, 100, 44)];
    button1.backgroundColor = [UIColor greenColor];
    [button1 setTitle:@"sendTest" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(sendTest) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button1];
}

- (void)startRecord {

    SMsgAVIoctrlAVStream ioMsg;
    memset(&ioMsg, 0, sizeof(SMsgAVIoctrlAVStream));
    
    _avchannelForSendAudioData =IOTC_Session_Get_Free_Channel(0);
    if (_avchannelForSendAudioData<0) {
        NSLog(@"have some thing wrong");
        return;
    }
    
    ioMsg.channel = _avchannelForSendAudioData;
    int ret = avSendIOCtrl(0, IOTYPE_USER_IPCAM_SPEAKERSTART, (char *)&ioMsg,                                         sizeof(SMsgAVIoctrlAVStream));
    int ret1 = avServStart(0, NULL, NULL, 60, 0, _avchannelForSendAudioData);
    NSLog(@"ret: %d ret1:%d _avchannelForSendAudioData: %d", ret, ret1, _avchannelForSendAudioData);
    
    if (ret1 >= 0) {
        [_pcmRecorder startRecord];
        _avchannelForSendAudioData = ret1;
    }
}

#pragma mark Receive Audio Data
- (void)DidGetAudioData:(void *const)buffer size:(int)dataSize {

    FRAMEINFO_t frameInfo;
    frameInfo.codec_id = 0x89;
    frameInfo.flags =0;
    frameInfo.cam_index=0;
    frameInfo.onlineNum =1;
//    frameInfo.timestamp = (unsigned int)([[NSDate date] timeIntervalSince1970]*1000);
//    NSLog(@"%d", frameInfo.timestamp);
    frameInfo.timestamp = _timeStamp ++;
    
    unsigned char requestBuf[dataSize / 2];
    G711Encoder(buffer, requestBuf, dataSize / 2, 1);
    
    int ret = avSendAudioData(_avchannelForSendAudioData, (char *)requestBuf,dataSize/2,(char *)&frameInfo, sizeof(FRAMEINFO_t));
    if (ret>=0) {
//        NSLog(@"send  audio success");
        NSLog(@"%d", frameInfo.timestamp);
    }else
        NSLog(@"send audio failed---->%d",ret);
    
    short decodeBuf[dataSize];
    G711Decode(decodeBuf, requestBuf, dataSize / 2);
//    fwrite(decodeBuf, 1, dataSize, _pcmFile);
}

- (void)stopRecord {
    [_pcmRecorder stopRecord];
}

- (void)sendTest {

    SMsgAVIoctrlGetStreamCtrlReq *s = (SMsgAVIoctrlGetStreamCtrlReq *)malloc(sizeof(SMsgAVIoctrlGetStreamCtrlReq));
    s->channel = 0;
    int ret = avSendIOCtrl(0, IOTYPE_USER_IPCAM_GETSTREAMCTRL_REQ, (char *)s, sizeof(SMsgAVIoctrlGetStreamCtrlReq));
    free(s);
    NSLog(@"%d",ret);
}

- (void)listWiFiAP {

    SMsgAVIoctrlListWifiApReq *structListWiFi = (SMsgAVIoctrlListWifiApReq *)malloc(sizeof(SMsgAVIoctrlListWifiApReq));
    memset(structListWiFi, 0, sizeof(SMsgAVIoctrlListWifiApReq));
    int ret = avSendIOCtrl(0, IOTYPE_USER_IPCAM_LISTWIFIAP_REQ, (char *)structListWiFi, sizeof(SMsgAVIoctrlListWifiApReq));
    NSLog(@"listWiFiAP: %d", ret);
    free(structListWiFi);
}

#pragma mark receive IO ctrl
- (void)receiveIOCtrl {

    int ret;
    unsigned int ioType;
    char ioCtrlBuf[MAX_SIZE_IOCTRL_BUF];
    
    while (1) {
        ret = avRecvIOCtrl(0, &ioType, (char *)&ioCtrlBuf, MAX_SIZE_IOCTRL_BUF, 1000);
        usleep(1000000);
        NSLog(@"avRecvIOCtrl: %d, %d", ioType, ret);
        if (ret > 0) {
            NSLog(@"avRecvIOCtrl: %d", ioType);
        }
        
        if (ioType == IOTYPE_USER_IPCAM_LISTWIFIAP_RESP) {
            SMsgAVIoctrlListWifiApResp *s = (SMsgAVIoctrlListWifiApResp *)ioCtrlBuf;
            for (int i = 0; i < s->number; ++i) {
                
                SWifiAp ap = s->stWifiAp[i];
                NSLog(@"WiFi Name: %s", ap.ssid);
            }
        }
    }
}

#pragma mark 音频处理
- (void)receiveAudioData:(NSNotification *)notification {

    if (!isFindIFrame) {
        return;
    }
    
    NSDictionary *dict = (NSDictionary *)notification.object;
    NSLog(@"receive: %d", [[dict objectForKey:@"sequence"] intValue]);
    NSData *audioData = [dict objectForKey:@"data"];
    uint8_t *buf = (uint8_t *)[audioData bytes];
    int length = (int)[audioData length];
//    fwrite(buf, 1, length, _pcmFile);
    short  requestBuf[length * 2];
//    int l = G711Decode(requestBuf, (unsigned char*)buf, length);
    int l = g711u_decode(requestBuf, (unsigned char *)buf, length);
    
    //open AL
//    NSData *data = [NSData dataWithBytes:requestBuf length:l];
//    [_openAl2 openAudio:data length:l];
    
//    audio queue
//    fwrite(requestBuf, 1, l, _pcmFile);
    [_pcmDataPlayer play:requestBuf length:l];
}

#pragma mark select decode way
- (void)receiveBuffer:(NSNotification *)notification{
    NSDictionary *dict = (NSDictionary *)notification.object;
    NSData *dataBuffer = [dict objectForKey:@"data"];
    unsigned int videoPTS = [[dict objectForKey:@"timestamp"] unsignedIntValue];
//    NSLog(@"receive: %d", [[dict objectForKey:@"sequence"] intValue]);
    int number =  (int)[dataBuffer length];
    uint8_t *buf = (uint8_t *)[dataBuffer bytes];
    
    if (!isFindIFrame && ![self detectIFrame:buf size:number]) {
        return;
    }

    [self decodeFramesToImage:buf size:number timeStamp:videoPTS];
}

- (void)decodeFramesToImage:(uint8_t *)nalBuffer size:(int)inSize timeStamp:(unsigned int)pts {
    
//    调节分辨率后，能自适应，但清晰度有问题
//    经过确认，是output值设置的问题。outputWidth、outputHeight代表输出图像的宽高，设置的和分辨率一样，是最清晰的效果
    CGSize fSize = [_decoder videoDecoder_decodeToImage:nalBuffer size:inSize timeStamp:pts];
    if (fSize.width == 0) {
        return;
    }
    
    UIImage *image = [_decoder currentImage];
    
    if (image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    }
}


#pragma mark public method
- (BOOL)detectIFrame:(uint8_t *)nalBuffer size:(int)size {

    NSString *string1 = @"";
    int dataLength = size > 100 ? 100 : size;
    for (int i = 0; i < dataLength; i ++) {
        NSString *temp = [NSString stringWithFormat:@"%x", nalBuffer[i]&0xff];
        if ([temp length] == 1) {
            temp = [NSString stringWithFormat:@"0%@", temp];
        }
        string1 = [string1 stringByAppendingString:temp];
    }
//    NSLog(@"%d,,%@",size,string1);
    NSRange range = [string1 rangeOfString:@"00000000165"];
    if (range.location == NSNotFound) {
        isFindIFrame = NO;
        return NO;
    } else {
        isFindIFrame = YES;
        [self.indicatorView stopAnimating];
        return YES;
    }

}

- (UIImage *)getBlackImage {

    CGSize imageSize = CGSizeMake(50, 50);
    UIGraphicsBeginImageContextWithOptions(imageSize, 0, [UIScreen mainScreen].scale);
    [[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0] set];
    UIRectFill(CGRectMake(0, 0, imageSize.width, imageSize.height));
    UIImage *pressedColorImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return pressedColorImg;
}

@end
