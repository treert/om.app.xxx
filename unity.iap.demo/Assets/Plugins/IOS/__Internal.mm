/*header
    > File Name: __Internal.cpp
    > Create Time: 2017-12-29 星期五 11时28分28秒
    > Athor: treertzhu
*/
#import <Foundation/Foundation.h>
#import "__Internal.h"
#import "XIAPHelper.h"

extern "C" void UnitySendMessage(const char * notfiyObjName, const char *method, const char *msg);


@interface TestIAP:NSObject<XIAPDelegate>
@end

@implementation TestIAP
- (void)RecvMsgFromUnity:(NSString *)type content:(NSString *)content {
    if ([type isEqualToString:@"xiap.init"]) {
        NSDictionary * contentDic = [XUtil dicWithJson:content];
        NSString * productIdListStr = [contentDic objectForKey:@"productIdList"];
        NSArray * arr = [productIdListStr componentsSeparatedByString:@","];
        NSSet * productIdList = [NSSet setWithArray:arr];
        [[XIAPHelper getInstance] setDelegate:self];
        [[XIAPHelper getInstance] initInfo:productIdList];
    }
    else if ([type isEqualToString:@"xiap.buy"]) {
        NSDictionary * contentDic = [XUtil dicWithJson:content];
        
        NSString * productId = [contentDic objectForKey:@"productId"];
        NSString * payload = [contentDic objectForKey:@"extData"];
        [[XIAPHelper getInstance] buy:productId payload:payload];
    }
}

- (void)onXIAPBuyError:(int)code msg:(NSString *)msg {
    NSLog(@"JoyYouSDK: onXIAPBuyError, Error Code: %d %@", code, msg);
    // notice user
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:[NSNumber numberWithInteger:8803] forKey:@"apiId"];
    [dict setObject:msg forKey:@"err_msg"];
    [dict setObject:[NSNumber numberWithInt:code] forKey:@"err_code"];
    NSString * resultStr = [XUtil dicToJson:dict];
    [self SendMsgToUnity:resultStr];
}

- (void)onXIAPBuySuccess:(NSString *)base64Receipt payload:(NSString *)payload product:(SKProduct *)product {
    NSLog(@"onXIAPBuySuccess, receipt: %@,payload: %@", base64Receipt, payload);
    // notice user
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:[NSNumber numberWithInteger:8804] forKey:@"apiId"];
    [dict setObject:base64Receipt forKey:@"token"];
    [dict setObject:payload forKey:@"payload"];
    NSString * resultStr = [XUtil dicToJson:dict];
    [self SendMsgToUnity:resultStr];
    
    if(product)
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:3];
        [dic setObject:[NSNumber numberWithInteger:1001] forKey:@"apiId"];
        [dic setObject:product.price forKey:@"price"];
        [dic setObject:product.priceLocale.countryCode forKey:@"price_currency_code"];
        NSString * resultStr = [XUtil dicToJson:dic];
        
        NSLog(@"JoyYouSDK: kor paycall, msg=%@", resultStr);
        [self SendMsgToUnity:resultStr];
        
    }
    
    
}

- (void)onXIAPInitError:(int)code msg:(NSString *)msg {
    NSLog(@"JoyYouSDK: onXIAPInitError, Error Code: %d %@", code, msg);
    // notice user
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:[NSNumber numberWithInteger:8801] forKey:@"apiId"];
    [dict setObject:msg forKey:@"err_msg"];
    [dict setObject:[NSNumber numberWithInt:code] forKey:@"err_code"];
    NSString * resultStr = [XUtil dicToJson:dict];
    [self SendMsgToUnity:resultStr];
}

- (void)onXIAPInitSuccess:(NSArray *)products {
    NSLog(@"onXIAPInitSuccess");
    NSMutableDictionary *price_map = [NSMutableDictionary dictionaryWithCapacity:products.count];
    for (SKProduct *product in products) {
        NSLog(@"product: %@",[product localizedDescription]);
        [price_map setObject:[NSString
                              stringWithFormat:@"%@%@",
                              [product.priceLocale objectForKey:NSLocaleCurrencySymbol],
                              product.price]
                      forKey:product.productIdentifier];
    }\
    // notice user
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:[NSNumber numberWithInteger:8802] forKey:@"apiId"];
    [dict setObject:price_map forKey:@"price_map"];
    NSString * resultStr = [XUtil dicToJson:dict];
    [self SendMsgToUnity:resultStr];
}

- (void)SendMsgToUnity:(NSString *)msg {
    UnitySendMessage("GamePoint","RecvNativeMsg", [msg UTF8String])
}

@end

static TestIAP* _test_iap_instance = nil;
static TestIAP* GetTestIAPInstance() {
    if(_test_iap_instance != nil) {
        _test_iap_instance = [TestIAP alloc];
    }
    return _test_iap_instance;
}

void U3D_RecvMsgFromUnity(const char * type , const char * content)
{
    NSString * _type = [[NSString alloc] initWithUTF8String:type];
    NSString * _content = [[NSString alloc] initWithUTF8String:content];
    TestIAP* GetTestIAPInstance();
    [TestIAP RecvMsgFromUnity:_type content:_content];
}

const char * U3D_GetSDKConfig(const char * type, const char * content)
{
    return "";
}
