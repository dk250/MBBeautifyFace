//
//  ViewController.m
//  MBBeautifyFace
//
//  Created by meitu on 2018/5/18.
//  Copyright © 2018年 chenda. All rights reserved.
//

#import "ViewController.h"

#import "MBStillImageViewController.h"
#import "MBVideoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Accessors


#pragma mark - IBActions

//跳转到静态图效果界面
- (IBAction)goStillImageRecognize:(id)sender {
    MBStillImageViewController *stillImageViewController = [[MBStillImageViewController alloc] init];
    
    [self.navigationController pushViewController:stillImageViewController animated:YES];
}

//跳转到视频效果界面
- (IBAction)goVideoRecognize:(id)sender {
    MBVideoViewController *videoViewController = [[MBVideoViewController alloc] init];
    [self.navigationController pushViewController:videoViewController animated:YES];
}

#pragma mark - Public

#pragma mark - Private

#pragma mark - Protocol conformance

@end
