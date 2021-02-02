//
//  HYRenderManager.h
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_OPTIONS(NSInteger,HYRenderFilterOptions) {
    HYRenderFilterOptionsBeauty = (1 << 0),//美颜
    HYRenderFilterOptionsLut = (1 << 1),//lut
    HYRenderFilterOptionsMotion = (1 << 2),//动画
    HYRenderFilterOptionsGreenScreen = (1 << 3),//绿幕
};

NS_ASSUME_NONNULL_BEGIN

@interface HYRenderManager : NSObject

#pragma mark - 美颜

@property (nonatomic,assign,readonly) BOOL hasFace;
@property (nonatomic,strong,readonly) NSArray *landmarks;

@property (nonatomic,assign) double blurLevel;//磨皮
@property (nonatomic,assign) double whiteLevel;//美白
@property (nonatomic,assign) double sharpenLevel;//清晰度

@property (nonatomic,assign) double bigEyeLevel;//大眼
@property (nonatomic,assign) double thinFaceLevel;//瘦脸

@property (nonatomic,assign) double eyeBrightLevel;//亮眼
@property (nonatomic,assign) double mouthBrightLevel;//嘴型

#pragma mark - Lut

@property (nonatomic,strong) NSArray *lutItems;

- (void)loadLutItems;

- (void)selectLutFilter:(NSInteger)index;

#pragma mark - 动画

- (void)loadMotionItems;


#pragma mark - 绿幕

- (void)showGreenScreenWithImage:(UIImage *)image;

- (void)showGreenScreenWithVideoUrl:(NSURL *)videoUrl;

- (void)cleanGreenScreen;



+ (HYRenderManager *)shareManager;

- (void)loadAllItems;

/* 暂时只支持BGRA格式 */
- (CVPixelBufferRef)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end

NS_ASSUME_NONNULL_END
