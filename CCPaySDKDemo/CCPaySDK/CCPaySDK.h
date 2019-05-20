//
//  CCPaySDK.h
//  CCPaySDKDemo
//
//  Created by iBlocker on 2019/5/16.
//  Copyright © 2019 iBlocker. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, CCPayChannel) {
    CCPayChannelALIPAY_MOBILE,  //  支付宝App支付
    CCPayChannelWX_APP,         //  微信App支付
    CCPayChannelUNION_APP       //  银联App支付
};

typedef NS_ENUM(NSUInteger, CCPayErrorCode) {
    CCPayErrorCodeSuccess                 = 0,        //  支付成功
    CCPayErrorCodeUnknown                 = 100000,   //  未知错误
    CCPayErrorCodeNotInstalled            = 100001,   //  程序未安装
    CCPayErrorCodeFailed                  = 100002,   //  支付失败
    CCPayErrorCodeCancel                  = 100003,   //  支付取消
    CCPayErrorCodeDealing                 = 100004,   //  交易处理中
    CCPayErrorCodeTemporarilyNotOpened    = 100099    //  功能暂未开放
};

NS_ASSUME_NONNULL_BEGIN

@interface CCWXAppPayParam : NSObject
/** App ID*/
@property (nonatomic, copy) NSString *appId;
/** 商家向财付通申请的商家id */
@property (nonatomic, copy) NSString *partnerId;
/** 预支付订单 */
@property (nonatomic, copy) NSString *prepayId;
/** 随机串，防重发 */
@property (nonatomic, copy) NSString *nonceStr;
/** 时间戳，防重发 */
@property (nonatomic, copy) NSString *timeStamp;
/** 商家根据财付通文档填写的数据和签名 */
@property (nonatomic, copy) NSString *packageValue;
/** 商家根据微信开放平台文档对数据做的签名 */
@property (nonatomic, copy) NSString *sign;
@end

@interface CCPaySDK : NSObject
/** SDK版本号*/
@property (nonatomic, readonly, copy) NSString *version;

/**
 单例方法
 
 @return 单例对象
 */
+ (instancetype)sharedSDK;

/**
 注册微信支付 若要支持微信支付，则必须注册
 
 @param appId 微信AppId
 @return 注册结果
 */
- (BOOL)registerWXAppId:(NSString *)appId;

/**
 打开支付Url
 
 @param url Url
 @return 是否打开
 */
- (BOOL)openPayURL:(NSURL *)url;

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
               completion:(void (^)(BOOL success, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
