//
//  MBVideoViewController.m
//  MBBeautifyFace
//
//  Created by meitu on 2018/5/18.
//  Copyright © 2018年 chenda. All rights reserved.
//

#import "MBVideoViewController.h"

#import <CoreImage/CoreImage.h>

#import "GPUImage.h"

#import "GPUImageCustomColorInvertFilter.h"

@interface MBVideoViewController ()<GPUImageVideoCameraDelegate>

@property (nonatomic, strong) GPUImageView *videoView; //视频显示的View
@property (nonatomic, strong) GPUImageVideoCamera *camera; //摄像类
@property (nonatomic, strong) GPUImageCustomColorInvertFilter *customColorInvertFilter; //自定义滤镜
@property (nonatomic, assign) BOOL faceThinking; //判断帧是否在人脸识别处理中
@property (nonatomic, strong) CIDetector *faceDetector; //人脸检测类
@property (nonatomic, strong) UIView *faceView;  // 标注人脸的红框

@end

@implementation MBVideoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initVideoView];
    [self initFaceDetector];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.camera startCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Accessors

- (GPUImageView *)videoView {
    if (!_videoView) {
        _videoView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    
    return _videoView;
}

- (GPUImageVideoCamera *)camera {
    if (!_camera) {
        _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
//        _camera.horizontallyMirrorFrontFacingCamera = YES;
        [_camera addAudioInputsAndOutputs];
        _camera.delegate = self;  //最关键的一步，通过代理方法，获取视频传过来的每一帧的图像。
    }
    
    return _camera;
}

#pragma mark - IBActions

#pragma mark - Public

#pragma mark - Private
//初始化视频显示
- (void)initVideoView {
    [self.view addSubview:self.videoView];
    self.customColorInvertFilter = [[GPUImageCustomColorInvertFilter alloc] init];
    [self.camera addTarget:self.customColorInvertFilter];
    [self.customColorInvertFilter addTarget:self.videoView];
}

//初始化脸部检测器
- (void)initFaceDetector {
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow,CIDetectorAccuracy, nil];
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    self.faceThinking = NO;
}

#pragma mark - GPUImageVideoCameraDelegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.faceThinking) {
        CFAllocatorRef allocator = CFAllocatorGetDefault();
        CMSampleBufferRef sbufCopyOut;
        CMSampleBufferCreateCopy(allocator, sampleBuffer, &sbufCopyOut);//如果对帧的处理需要比较长的话，copy它，后面自己释放
        
        [self performSelectorInBackground:@selector(grepFacesForSampleBuffer:) withObject:CFBridgingRelease(sbufCopyOut)];
    }
}

//从buffer中获取CIImage
- (void)grepFacesForSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    self.faceThinking = YES;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    
    //从帧中获取到的图片相对镜头下看到的会向左旋转90度，所以后续坐标的转换要注意。
    CIImage *convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
    if (attachments) {
        CFRelease(attachments);
    }
    
    NSDictionary *imageOptions = nil;
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    int exifOrientation;
    
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT          = 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT         = 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };
    
    BOOL isUsingFrontFacingCamera = NO;
    
    AVCaptureDevicePosition currentCameraPosition = [self.camera cameraPosition];
    
    if (currentCameraPosition != AVCaptureDevicePositionBack) {
        isUsingFrontFacingCamera = YES;
    }
    
    switch (curDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (isUsingFrontFacingCamera) {
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            }else {
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            }
            
            break;
        case UIDeviceOrientationLandscapeRight:
            if (isUsingFrontFacingCamera) {
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            }else {
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            }
            
            break;
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP; //值为6。确定初始化原点坐标的位置，坐标原点为右上。其中横的为y，竖的为x，表示真实想要显示图片需要顺时针旋转90度
            break;
    }
    
    //exifOrientation的值用于确定图片的方向
    imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    
    NSArray *features = [self.faceDetector featuresInImage:convertedImage options:imageOptions];
    
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false); //图片的显示大小
    
    [self outputFeatures:features forClap:clap];
    
    self.faceThinking = NO;
    //test001
}

//根据features计算坐标区域
- (void)outputFeatures:(NSArray*)featureArray forClap:(CGRect)clap {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect previewBox = self.view.frame;
        
        if (featureArray == nil && self.faceView) {
            [self.faceView removeFromSuperview];
            self.faceView = nil;
        }
        
        for (CIFeature *feature in featureArray) {
            CGRect faceRect = feature.bounds;
            CGFloat temp = faceRect.size.width;
            faceRect.size.width = faceRect.size.height; //长宽互换
            faceRect.size.height = temp;

            temp = faceRect.origin.x;
            faceRect.origin.x = faceRect.origin.y;
            faceRect.origin.y = temp;
            
            [self.customColorInvertFilter setMask:faceRect];
            
            CGFloat widthScale = previewBox.size.width / clap.size.height;
            CGFloat heightScale = previewBox.size.height / clap.size.width;
            
            faceRect.size.height *= heightScale;
            faceRect.size.width *= widthScale;
            faceRect.origin.x *= widthScale;
            faceRect.origin.y *= heightScale;
            
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
            
            if (self.faceView) {
                [self.faceView removeFromSuperview];
                self.faceView = nil;
            }
            
            self.faceView = [[UIView alloc] initWithFrame:faceRect];
            
            self.faceView.layer.borderColor = [UIColor redColor].CGColor;
            self.faceView.layer.borderWidth = 1;

//            [self.view addSubview:self.faceView];
        }
    });
}

@end
