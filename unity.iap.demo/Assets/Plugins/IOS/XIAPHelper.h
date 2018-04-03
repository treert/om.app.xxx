/*header
    > File Name: XIAPHelper.h
    > Create Time: 2018-04-03 星期二 20时03分07秒
    > Athor: treertzhu
*/

#ifndef XAppleIAP_h
#define XAppleIAP_h
#import "IAPShare.h"

@protocol XIAPDelegate
- (void) onXIAPInitError:(int) code msg:(NSString*)msg;
- (void) onXIAPInitSuccess:(NSArray *) products ;
- (void) onXIAPBuyError:(int) code msg:(NSString*)msg;
- (void) onXIAPBuySuccess:(NSString*)base64Receipt  payload:(NSString*)payload product:(SKProduct*)product;
@end

/**
 * 简单包装，方便使用。
 * 1. initInfo 初始化，拉取商品列表
 * 2. buy
 * 3. setDelegate 设置回调
 */
@interface XIAPHelper : NSObject
+ (XIAPHelper* ) getInstance;
- (void) initInfo:(NSSet*)productIdList ;
- (void) buy:(NSString*)productId payload:(NSString*) payload;
- (void) setDelegate:(id<XIAPDelegate>)delegate;
@end

#endif /* XAppleIAP_h */
