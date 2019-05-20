//
//  ViewController.m
//  CCPaySDKDemo
//
//  Created by iBlocker on 2019/5/16.
//  Copyright © 2019 iBlocker. All rights reserved.
//

#import "ViewController.h"
#import "CCPaySDK.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (IBAction)alipayTouchUpInside:(UIButton *)sender {
    //  支付宝支付
    __weak __typeof (self) weakSelf = self;
    [[CCPaySDK sharedSDK] payWithPayChannel:CCPayChannelALIPAY_MOBILE pay_params:@"AliPay Params" viewController:self completion:^(BOOL success, NSError * _Nonnull error) {
        NSLog(@"error --- %@", error);
        [weakSelf alertTitle:@"提示" alertMessage:error.userInfo[NSLocalizedDescriptionKey]];
    }];
}

- (IBAction)wechatpayTouchUpInside:(UIButton *)sender {
    //  微信支付
    __weak __typeof (self) weakSelf = self;
    [[CCPaySDK sharedSDK] payWithPayChannel:CCPayChannelWX_APP pay_params:@"WeChat Params" viewController:self completion:^(BOOL success, NSError * _Nonnull error) {
        NSLog(@"error --- %@", error);
        [weakSelf alertTitle:@"提示" alertMessage:error.userInfo[NSLocalizedDescriptionKey]];
    }];
}

- (IBAction)unionpayTouchUpInside:(UIButton *)sender {
    //  银联支付
    __weak __typeof (self) weakSelf = self;
    [[CCPaySDK sharedSDK] payWithPayChannel:CCPayChannelUNION_APP pay_params:@"UnionPay Params" viewController:self completion:^(BOOL success, NSError * _Nonnull error) {
        NSLog(@"error --- %@", error);
        [weakSelf alertTitle:@"提示" alertMessage:error.userInfo[NSLocalizedDescriptionKey]];
    }];
}

/**
 提示弹窗
 
 @param alertTitle 提示标题
 @param alertMessage 提示信息
 */
- (void)alertTitle:(NSString *)alertTitle
      alertMessage:(NSString *)alertMessage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"我知道了"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    [alert addAction:action];
    [self.topViewController presentViewController:alert animated:YES completion:nil];
}

/**
 获取最顶层的viewController
 */
- (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

- (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
}

@end
