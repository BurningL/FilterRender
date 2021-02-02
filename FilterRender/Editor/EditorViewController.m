//
//  EditorViewController.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "EditorViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "EditorVideoCompositing.h"
#import "EditorCompositionInstruction.h"
#import "HYRenderManager.h"

@interface EditorViewController ()<EditorCompositionInstructionDelegete>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;


@end

@implementation EditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPlayer];
}

- (void)dealloc{
    [[HYRenderManager shareManager] cleanGreenScreen];
    NSLog(@"EditorViewController dealloc");
}

- (void)setupPlayer {
    self.view.bounds = [UIScreen mainScreen].bounds;
    // asset
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"greenscreen" withExtension:@"mp4"];
    self.asset = [AVURLAsset assetWithURL:url];
    
    // videoComposition
    self.videoComposition = [self createVideoCompositionWithAsset:self.asset];
    self.videoComposition.customVideoCompositorClass = [EditorVideoCompositing class];
    
    // playerItem
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
    self.playerItem.videoComposition = self.videoComposition;
    
    // player
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    
    // playerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0,
                                        0,
                                        self.view.frame.size.width,
                                        self.view.frame.size.width);
    self.playerLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds),
                                            CGRectGetMidY(self.view.bounds));
    [self.view.layer addSublayer:self.playerLayer];
    
    [self.player play];
}

- (IBAction)addPicture:(id)sender {
    [[HYRenderManager shareManager] showGreenScreenWithImage:[UIImage imageNamed:@"abc2"]];
}

- (IBAction)addVideo:(id)sender {
    NSURL *bgUrl = [[NSBundle mainBundle] URLForResource:@"mov_bbb" withExtension:@"mp4"];
    [[HYRenderManager shareManager] showGreenScreenWithVideoUrl:bgUrl];
}

- (IBAction)cleanAll:(id)sender {
    [[HYRenderManager shareManager] cleanGreenScreen];
}

- (AVMutableVideoComposition *)createVideoCompositionWithAsset:(AVAsset *)asset {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];
    NSArray *instructions = videoComposition.instructions;
    NSMutableArray *newInstructions = [NSMutableArray array];
    for (AVVideoCompositionInstruction *instruction in instructions) {
        NSArray *layerInstructions = instruction.layerInstructions;
        // TrackIDs
        NSMutableArray *trackIDs = [NSMutableArray array];
        for (AVVideoCompositionLayerInstruction *layerInstruction in layerInstructions) {
            [trackIDs addObject:@(layerInstruction.trackID)];
        }
        EditorCompositionInstruction *newInstruction = [[EditorCompositionInstruction alloc] initWithSourceTrackIDs:[trackIDs copy] timeRange:instruction.timeRange];
        newInstruction.delegete = self;
        newInstruction.foregroundTrackID = [((NSNumber *)instruction.requiredSourceTrackIDs.firstObject) intValue];
        [newInstructions addObject:newInstruction];
    }
    videoComposition.instructions = newInstructions;
    return videoComposition;
}

#pragma mark - EditorCompositionInstructionDelegete

- (CVPixelBufferRef)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return [[HYRenderManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
