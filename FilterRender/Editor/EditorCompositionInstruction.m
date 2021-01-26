//
//  EditorCompositionInstruction.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "EditorCompositionInstruction.h"

@interface EditorCompositionInstruction ()


@end

@implementation EditorCompositionInstruction

@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

- (instancetype)initWithPassthroughTrackID:(CMPersistentTrackID)passthroughTrackID
                                 timeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        _passthroughTrackID = passthroughTrackID;
        _timeRange = timeRange;
        _requiredSourceTrackIDs = @[];
        _containsTweening = NO;
        _enablePostProcessing = NO;
    }
    return self;
}

- (instancetype)initWithSourceTrackIDs:(NSArray<NSValue *> *)sourceTrackIDs
                             timeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _timeRange = timeRange;
        _requiredSourceTrackIDs = sourceTrackIDs;
        _containsTweening = YES;
        _enablePostProcessing = NO;
    }
    return self;
}

- (CVPixelBufferRef)applyPixelBuffer:(CVPixelBufferRef)pixelBuffer
                         currentTime:(CMTime)currentTime
{
    if([self.delegete respondsToSelector:@selector(renderPixelBuffer:)]){
       return [self.delegete renderPixelBuffer:pixelBuffer];
    }
    return pixelBuffer;
}




@end
