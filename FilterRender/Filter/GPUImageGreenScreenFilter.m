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
//     textureColor.a = textureColor.a * textureColor.a * textureColor.a;
//     gl_FragColor = textureColor;
 }
);

/*
 // lookup the color of the texel corresponding to the fragment being
 // generated while rendering a triangle
 lowp vec4 tempColor = texture2D(uVideoframe, vCoordinate);
 
 // Calculate the average intensity of the texel's red and blue components
 lowp float rbAverage = tempColor.r * 0.5 + tempColor.b * 0.5;
 
 // Calculate the difference between the green element intensity and the
 // average of red and blue intensities
 lowp float gDelta = tempColor.g - rbAverage;
 
 // If the green intensity is greater than the average of red and blue
 // intensities, calculate a transparency value in the range 0.0 to 1.0
 // based on how much more intense the green element is
 tempColor.a = 1.0 - smoothstep(0.0, 0.25, gDelta);
 
 // Use the cube of the of the transparency value. That way, a fragment that
 // is partially translucent becomes even more translucent. This sharpens
 // the final result by avoiding almost but not quite opaque fragments that
 // tend to form halos at color boundaries.
 tempColor.a = tempColor.a * tempColor.a * tempColor.a;
    
  gl_FragColor = tempColor;
 
 */


/*
 
 textureColor.r == 75.0 && textureColor.g == 249.0 && textureColor.b == 44.0
 
 R:75

 G:249

 B:44
 */

@implementation GPUImageGreenScreenFilter

- (id)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageGreenScreenFragmentShaderString];
    if (self) {
        
    }
    return self;
}

@end
