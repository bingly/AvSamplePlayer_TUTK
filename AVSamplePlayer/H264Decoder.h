//
//  H264Decoder.h
//  AVSamplePlayer
//
//  Created by bingcai on 16/7/1.
//  Copyright © 2016年 sharetronic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>


@interface H264Decoder : NSObject


@property (nonatomic) int outputWidth, outputHeight;

/* Last decoded picture as UIImage */
@property (nonatomic, readonly) UIImage *currentImage;

- (void)videoDecoder_init;
//decode nalu 
- (CGSize)videoDecoder_decodeToImage:(uint8_t *)nalBuffer size:(int)inSize timeStamp:(unsigned int)pts;

@end
