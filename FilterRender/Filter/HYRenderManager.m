//
//  HYRenderManager.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "HYRenderManager.h"
#import "HYRenderer.h"


@interface HYRenderManager ()

@property (nonatomic,strong) HYRenderer *renderer;

@end

@implementation HYRenderManager

static HYRenderManager *manager;
+ (instancetype)shareManager {
    if (manager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            manager = [HYRenderManager new];
        });
    }
    return manager;
}


#pragma mark - Lut

- (void)loadLutItems
{
    
}

- (void)selectLutFilter:(NSInteger)index
{
    
}

#pragma mark - 动画

- (void)loadMotionItems
{
    
}


#pragma mark - 绿幕
- (void)showGreenScreenWithImage:(UIImage *)image
{
    [self.renderer showGreenScreenWithImage:image];
}

- (void)showGreenScreenWithVideoUrl:(NSURL *)videoUrl
{
    [self.renderer showGreenScreenWithVideoUrl:videoUrl];
}

- (void)cleanGreenScreen{
    [self.renderer cleanGreenScreen];
}


- (void)loadAllItems
{
    [self loadLutItems];
}

- (void)getLandmarks:(NSArray *)landmarks
{
    
}

- (BOOL)hasFace{
    return YES;
}

- (CVPixelBufferRef)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return [self.renderer renderPixelBuffer:pixelBuffer];
}

- (HYRenderer *)renderer
{
    if (!_renderer) {
        _renderer = [[HYRenderer alloc] init];
    }
    return _renderer;
}

@end
