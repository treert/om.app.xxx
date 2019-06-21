/*header
    > File Name: XIAPHelper.m
    > Create Time: 2018-04-03 星期二 20时03分14秒
    > Athor: treertzhu
*/

// 掉单处理的不好，这次优化一点点，有机会再优化完整吧。有两个参考文章
// > 有代码 https://www.jianshu.com/p/573876b34c15
// > 分析过程多一点 https://www.jianshu.com/p/d8bf952a023a


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
		_singleton.goodId = @"";
		_singleton.
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

    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
	payment.applicationUsername = payload; // 这个可能回调时为空，有坑。
    // SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//<SKPaymentTransactionObserver> 支付过程回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self completeTransaction:transaction];
                break;
			case SKPaymentTransactionStatePurchasing:
				// NSLog(@"商品添加进列表");
				break;
            default:
				// NSLog(@"支付失败");// ??
                break;
        }
    }
}

-(void) completeTransaction:(SKPaymentTransaction *)transaction {
	NSLog(@"XIAP: buy success product: %@ payload: %@ ",_goodId,_payload);
	self.mIsBuying = NO;
	// !!!用户已经付钱了，这之后要是请求服务器发货失败就掉单了
    // 把票据发服务器，这儿不做票据保存，做也是在游戏逻辑里做
	NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
	if(receipt){
		NSString *orderId = transaction.payment.applicationUsername ?: self.payload;// applicationUsername 就算设置了也可能为空
		// NSString *key = transaction.transactionIdentifier;// should use, but has not use
		NSString *base64Receipt = [receipt base64EncodedStringWithOptions:0];
		
		[self showDebugView:@"info" msg:transaction.description];
		[self.mDelegate onXIAPBuySuccess:base64Receipt payload:orderId product:_productInfo];
	}
	
	// 应该等服务器回调后再调用这个
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


-(void) failedTransaction:(SKPaymentTransaction *)transaction{
    self.mIsBuying = NO;
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"XIAP: Transaction error: %@ %ld ", transaction.error.localizedDescription,(long)transaction.error.code);
    }

    [self.mDelegate onXIAPBuyError:-1 msg:@"buy failed"];
}

@end

