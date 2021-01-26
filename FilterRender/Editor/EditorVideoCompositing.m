//
//  EditorVideoCompositing.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "EditorVideoCompositing.h"
#import <AVFoundation/AVFoundation.h>
#import "EditorCompositionInstruction.h"

@interface EditorVideoCompositing ()

@property (nonatomic, strong) dispatch_queue_t renderContextQueue;
@property (nonatomic, strong) dispatch_queue_t renderingQueue;
@property (nonatomic, assign) BOOL shouldCancelAllRequests;

@property (nonatomic, strong) AVVideoCompositionRenderContext *renderContext;

@end

@implementation EditorVideoCompositing

- (instancetype)init {
    self = [super init];
    if (self) {
        _renderContextQueue = dispatch_queue_create("com.videofilter.rendercontextqueue", 0);
        _renderingQueue = dispatch_queue_create("com.videofilter.renderingqueue", 0);
    }
    return self;
}

- (NSDictionary *)sourcePixelBufferAttributes {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey :@YES};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : @YES};
}


- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    dispatch_sync(self.renderContextQueue, ^{
        self.renderContext = newRenderContext;
    });
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request {
    @autoreleasepool {
        dispatch_async(self.renderingQueue,^() {
            if (self.shouldCancelAllRequests) {
                [request finishCancelledRequest];
            } else {
                NSError *err = nil;
                CVPixelBufferRef resultPixels = [self newRenderdPixelBufferForRequest:request error:&err];
                if (resultPixels) {
                    [request finishWithComposedVideoFrame:resultPixels];
                } else {
                    [request finishWithError:err];
                }
            }
        });
    }
}

- (void)cancelAllPendingVideoCompositionRequests {
    self.shouldCancelAllRequests = YES;
    dispatch_barrier_async(self.renderingQueue, ^{
        self.shouldCancelAllRequests = NO;
    });
}

#pragma mark - Private

- (CVPixelBufferRef)newRenderdPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)error{
    
    id<AVVideoCompositionInstruction> compositionInstruction = request.videoCompositionInstruction;
    if ([compositionInstruction isKindOfClass:[EditorCompositionInstruction class]]) {
        EditorCompositionInstruction *videoInstruction = (EditorCompositionInstruction *)compositionInstruction;
        CMPersistentTrackID trackId = videoInstruction.foregroundTrackID;
        CVPixelBufferRef sourcePixelBuffer = [request sourceFrameByTrackID:trackId];
        CVPixelBufferRef resultPixelBuffer = [videoInstruction applyPixelBuffer:sourcePixelBuffer currentTime:request.compositionTime];
        return resultPixelBuffer;
    }
    return nil;
}


@end
