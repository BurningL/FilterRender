//
//  HYVideoCamera.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/26.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "HYVideoCamera.h"

@interface HYVideoCamera ()
{
    int sampleBufferWidth;
    int sampleBufferHeight;
    AVCaptureDevicePosition devicePosition;
    GLuint bgraTexture;
    GLProgram *bgraRotateProgram;
    GLint bgraPositionAttribute;
    GLint bgraTextureCoordinateAttribute;
    GLint bgraInputTextureUniform;
}

@end

@implementation HYVideoCamera

- (instancetype)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition;
{
    if (!(self = [super initWithSessionPreset:sessionPreset cameraPosition:cameraPosition]))
    {
        return nil;
    }
    self->devicePosition = [self cameraPosition];
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    runSynchronouslyOnVideoProcessingQueue(^{
        self->bgraRotateProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        if (!self->bgraRotateProgram.initialized)
        {
            [self->bgraRotateProgram addAttribute:@"position"];
            [self->bgraRotateProgram addAttribute:@"inputTextureCoordinate"];
            
            if (![self->bgraRotateProgram link])
            {
                NSString *progLog = [self->bgraRotateProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [self->bgraRotateProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [self->bgraRotateProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                self->bgraRotateProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        self->bgraPositionAttribute = [self->bgraRotateProgram attributeIndex:@"position"];
        self->bgraTextureCoordinateAttribute = [self->bgraRotateProgram attributeIndex:@"inputTextureCoordinate"];
        self->bgraInputTextureUniform = [self->bgraRotateProgram uniformIndex:@"inputImageTexture"];

        [GPUImageContext setActiveShaderProgram:self->bgraRotateProgram];
        glEnableVertexAttribArray(self->bgraPositionAttribute);
        glEnableVertexAttribArray(self->bgraTextureCoordinateAttribute);
    });
    return self;
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    if (capturePaused)
    {
        return;
    }
    
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [GPUImageContext useImageProcessingContext];
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(cameraFrame);
    
    CVOpenGLESTextureRef bgraTextureRef = NULL;
    
    bufferWidth = bytesPerRow / 4;
    if ( (sampleBufferWidth != bufferWidth) && (sampleBufferHeight != bufferHeight) )
    {
        sampleBufferWidth = bufferWidth;
        sampleBufferHeight = bufferHeight;
    }
    CVReturn err;
    glActiveTexture(GL_TEXTURE4);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &bgraTextureRef);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    bgraTexture = CVOpenGLESTextureGetName(bgraTextureRef);
    glBindTexture(GL_TEXTURE_2D, bgraTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    [self rotateBGRImageBuffer];
    
    int rotatedImageBufferWidth = bufferWidth, rotatedImageBufferHeight = bufferHeight;
    
    if (GPUImageRotationSwapsWidthAndHeight(internalRotation))
    {
        rotatedImageBufferWidth = bufferHeight;
        rotatedImageBufferHeight = bufferWidth;
    }
    
    [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:rotatedImageBufferWidth height:rotatedImageBufferHeight time:currentTime];
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    CFRelease(bgraTextureRef);
    
}

- (void)rotateBGRImageBuffer;
{
    [GPUImageContext setActiveShaderProgram:bgraRotateProgram];
    
    int rotatedImageBufferWidth = sampleBufferWidth, rotatedImageBufferHeight = sampleBufferHeight;
    
    if (GPUImageRotationSwapsWidthAndHeight(internalRotation))
    {
        rotatedImageBufferWidth = sampleBufferHeight;
        rotatedImageBufferHeight = sampleBufferWidth;
    }
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(rotatedImageBufferWidth, rotatedImageBufferHeight) textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, bgraTexture);
    glUniform1i(bgraInputTextureUniform, 4);
    glVertexAttribPointer(bgraPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(bgraTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [GPUImageFilter textureCoordinatesForRotation:internalRotation]);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
}

- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];//target下标
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
                
                if ([currentTarget wantsMonochromeInput] && captureAsYUV)
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:YES];
                    // TODO: Replace optimization for monochrome output
                    [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
                }
                else
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:NO];
                    [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
                }
            }
            else
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
            }
        }
    }
    
    // Then release our hold on the local framebuffer to send it back to the cache as soon as it's no longer needed
    [outputFramebuffer unlock];
    outputFramebuffer = nil;
    
    // Finally, trigger rendering as needed
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
            }
        }
    }
}



#pragma mark - Torch

- (BOOL)torchAvailable {
    return _inputCamera.torchAvailable;
}

- (void)switchTorch {
    BOOL isActive = _inputCamera.isTorchActive;
    
    NSError *error;
    [_inputCamera lockForConfiguration:&error];
    if (isActive) {
        if ([_inputCamera isTorchModeSupported:AVCaptureTorchModeOff]) {
            [_inputCamera setTorchMode:AVCaptureTorchModeOff];
        }
    } else {
        if ([_inputCamera isTorchModeSupported:AVCaptureTorchModeOn]) {
            [_inputCamera setTorchMode:AVCaptureTorchModeOn];
        }
    }
    [_inputCamera unlockForConfiguration];
}

- (void)dealloc {

}


@end
