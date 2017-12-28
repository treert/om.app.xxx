//
//  XAppleIAP.m
//  Unity-iPhone
//
//  Created by 龙之谷海外 on 2017/11/29.
//

#import <Foundation/Foundation.h>
#import "XIAPHelper.h"

/**
 * 简单包装下IAPHelper，方便使用。只支持消耗型内购
 * 1. initInfo
 * 2. buy
 */
@interface XIAPHelper()
@property BOOL mInitSuccess;
@property BOOL mIsBuying;
@property BOOL mShowAlert;
@property NSString *mCurrentProductId;// 一次只能买一个
@property id<XIAPDelegate> mDelegate;
@end

@implementation XIAPHelper


static XIAPHelper * _singleton;

+ (XIAPHelper* ) getInstance {
    if (_singleton == nil) {
        _singleton = [XIAPHelper alloc];
        _singleton.mInitSuccess = NO;
        _singleton.mIsBuying = NO;
        _singleton.mCurrentProductId = @"";
        _singleton.mShowAlert = NO;
    }
    return _singleton;
}

- (void) initInfo:(NSSet*)productIdList{
//    if(self.mInitSuccess)
//    {
//        // 不支持重复初始化
//        return;
//    }
//    NSSet * productIdList = [NSSet setWithObjects:
//                         @"com.dragonnest.kakao.kr.diamond1",
//                         @"com.dragonnest.kakao.kr.diamond2",
//                         nil];
    
    self.mInitSuccess = NO;
    
    [IAPShare sharedHelper].iap = [[IAPHelper alloc] initWithProductIdentifiers:productIdList];
    // 沙河测试
    [IAPShare sharedHelper].iap.production = NO;
    // 获取商品列表
    [[IAPShare sharedHelper].iap requestProductsWithCompletion:^(SKProductsRequest* request,SKProductsResponse* response)
     {
         self.mInitSuccess = YES;
         NSLog(@"XIAP: get product info list finish");
         NSArray *list = [IAPShare sharedHelper].iap.products;
         NSLog(@"XIAP: product list:\n %lu %@",(unsigned long)[list count],[list description]);
         
         NSLog(@"XIAP: failed list: %@",[response.invalidProductIdentifiers description]);
         
         if([list count] > 0)
         {
             [self.mDelegate onXIAPInitSuccess:list];
         }
         else
         {
             [self.mDelegate onXIAPBuyError:-1 msg:@""];
         }
         
         [self showDebugView:@"init finish" msg:
           [NSString stringWithFormat:@"success %@ \n failed %@",
           [response.products description],
           [response.invalidProductIdentifiers description]]];
    }];
}

-(void)showDebugView:(NSString*)title msg:(NSString*)msg{
    if(!self.mShowAlert) return;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
    [alertView show];
}

//
//-(NSData*)receiptWithTransation:(SKPaymentTransaction*) transcation {
//    NSData *receipt = nil;
//    if ([[NSBundle mainBundle]respondsToSelector:@selector(appStoreReceiptURL)]) {
//        NSURL *receiptUrl = [[NSBundle mainBundle]appStoreReceiptURL];
//        receipt = [NSData dataWithContentsOfURL:receiptUrl];
//    } else {
//        // IOS7 之后废弃了，应该不会用到了
//        if ([transcation respondsToSelector:@selector(transactionReceipt)]) {
//            receipt = [transcation transactionReceipt];
//        }
//    }
//
//    return receipt;
//}

- (SKProduct*) getProductById:(NSString*) productId
{
    // get product info
    SKProduct* product = nil;
    NSArray *list = [IAPShare sharedHelper].iap.products;
    for(SKProduct* item in list)
    {
        if([item.productIdentifier isEqualToString:productId])
        {
            product = item;
            break;
        }
    }
    return product;
}

- (void) buy:(NSString*)productId payload:(NSString*) payload {
    if (![SKPaymentQueue canMakePayments]) {
        NSLog(@"XIAP: can not buy, IAP can not work");
        [self.mDelegate onXIAPBuyError:-1 msg:@"just do not support buy"];
        return;
    }
    
    if(self.mInitSuccess == NO)
    {
        NSLog(@"XIAP: can not buy, has not init success");
        [self.mDelegate onXIAPBuyError:-1 msg:@"has not init success"];
        return;
    }
    
//    if(self.mIsBuying){
//        NSLog(@"XIAP: can not buy, is buying %@",self.mCurrentProductId);
//        [self.mDelegate onXIAPBuyError:4001 msg:@"waiting for last buy request"];
//        return;
//    }

    // get product info
    SKProduct* product = [self getProductById:productId];
    
    if(!product){
        NSLog(@"XIAP: error productId: %@ is not valid",productId);
        [self.mDelegate onXIAPBuyError:4002 msg:
         [NSString stringWithFormat:@"%@ is not valid", productId]];
        return;
    }

    self.mIsBuying = YES;
    [[IAPShare sharedHelper].iap buyProductWithPayload:product payload:payload
                               onCompletion:^(SKPaymentTransaction* trans)
    {
        if(trans.error)
        {
            self.mIsBuying = NO;
            NSLog(@"XIAP: buy %@ Fail %@",productId,[trans.error localizedDescription]);
            [self.mDelegate onXIAPBuyError:-1 msg:
             [NSString stringWithFormat:@"buy %@ Fail %@", productId, [trans.error localizedDescription]]];
        }
        else if(trans.transactionState == SKPaymentTransactionStatePurchased) {
            // !!!用户已经付钱了，这之后要是请求服务器发货失败就掉单了
            // 把票据发服务器，这儿不做票据保存，做也是在游戏逻辑里做
            NSURL *receiptUrl = [[NSBundle mainBundle]appStoreReceiptURL];
            NSData *receipt = [NSData dataWithContentsOfURL:receiptUrl];
            NSString *base64Receipt = [receipt base64EncodedStringWithOptions:0];
            
            // todo@om
            self.mIsBuying = NO;
            
            NSString* x_productId = trans.payment.productIdentifier;
            NSString* x_payload = trans.payment.applicationUsername;
            SKProduct* x_product = [self getProductById:x_productId];
            //NSString* x_receipt = [[trans transactionReceipt] base64EncodedDataWithOptions:0];
            
            NSLog(@"product: %@ payload: %@ ",productId,payload);
            NSLog(@"x_product: %@ x_payload: %@ ",x_productId,x_payload);
            
            // too long
            // NSLog(@"XIAP: buy receipt %@",base64Receipt);
            [self showDebugView:@"info" msg:trans.description];
            
            [self.mDelegate onXIAPBuySuccess:base64Receipt payload:x_payload product:x_product];
        }
        else if(trans.transactionState == SKPaymentTransactionStateFailed) {
            NSLog(@"XIAP: buy %@ state notify", productId);
            
            switch (trans.transactionState) {
                case SKPaymentTransactionStatePurchasing:
                    NSLog(@"IAP: buy ing...");
                    break;
                case SKPaymentTransactionStatePurchased:
                    NSLog(@"IAP: buy ok, should not happend");
                    break;
                case SKPaymentTransactionStateFailed:
                    self.mIsBuying = NO;
                    NSLog(@"IAP: buy failed");
                    [self.mDelegate onXIAPBuyError:-1 msg:@"buy failed"];
                    break;
                case SKPaymentTransactionStateRestored:
                    NSLog(@"IAP: buy has buy one %@",productId);
                    break;
                case SKPaymentTransactionStateDeferred:
                    NSLog(@"XIAP: buy deferr??");
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void) setDelegate:(id<XIAPDelegate>)delegate{
    self.mDelegate = delegate;
}

@end
