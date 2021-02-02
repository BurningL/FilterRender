//
//  GPUImageGreenScreenFilter.m
//  FilterRender
//
//  Created by liuhongyang on 2021/1/31.
//  Copyright © 2021 Burning. All rights reserved.
//

#import "GPUImageGreenScreenFilter.h"

/*
 计算当前像素点RGB值对应的HSV值

 设定HSV三个分量的权重，根据权重计算当前像素点的HSV值到给定背景色的HSV值的欧式距离

 将欧式距离用smoothstep做平滑，0.5以下的一定要滤掉

 将原图和背景图用平滑值混合
 */

NSString *const kGPUImageGreenScreenFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);

    lowp float rbAverage = textureColor.r * 0.5 + textureColor.b * 0.5;
    lowp float gDelta = textureColor.g - rbAverage;
    textureColor.a = 1.0 - smoothstep(0.0, 0.25, gDelta);
    if(textureColor.a < 0.5){
        gl_FragColor = textureColor2;
    }else{
        gl_FragColor = textureColor;
    }
 }
);


@implementation GPUImageGreenScreenFilter

- (id)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageGreenScreenFragmentShaderString];
    if (self) {
        
    }
    return self;
}

@end
