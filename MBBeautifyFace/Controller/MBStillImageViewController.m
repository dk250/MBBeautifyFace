//
//  MBStillImageViewController.m
//  MBBeautifyFace
//
//  Created by meitu on 2018/5/18.
//  Copyright © 2018年 chenda. All rights reserved.
//

#import "MBStillImageViewController.h"

#import <CoreImage/CoreImage.h>

#import "GPUImage.h"

#import "GPUImageBeautifyFilter.h"
#import "GPUImageCustomColorInvertFilter.h"

@interface MBStillImageViewController ()

@property (nonatomic, strong) GPUImageView *imageView; //最终效果显示View
@property (nonatomic, strong) UIImage *faceImage; //静态图片
@property (nonatomic, strong) GPUImagePicture *sourcePicture; //GPUImage的静态图源
@property (nonatomic, assign) CGRect faceRigion; //人脸识别区域
@property (nonatomic, strong) GPUImageCustomColorInvertFilter *customFilter; //自定义滤镜
@property (nonatomic, assign) float widthScale; //实际图片宽度和UIImageView显示宽度的比例
@property (nonatomic, assign) float heigthScale; //实际图片长度和UIImageView显示长度的比例

@end

@implementation MBStillImageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.imageView];
    
    [self showFeatures];
    [self addFilter];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Custom Accessors

- (UIImage *)faceImage {
    if (!_faceImage) {
        _faceImage = [UIImage imageNamed:@"face"];
    }
    
    return _faceImage;
}

#pragma mark - IBActions

#pragma mark - Public

#pragma mark - Private

//识别人脸，并在界面上使用红框标出人脸
- (void)showFeatures {
    UIView *resultView = [[UIView alloc] initWithFrame:self.imageView.bounds];
    [self.imageView addSubview:resultView];
    
    NSArray *features = [self detectFaceWithImage:self.faceImage];
    
    CGSize imageViewSize = self.imageView.frame.size;
    CGSize imageSize = self.faceImage.size;
    
    self.widthScale = imageSize.width / imageViewSize.width;
    self.heigthScale = imageSize.height / imageViewSize.height;
    
    for (CIFaceFeature *feature in features) {
        self.faceRigion = feature.bounds; //保存当前的脸部区域坐标
        
        CGRect rect = CGRectMake(feature.bounds.origin.x / self.widthScale, feature.bounds.origin.y / self.heigthScale, feature.bounds.size.width / self.widthScale, feature.bounds.size.height / self.widthScale);
        
        UIView *redView  = [self redRectangleViewWithFrame:rect];
        
        //转换坐标方式2
//        CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
//        transform = CGAffineTransformTranslate(transform, 0, -self.imageView.bounds.size.height);
//        rect = CGRectApplyAffineTransform(rect, transform);
//        redView.frame = rect;
//        [self.view addSubview:redView];
        [resultView addSubview:redView];
    }
    
    resultView.layer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
}

//识别人脸，并返回人脸特征数组
- (NSArray *)detectFaceWithImage:(UIImage *)image {
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:dictionary];
    
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    
    NSArray *features = [detector featuresInImage:ciImage];
    
    if (features.count > 0) {
        return features;
    }
    
    return nil;
}

//根据frame，生成红色提示框
- (UIView *)redRectangleViewWithFrame:(CGRect)rect {
    UIView *redView = [[UIView alloc] initWithFrame:rect];
    redView.layer.borderColor = [UIColor redColor].CGColor;
    redView.layer.borderWidth = 1;
    
    return redView;
}

//添加滤镜
- (void)addFilter {
    self.sourcePicture = [[GPUImagePicture alloc] initWithImage:self.faceImage smoothlyScaleOutput:YES];
    
    self.customFilter = [[GPUImageCustomColorInvertFilter alloc] init];
    
    CGRect frame = self.faceRigion;
    //因为人脸识别出来的坐标系是以左下角为原点，所以要转换下y的值
    frame.origin.y = self.faceImage.size.height - self.faceRigion.size.height - self.faceRigion.origin.y;
    self.faceRigion = frame;
    
    self.customFilter.mask = self.faceRigion;
    [self.sourcePicture addTarget:self.customFilter];
    [self.customFilter addTarget:self.imageView];
    [self.sourcePicture processImage];
}

#pragma mark - Protocol conformance
@end
