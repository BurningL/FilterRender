//
//  RecorderViewController.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/25.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "RecorderViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HYRenderManager.h"
#import <GPUImage.h>
#import "HYVideoCamera.h"

@interface RecorderViewController ()<GPUImageVideoCameraDelegate>

@property (nonatomic,strong) GPUImageView *gpuView;
@property (nonatomic,strong) HYVideoCamera *videoCamera;

@end

@implementation RecorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupRecorder];
}

- (void)dealloc{
    [[HYRenderManager shareManager] cleanGreenScreen];
    NSLog(@"RecorderViewController dealloc");
}

- (void)setupRecorder{
    self.view.bounds = [UIScreen mainScreen].bounds;
    self.gpuView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.gpuView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [self.gpuView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.view insertSubview:self.gpuView atIndex:0];
    
    self.videoCamera = [[HYVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.frameRate = 25;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    [self.videoCamera addAudioInputsAndOutputs];
    self.videoCamera.delegate = self;
    
    [self.videoCamera addTarget:self.gpuView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startCaputureSession];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self stopCaputureSession];
    });
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

- (void)startCaputureSession
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.videoCamera startCameraCapture];
    });
}

- (void)stopCaputureSession
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.videoCamera stopCameraCapture];
    });
}

#pragma mark - GPUImageVideoCameraDelegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [[HYRenderManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
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
