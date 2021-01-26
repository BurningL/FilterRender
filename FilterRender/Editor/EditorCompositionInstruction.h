//
//  EditorCompositionInstruction.h
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol EditorCompositionInstructionDelegete <NSObject>

- (CVPixelBufferRef)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface EditorCompositionInstruction : NSObject <AVVideoCompositionInstruction>

@property (nonatomic,weak) id <EditorCompositionInstructionDelegete> delegete;

@property (nonatomic,assign) CMPersistentTrackID foregroundTrackID;
@property (nonatomic,assign) CMPersistentTrackID backgroundTrackID;

- (instancetype)initWithPassthroughTrackID:(CMPersistentTrackID)passthroughTrackID
                                 timeRange:(CMTimeRange)timeRange;

- (instancetype)initWithSourceTrackIDs:(NSArray<NSValue *> *)sourceTrackIDs
                             timeRange:(CMTimeRange)timeRange;

- (CVPixelBufferRef)applyPixelBuffer:(CVPixelBufferRef)pixelBuffer
                         currentTime:(CMTime)currentTime;

@end

NS_ASSUME_NONNULL_END
