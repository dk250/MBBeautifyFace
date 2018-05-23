//
//  GPUImageCustomColorInvertFilter.m
//  MBBeautifyFace
//
//  Created by meitu on 2018/5/18.
//  Copyright © 2018年 chenda. All rights reserved.
//

#import "GPUImageCustomColorInvertFilter.h"

NSString *const kGPUImageCustomInvertFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform lowp vec4 mask;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     if(gl_FragCoord.x < (mask.x + mask.z) && gl_FragCoord.y < (mask.y + mask.w) && gl_FragCoord.x > mask.x && gl_FragCoord.y > mask.y) {
         gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
     }else {
         gl_FragColor = textureColor;
     }
 }
);

@interface GPUImageCustomColorInvertFilter() {
    GLint maskUniform;
}

@end

@implementation GPUImageCustomColorInvertFilter

- (id)init;
{
    if ((self = [super initWithFragmentShaderFromString:kGPUImageCustomInvertFragmentShaderString])) {
        maskUniform = [filterProgram uniformIndex:@"mask"];
    }
    
    return self;
}

- (void)setMask:(CGRect)mask {
    _mask = mask;
    
    GPUVector4 maskVector4 = {mask.origin.x, mask.origin.y, mask.size.width, mask.size.height};
    [self setVec4:maskVector4 forUniform:maskUniform program:filterProgram];
}

@end
