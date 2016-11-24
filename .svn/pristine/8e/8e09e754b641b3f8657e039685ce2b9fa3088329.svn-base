//
//  HardwareDecoder.h
//  AVSamplePlayer
//
//  Created by bingcai on 16/7/8.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol HardwareDecoderDelegate <NSObject>

- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer;

@end

@interface HardwareDecoder : NSObject

@property(nonatomic, weak) id<HardwareDecoderDelegate> delegate;

- (void)receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize;

- (void)hardwareDecode:(uint8_t *)buf size:(int)inSize;

@end
