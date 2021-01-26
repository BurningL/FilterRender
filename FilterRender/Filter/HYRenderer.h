//
//  HYRenderer.h
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYRenderer : NSObject

- (CVPixelBufferRef)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end

NS_ASSUME_NONNULL_END
