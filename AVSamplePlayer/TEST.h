//
//  TEST.h
//  AVSamplePlayer
//
//  Created by bingcai on 16/8/8.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TEST : NSObject

int g711u_decode(short amp[], const unsigned char g711u_data[], int g711u_bytes);

int G711Decode(char* pRawData,const unsigned char* pBuffer, int nBufferSize);

void G711Encoder(void *pcm,unsigned char *code,int size,int lawflag);

@end
