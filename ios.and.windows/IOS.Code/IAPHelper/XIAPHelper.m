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
@interface XIAPHelper()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
{
    NSString* _goodId;
    SKProduct* _productInfo;
    NSString* _payload;
}
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
        _singleton = [[XIAPHelper alloc] init];
        _singleton.mInitSuccess = NO;
        _singleton.mIsBuying = NO;
        _singleton.mCurrentProductId = @"";
        _singleton.mShowAlert = NO;
    }
    return _singleton;
}

-(id) init
{
    if (self = [super init]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

//-(void) dealloc
//{
//    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
//    [super dealloc];
//}


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
    if(true){
        _payload = payload;
        [self buyGood: productId];
        return;
    }

    
    
    
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


-(void)buyGood:(NSString*)goodId
{
    
    NSLog(@" buyGood _goodId %@",goodId);
    
    if ([SKPaymentQueue canMakePayments]) {
        
        NSLog(@"允许程序内付费购买");
        
        _goodId = goodId;
        
        
        NSArray *product=[[NSArray alloc] initWithObjects:goodId,nil];
        NSSet *nsset = [NSSet setWithArray:product];
        SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
        request.delegate=self;
        [request start];
        
    }
    else
    {
        NSLog(@"XIAP: can not buy, IAP can not work");
        [self.mDelegate onXIAPBuyError:-1 msg:@"just do not support buy"];
        return;
    }
    
    
}



//<SKProductsRequestDelegate> 请求协议
//收到的产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    NSLog(@"-----------收到产品反馈信息--------------");
    NSArray *myProduct = response.products;
    NSLog(@"产品Product ID:%@",response.invalidProductIdentifiers);
    NSLog(@"产品付费数量: %d", (int)[myProduct count]);
    
    if([myProduct count]==0)//不存在改商品
    {
        [self.mDelegate onXIAPBuyError:-1 msg:@"product id not exist"];
        return;
    }
    // populate UI
    for(SKProduct *product in myProduct){
        NSLog(@"product info");
        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"Product id: %@" , product.productIdentifier);
    }
    
    NSLog(@"---------发送购买请求------------");
    
    _productInfo = myProduct[0];
    
    //  SKProduct *product = (SKProduct*) [response.products objectAtIndex:0];
    
    //_goodId
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:_productInfo];
    
    // SKPayment *payment = [SKPayment paymentWithProductIdentifier:_goodId];//
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    
}
- (void)requestProUpgradeProductData
{
    NSLog(@"------请求升级数据---------");
    NSSet *productIdentifiers = [NSSet setWithObject:@"com.productid"];
    SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
    
}
//弹出错误信息
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError error: %@ %ld", error.localizedDescription,(long)error.code);

    
    // [__object performSelector:__selector withObject:nil withObject:nil];
    
    [self.mDelegate onXIAPBuyError:-1 msg:@"pay failed"];
}

-(void) requestDidFinish:(SKRequest *)request
{
    NSLog(@"----------反馈信息结束--------------");
    
}

-(void) PurchasedTransaction: (SKPaymentTransaction *)transaction{
    NSLog(@"-----PurchasedTransaction----");
    NSArray *transactions =[[NSArray alloc] initWithObjects:transaction, nil];
    [self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:transactions];
}

//<SKPaymentTransactionObserver> 千万不要忘记绑定，代码如下：
//----监听购买结果
//[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions//交易结果
{
    NSLog(@"-----paymentQueue--------");
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:{//交易完成
                [self completeTransaction:transaction];
                NSLog(@"-----交易完成 --------");
                
                
            } break;
            case SKPaymentTransactionStateFailed://交易失败
            { [self failedTransaction:transaction];
                NSLog(@"-----交易失败 --------");
                
                [self.mDelegate onXIAPBuyError:-1 msg:@"buy failed"];
                //[__object performSelector:__selector withObject:nil withObject:nil];
                
            }break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                [self restoreTransaction:transaction];
                NSLog(@"-----已经购买过该商品 --------");
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
                NSLog(@"-----商品添加进列表 --------");
                break;
            default:
                break;
        }
    }
}
- (void) completeTransaction: (SKPaymentTransaction *)transaction

{
    NSLog(@"-----completeTransaction--------");

//    NSURL *receiptUrl = [[NSBundle mainBundle]appStoreReceiptURL];
//    NSData *receipt = [NSData dataWithContentsOfURL:receiptUrl];
//    NSString *base64Receipt = [receipt base64EncodedStringWithOptions:0];
//
//    // todo@om
//    self.mIsBuying = NO;
//
//    NSString* x_productId = trans.payment.productIdentifier;
//    NSString* x_payload = trans.payment.applicationUsername;
//    SKProduct* x_product = [self getProductById:x_productId];
//    //NSString* x_receipt = [[trans transactionReceipt] base64EncodedDataWithOptions:0];
//
//    NSLog(@"product: %@ payload: %@ ",productId,payload);
//    NSLog(@"x_product: %@ x_payload: %@ ",x_productId,x_payload);
//
//    // too long
//    // NSLog(@"XIAP: buy receipt %@",base64Receipt);
//    [self showDebugView:@"info" msg:trans.description];
//
//    [self.mDelegate onXIAPBuySuccess:base64Receipt payload:x_payload product:x_product];
    
    //从沙盒中获取交易凭证并且拼接成请求体数据
    NSURL *receiptUrl=[[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData=[NSData dataWithContentsOfURL:receiptUrl];
    NSString *base64Receipt = [receiptData base64EncodedStringWithOptions:0];
    
    //NSString *receiptString=[receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];//转化为base64字符串
    [self.mDelegate onXIAPBuySuccess:base64Receipt payload:_payload product:_productInfo];
    
    
    //[__object performSelector:__selector withObject:receiptString withObject:transaction.transactionIdentifier];
    
    
    // Remove the transaction from the payment queue.
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction{
    NSLog(@"失败 %@",transaction.error);
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}
-(void) paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *)transaction{
    
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@" 交易恢复处理");
    
}

-(void) paymentQueue:(SKPaymentQueue *) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"-------paymentQueue----");
}

#pragma mark connection delegate
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"test");
}


@end

