/*header
    > File Name: XIAPHelper.m
    > Create Time: 2018-04-03 星期二 20时03分14秒
    > Athor: treertzhu
*/

#import <Foundation/Foundation.h>
#import "XIAPHelper.h"

#if ! __has_feature(objc_arc)
#error You need to either convert your project to ARC or add the -fobjc-arc compiler flag to IAPHelper.m.
#endif

@interface XIAPHelper()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
{
    NSString* _goodId;
    SKProduct* _productInfo;
    NSString* _payload;
}
@property BOOL mIsBuying;
@property BOOL mShowAlert;
@property id<XIAPDelegate> mDelegate;
@property (nonatomic,strong) NSArray * products;// 商品列表

@end

@implementation XIAPHelper


static XIAPHelper * _singleton;

// 会初始化，添加监听，在应用有能力处理支付逻辑时在调用
+ (XIAPHelper* ) getInstance {
    if (_singleton == nil) {
        _singleton = [[XIAPHelper alloc] init];
        _singleton.mIsBuying = NO;
        _singleton.mShowAlert = NO;
        _singleton.products = [NSArray array];
    }
    return _singleton;
}

-(id) init {
    if (self = [super init]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

-(void) dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void) setDelegate:(id<XIAPDelegate>)delegate {
    self.mDelegate = delegate;
}

- (void) initInfo:(NSSet*)productIdList{
    [self requestProducts:productIdList];
}

-(void)showDebugView:(NSString*)title msg:(NSString*)msg {
    if(!self.mShowAlert) return;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
    [alertView show];
}

- (SKProduct*) getProductById:(NSString*) productId {
    for(SKProduct* item in self.products) {
        if([item.productIdentifier isEqualToString:productId]) {
            return item;
        }
    }
    return nil;
}

// 获取所有的商品
- (void)requestProducts:(NSSet *)productIdentifiers {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    request.delegate=self;
    [request start];// 这个的生命周期大概会自动管理，注意开启ARC
}

//<SKProductsRequestDelegate> 收到的产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"XIAP: get product info list finish");
    self.products = response.products;
    NSArray *list = self.products;
    NSLog(@"XIAP: product list:\n %lu %@",(unsigned long)[list count],[list description]);
    NSLog(@"XIAP: failed list: %@",[response.invalidProductIdentifiers description]);

    if([list count] > 0) {
        [self.mDelegate onXIAPInitSuccess:list];
    }
    else {
        [self.mDelegate onXIAPInitError:-1 msg:@""];
    }

    [self showDebugView:@"get product info list finish" 
          msg:[NSString stringWithFormat:@"success %@ \n failed %@",
                [response.products description],
                [response.invalidProductIdentifiers description]]
            ];
}

- (void) buy:(NSString*)productId payload:(NSString*) payload {
    NSLog(@"XIAP: buy Good productId = %@",productId);
    if (![SKPaymentQueue canMakePayments]) {
        NSLog(@"XIAP: can not buy, IAP can not work");
        [self.mDelegate onXIAPBuyError:-1 msg:@"just do not support buy"];
        return;
    }
    
    if(self.mIsBuying){
        NSLog(@"XIAP: can not buy, is buying %@",_goodId);
       [self.mDelegate onXIAPBuyError:4001 msg:@"waiting for last buy request"];
       return;
    }

    // get product info
    SKProduct* product = [self getProductById:productId];
    
    if(!product){
        NSLog(@"XIAP: error productId: %@ is not valid",productId);
        [self.mDelegate onXIAPBuyError:4002 msg:[NSString stringWithFormat:@"%@ is not valid", productId]];
        return;
    }

    self.mIsBuying = YES;
    _goodId = productId;
    _payload = payload;
    _productInfo = product;

    // SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//<SKPaymentTransactionObserver> 支付过程回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

-(void) completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"XIAP: buy success product: %@ payload: %@ ",_goodId,_payload);
    self.mIsBuying = NO;
    // !!!用户已经付钱了，这之后要是请求服务器发货失败就掉单了
    // 把票据发服务器，这儿不做票据保存，做也是在游戏逻辑里做
    NSURL *receiptUrl = [[NSBundle mainBundle]appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptUrl];
    NSString *base64Receipt = [receipt base64EncodedStringWithOptions:0];
    
    [self showDebugView:@"info" msg:transaction.description];
    [self.mDelegate onXIAPBuySuccess:base64Receipt payload:_payload product:_productInfo];
}


-(void) failedTransaction:(SKPaymentTransaction *)transaction{
    self.mIsBuying = NO;
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"XIAP: Transaction error: %@ %ld ", transaction.error.localizedDescription,(long)transaction.error.code);
    }

    [self.mDelegate onXIAPBuyError:-1 msg:@"buy failed"];
}


-(void) restoreTransaction:(SKPaymentTransaction *)transaction{
    NSLog(@"XIAP: Restore transaction : %@",transaction.transactionIdentifier);
    // 当前不支持非消耗物品
}

@end

