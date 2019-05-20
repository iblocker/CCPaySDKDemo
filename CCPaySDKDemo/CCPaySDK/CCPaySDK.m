//
//  CCPaySDK.m
//  CCPaySDKDemo
//
//  Created by iBlocker on 2019/5/16.
//  Copyright © 2019 iBlocker. All rights reserved.
//

#import "CCPaySDK.h"
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
#import <MJExtension.h>
#import "UPPaymentControl.h"

@implementation CCWXAppPayParam

@end

@interface CCPaySDK () <WXApiDelegate>
/** 支付方式*/
@property (nonatomic, assign) CCPayChannel payChannel;
/** 完成回调*/
@property (nonatomic, copy) void(^completion)(BOOL success, NSError *error);
@end
@implementation CCPaySDK

static NSString *const CCPayErrorDomain    = @"CCPaySDKDemo Pay Error";

/**
 单例方法
 
 @return 单例对象
 */
+ (instancetype)sharedSDK {
    static dispatch_once_t onceToken;
    static CCPaySDK *paySDK = nil;
    dispatch_once(&onceToken, ^{
        paySDK = [[CCPaySDK alloc] init];
    });
    return paySDK;
}

/**
 注册微信支付 若要支持微信支付，则必须注册
 
 @param appId 微信AppId
 @return 注册结果
 */
- (BOOL)registerWXAppId:(NSString *)appId {
#ifdef DEBUG
    [WXApi startLogByLevel:WXLogLevelNormal logBlock:^(NSString *log) {
        NSLog(@"log : %@", log);
    }];
#else
#endif
    return [WXApi registerApp:appId enableMTA:NO];
}

/**
 打开支付Url
 
 @param url Url
 @return 是否打开
 */
- (BOOL)openPayURL:(NSURL *)url {
    __weak typeof (self) weakSelf = self;
    if ([url.host isEqualToString:@"pay"]) {
        //  微信
        [WXApi handleOpenURL:url delegate:self];
    } else if ([url.host isEqualToString:@"safepay"]) {
        //  支付宝
        //  跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:nil];
    } else /**if ([url.host isEqualToString:@"CCPaySDKDemoUnionPay"]) */{
        //  _clients    __NSCFString *    @"CCPaySDKDemoUnionPay://uppayresult?code=cancel&data="    0x00000002834e6ee0
        [[UPPaymentControl defaultControl] handlePaymentResult:url
                                                 completeBlock:^(NSString *code, NSDictionary *data) {
                                                     // 结果code为成功时，先校验签名，校验成功后做后续处理
                                                     if ([code isEqualToString:@"success"]) {
                                                         if (weakSelf.completion) { weakSelf.completion (YES, nil); }
                                                     } else if([code isEqualToString:@"fail"]) {
                                                         // 交易失败
                                                         NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                                                                              code:CCPayErrorCodeFailed
                                                                                          userInfo:@{NSLocalizedDescriptionKey : @"交易失败"}];
                                                         if (weakSelf.completion) { weakSelf.completion(NO, error); }
                                                     } else if([code isEqualToString:@"cancel"]) {
                                                         // 交易取消
                                                         NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                                                                              code:CCPayErrorCodeFailed
                                                                                          userInfo:@{NSLocalizedDescriptionKey : @"交易取消"}];
                                                         if (weakSelf.completion) { weakSelf.completion(NO, error); }
                                                     }
                                                 }];
    }
    return YES;
}

/**
 支付
 
 @param payChannel      支付方式
 @param pay_params      支付参数
 @param viewController  调起支付的视图控制器
 @param completion      完成回调
 */
- (void)payWithPayChannel:(CCPayChannel)payChannel
               pay_params:(NSString *)pay_params
           viewController:(UIViewController *)viewController
               completion:(void (^)(BOOL success, NSError *error))completion {
    self.payChannel = payChannel;
    switch (payChannel) {
        case CCPayChannelWX_APP: {
            //  微信支付
            if (![WXApi isWXAppInstalled]) {
                NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                                     code:CCPayErrorCodeNotInstalled
                                                 userInfo:@{NSLocalizedDescriptionKey:@"微信未安装"}];
                if (completion) { completion (NO, error); }
                return;
            }
            CCWXAppPayParam *payParam = [CCWXAppPayParam mj_objectWithKeyValues:pay_params];
            //  调起微信支付
            PayReq *req     = [[PayReq alloc] init];
            req.partnerId   = payParam.partnerId;
            req.prepayId    = payParam.prepayId;
            req.nonceStr    = payParam.nonceStr;
            req.timeStamp   = [payParam.timeStamp intValue];
            req.package     = payParam.packageValue;
            req.sign        = payParam.sign;
            [WXApi sendReq:req];
            self.completion = completion;
        }
            break;
        case CCPayChannelALIPAY_MOBILE: {
            //  支付宝支付
            //  应用注册scheme,在AliSDKDemo-Info.plist定义URL types
            NSString *appScheme = @"CCPaySDKDemoAlipay";
            __weak __typeof (self) weakSelf = self;
            // NOTE: 调用支付结果开始支付
            [[AlipaySDK defaultService] payOrder:pay_params fromScheme:appScheme callback:^(NSDictionary *resultDic) {
                NSError *error = [weakSelf handleAliPayWithResult:resultDic];
                if (!error) {
                    if (completion) { completion (YES, nil); }
                } else {
                    if (completion) { completion (NO, error); }
                }
            }];
        }
            break;
        case CCPayChannelUNION_APP: {
            //  银联支付 mode 00 为正式环境 01 为测试环境
            [[UPPaymentControl defaultControl] startPay:pay_params
                                             fromScheme:@"CCPaySDKDemoUnionPay"
                                                   mode:@"01"
                                         viewController:viewController];
            self.completion = completion;
        }
            break;
        default: {
            NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                                 code:CCPayErrorCodeTemporarilyNotOpened
                                             userInfo:@{NSLocalizedDescriptionKey:@"功能建设中"}];
            if (completion) { completion (NO, error); }
        }
            break;
    }
}

#pragma mark - WXApiDelegate
/*! @brief 发送一个sendReq后，收到微信的回应
 *
 * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
 * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等。
 * @param resp 具体的回应内容，是自动释放的
 */
- (void)onResp:(BaseResp *)resp {
    if([resp isKindOfClass:PayResp.class]) {
        //  支付返回结果，实际支付结果需要去微信服务器端查询
        PayResp *payResp = (PayResp *)resp;
        if (payResp.errCode == WXSuccess) {
            if (self.completion) { self.completion (YES, nil); }
        } else if (payResp.errCode == WXErrCodeUserCancel) {
            NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                                 code:CCPayErrorCodeCancel
                                             userInfo:@{NSLocalizedDescriptionKey:@"交易取消"}];
            if (self.completion) { self.completion (NO, error); }
        } else {
            NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                                 code:CCPayErrorCodeFailed
                                             userInfo:@{NSLocalizedDescriptionKey:@"交易失败"}];
            if (self.completion) { self.completion (NO, error); }
        }
    }
}

/*! @brief 收到一个来自微信的请求，第三方应用程序处理完后调用sendResp向微信发送结果
 *
 * 收到一个来自微信的请求，异步处理完成后必须调用sendResp发送处理结果给微信。
 * 可能收到的请求有GetMessageFromWXReq、ShowMessageFromWXReq等。
 * @param req 具体请求内容，是自动释放的
 */
- (void)onReq:(BaseReq *)req {}

#pragma mark - Methods

//  处理支付宝 支付结果
- (NSError *)handleAliPayWithResult:(NSDictionary *)result {
    NSInteger errCode = [result[@"resultStatus"] integerValue];
    if (errCode == 9000) {
        //  支付成功
        return nil;
    }
    NSInteger code;
    NSString *message = nil;
    switch (errCode) {
        case 9000:
            return nil;
        case 8000: {
            code = CCPayErrorCodeDealing;
            message = @"交易处理中";
        }
            break;
        case 6001: {
            code = CCPayErrorCodeCancel;
            message = @"交易取消";
        }
            break;
        default: {
            code = CCPayErrorCodeFailed;
            message = @"交易失败";
        }
            break;
    }
    NSError *error = [NSError errorWithDomain:CCPayErrorDomain
                                         code:code
                                     userInfo:@{NSLocalizedDescriptionKey:message}];
    return error;
}

#pragma mark - init
- (instancetype)init NS_UNAVAILABLE {
    self = [super init];
    if (self) {
        _version = @"1.0";
    }
    return self;
}

@end
