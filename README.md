#### CCPaySDK
------

**1.三方库依赖**

1.1 CocoaPods导入三方依赖库
```objective-c
pod 'AlipaySDK-iOS'
pod 'WechatOpenSDK'
pod 'MJExtension'
```
1.2 手动引入银联依赖库
```objective-c
UPPaymentControl.h
libPaymentControl.a
```
1.3 Library Binary With Libraries引入依赖
```objective-c
CFNetwork.framework
SystemConfiguration.framework
libz.tdb
```

**2.代码示例**

2.1 SDK回调Code类型
```objective-c
typedef NS_ENUM(NSUInteger, CCPayErrorCode) {
    CCPayErrorCodeSuccess                 = 0,        //  支付成功
    CCPayErrorCodeUnknown                 = 100000,   //  未知错误
    CCPayErrorCodeNotInstalled            = 100001,   //  程序未安装
    CCPayErrorCodeFailed                  = 100002,   //  支付失败
    CCPayErrorCodeCancel                  = 100003,   //  支付取消
    CCPayErrorCodeDealing                 = 100004,   //  交易处理中
    CCPayErrorCodeTemporarilyNotOpened    = 100099    //  功能暂未开放
};
```

2.2 方法

```objective-c
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
```

2.3.1 注册微信AppId

```objective-c
//  若要支持微信支付，则必须注册微信支付
[[CCPayManager sharedManager] registerWXAppId:@"wx0000000000000000"];
```

2.3.2 获取SDK版本号

```objective-c
NSString *version = [CCPayManager sharedManager].version;
```

2.3.3 处理OpenUrl
```objective-c
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[CCPaySDK sharedSDK] openPayURL:url];
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation {
    return [[CCPaySDK sharedSDK] openPayURL:url];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options NS_AVAILABLE_IOS(9_0) {
    return [[CCPaySDK sharedSDK] openPayURL:url];
}
```

2.3.4 支付示例

```objective-c
- (IBAction)aliPayTouchUpInside:(id)sender {
    //  支付宝支付
   [[CCPaySDK sharedSDK] payWithPayChannel:CCPayChannelALIPAY_MOBILE
                                         pay_params:@"alipay_params"
                                     viewController:self
                                         completion:^(BOOL success, NSError * _Nonnull error) {
                                             NSLog(@"%d --- %@", success, error);
                                         }];
}

- (IBAction)wechatPayTouchUpInside:(id)sender {
    //  微信支付
    [[CCPaySDK sharedSDK] payWithPayChannel:CCPayChannelWX_APP
                                         pay_params:@"wechatpay_params"
                                     viewController:self
                                         completion:^(BOOL success, NSError * _Nonnull error) {
                                             NSLog(@"%d --- %@", success, error);
                                         }];
}

- (IBAction)unionPayTouchUpInside:(id)sender {
    //  银联支付
    [[CCPaySDK sharedSDK] payWithPayChannel:CCPayChannelUNION_APP
                                         pay_params:@"unionpay_params"
                                     viewController:self
                                         completion:^(BOOL success, NSError * _Nonnull error) {
                                             NSLog(@"%d --- %@", success, error);
                                         }];
}
```
