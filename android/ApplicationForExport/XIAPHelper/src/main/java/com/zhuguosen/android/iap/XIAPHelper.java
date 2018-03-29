package com.zhuguosen.android.iap;

import java.util.List;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.util.Log;

//import com.zhuguosen.android.iap.util.IabBroadcastReceiver;
//import com.zhuguosen.android.iap.util.IabBroadcastReceiver.IabBroadcastListener;
import com.zhuguosen.android.iap.util.IabHelper;
import com.zhuguosen.android.iap.util.IabResult;
import com.zhuguosen.android.iap.util.Inventory;
import com.zhuguosen.android.iap.util.Purchase;
import com.zhuguosen.android.iap.util.SkuDetails;
import com.zhuguosen.android.iap.util.IabHelper.IabAsyncInProgressException;

/**
 * 对google IabHelper做二次包装，正对项目简化使用
 * 1. 调用
 * 		1. init 初始化商品列表，**同时会检查未消费的商品，继续消费**
 * 		2. buy 购买商品
 * 2. 回调
 * 		1. setDelegate
 * 3. activity事件调用
 * 		1. onDestroy
 * 		2. handleActivityResult
 * 4。 设置
 * 		1. mBase64EncodedPublicKey **必须**，Google Play Console 提供的key
 * ·	2。 mDebugLog 是否输出调试信息，默认true
 * 		3. mShowAlert 是否显示提示窗口，默认false
 * 
 * @author treertzhu
 *
 */
public class XIAPHelper {

    static int ERR_HAS_OWNED_NEED_CONSUME = 1001;
    static int ERR_BILL_SERVICE_DISCONNECTED = 4001;


	static XIAPHelper _singleton = null;
	public static XIAPHelper getInstance(){
		if(_singleton == null)
		{
			_singleton = new XIAPHelper();
		}
		return _singleton;
	}
	
	static final String TAG = "XGoogleIAPHelper";
	
    // (arbitrary) request code for the purchase flow
    static final int RC_REQUEST = 10001;

	// Google Play Console 提供的key，最好是保存到服务器里，通过请求获取，然后初始化前设置进来
    public String mBase64EncodedPublicKey = "";
	//public String mBase64EncodedPublicKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp2IBeOvkYOAVsyAhvFIRktYjInmjKFbqmdn5haLGKWi46QIbS82gPdAxYoq2dc5bC/zIXjBDns/LmbKE7hQy+VvsI4BZF+bhCQ50UKubMKeNH7AI/sQvNUgcpqseLppVylw56JKwRCLJoytSku/TvKulrgLx+DEyCwHdyxh/IQSAJGfE0sOg1eTMotxUG3KR0EnA9pnaP4S+Dka0f22fhYo2+MoGAYHyVfdlaGuXwve3kWiVSDiStn3sXCwmHpDtbtBEyjT7x6SOMygOhCdSM9W7rQoV8sZpBZxy+KWvn1ZxxMV9/x4CcRPT8zx3++bxJx6X+nxZqIu2Xbh3g65OfwIDAQAB";

	public boolean mDebugLog = true;
	public boolean mShowAlert = false;
	
    void logDebug(String msg) {
        if (mDebugLog) Log.d(TAG, msg);
    }

    void logError(String msg) {
        Log.e(TAG, "XGoogleIAPManager error: " + msg);
    }

    void logWarn(String msg) {
        Log.w(TAG, "XGoogleIAPManager warning: " + msg);
    }
    
    // only for developer debug
    void alert(String message) {
    	if(!mShowAlert) return;
        AlertDialog.Builder bld = new AlertDialog.Builder(mActivity);
        bld.setMessage(message);
        bld.setNeutralButton("OK", null);
        Log.d(TAG, "Showing alert dialog: " + message);
        bld.create().show();
    }

    private List<String> mProductIdList;
    // 商品信息
    private Inventory mInventory;
    
    // 主ui activity
    private Activity mActivity;
	
    // The helper object
    private IabHelper mHelper;
    
    // 官方文档说是要调用
    public void onDestroy(){
        // very important:
        logDebug("Destroying helper.");
        if (mHelper != null && mHelper.IsDisposed() == false) {
            mHelper.disposeWhenFinished();
            mHelper = null;
        }
    }
    
    // 官方文档说是要调用
    public void handleActivityResult(int requestCode, int resultCode, Intent data)
    {
    	if(mHelper == null) return;
    	// Pass on the activity result to the helper for handling
        if (mHelper.handleActivityResult(requestCode, resultCode, data))
        {
        	logDebug("handled by IABUtil onActivityResult(" + requestCode + "," + resultCode + "," + data);
        }
    }

    private void _init(){
        this.init(mActivity, mProductIdList);
    }
    
    public void init(Activity activity, final List<String> productIdList){
    	mActivity = activity;
        mProductIdList = productIdList;
    	
    	if(mBase64EncodedPublicKey.length() < 1)
    	{
    		logError("et app public key before init");
    		this.mDelegate.onXIAPIinitError(-1, "set app public key before init");
    		return;
    	}
    	
        // Create the helper, passing it our context and the public key to verify signatures with
    	logDebug("Creating IAB helper.");

    	if(mHelper != null && mHelper.IsDisposed() == false){
    	    mHelper.disposeWhenFinished();
        }

        mHelper = new IabHelper(mActivity, mBase64EncodedPublicKey);
    	
        // enable debug logging (for a production application, you should set this to false).
        mHelper.enableDebugLogging(mDebugLog);
        
        // Start setup. This is asynchronous and the specified listener
        // will be called once setup completes.
        logDebug("Starting setup.");
        mHelper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
            public void onIabSetupFinished(IabResult result) {
                // Have we been disposed of in the meantime? If so, quit.
                if (mHelper == null) return;

                // unfortunely, this may happend
                if(mHelper.IsDisposed()) return;

                logDebug("Setup finished. ");

                if (!result.isSuccess()) {
                    // Oh noes, there was a problem.
                    logError("Problem setting up in-app billing: " + result);
                    mDelegate.onXIAPIinitError(-1, "iap helper setup failed: "+result);
                    return;
                }

                if(mHelper.IsServiceConnected() == false){
                    logError("startSetup error: bill service disconnected");
                    mDelegate.onXIAPIinitError(ERR_BILL_SERVICE_DISCONNECTED, "startSetup error: bill service disconnected");
                    return;
                }

                // Important: Dynamically register for broadcast messages about updated purchases.
                // We register the receiver here instead of as a <receiver> in the Manifest
                // because we always call getPurchases() at startup, so therefore we can ignore
                // any broadcasts sent while the app isn't running.
                // Note: registering this listener in an Activity is a bad idea, but is done here
                // because this is a SAMPLE. Regardless, the receiver must be registered after
                // IabHelper is setup, but before first call to getPurchases().
//                mBroadcastReceiver = new IabBroadcastReceiver(MainActivity.this);
//                IntentFilter broadcastFilter = new IntentFilter(IabBroadcastReceiver.ACTION);
//                registerReceiver(mBroadcastReceiver, broadcastFilter);

                // IAB is fully set up. Now, let's get an inventory of stuff we own.
                logDebug("Setup successful. Querying inventory.");
                try {
                    mHelper.queryInventoryAsync(true,mProductIdList,null,mGotInventoryListener);
                } catch (IabAsyncInProgressException e) {
                	logError("Error querying inventory. Another async operation in progress.");
                	mDelegate.onXIAPIinitError(-1, "Error querying inventory. Another async operation in progress.");
                }
            }
        });
    }
    
    public void buy(String productId, String payload){
    	logDebug(String.format("buy product: %s", productId));
    	
    	if(mInventory == null || mHelper == null || mHelper.IsDisposed()){
    		logError("buy product error: has not init success");
    		mDelegate.onXIAPBuyError(-1, "buy product error: has not init success");
    		return;
    	}

    	if(mHelper.IsServiceConnected() == false){
            logError("buy product error: bill service disconnected");
            mDelegate.onXIAPBuyError(ERR_BILL_SERVICE_DISCONNECTED, "buy product error: bill service disconnected");
            // reinit
            _init();
    	    return;
        }
    	
    	if(mInventory.hasDetails(productId) == false)
    	{
    		logError("buy product error: invalid productId: " + productId);
    		mDelegate.onXIAPBuyError(-1, "buy product error: invalid productId: " + productId);
    		return;
    	}
    	
        try {
            mHelper.launchPurchaseFlow(mActivity, productId, RC_REQUEST,
                    mPurchaseFinishedListener, payload);
        } catch (IabAsyncInProgressException e) {
            logError("Error launching purchase flow. Another async operation in progress.");
            mDelegate.onXIAPBuyError(-1, "Error launching purchase flow. Another async operation in progress.");
        }
    }

    /**
     * consume owned product, so can buy again
     * @param productId
     */
    public void consume(String productId){
        // 这个接口，不需要返回，服务
        if(mInventory == null || mHelper == null || mHelper.IsDisposed()) return;
        if(mHelper.IsServiceConnected() == false){
            return;
        }
        Purchase purchase = mInventory.getPurchase(productId);
        if(purchase != null){
            try {
                mInventory.erasePurchase(purchase.getSku());
                mHelper.consumeAsync(purchase, mConsumeFinishedListener);
            } catch (IabAsyncInProgressException e) {
                logError("Error consuming . Another async operation in progress. product: " + purchase.getSku());
                return;
            }
        }
    }
    
    private void ConsumeOneUnexceptProduct(){
    	if(mInventory == null) return;
        // 这些商品商品直接通知游戏去消耗
    	List<Purchase> needConsumeProducts = mInventory.getAllPurchases();
    	if(needConsumeProducts.size() > 0)
    	{
    		Purchase purchase= needConsumeProducts.get(0);
            mDelegate.onXIAPBuySuccess(purchase);
    	}
    }
    
    
    // Listener that's called when we finish querying the items and subscriptions we own
    IabHelper.QueryInventoryFinishedListener mGotInventoryListener = new IabHelper.QueryInventoryFinishedListener() {

		@Override
		public void onQueryInventoryFinished(IabResult result, Inventory inv) {
			logDebug("Query inventory finished.");
            // Is it a failure?
            if (result.isFailure()) {
                logError("Failed to query inventory: " + result);
                mDelegate.onXIAPIinitError(-1, "Failed to query inventory: " + result);
                return;
            }

            // if mInventory aready exsit, merge it seems better, but i do not do it
            mInventory = inv;
            
            // 通知客户端，商品列表和为消费的商品列表�??
            List<SkuDetails> products = mInventory.getAllSkus();
            List<Purchase> needConsumeProducts = mInventory.getAllPurchases();
            
            logDebug("products: " + products);
            logDebug("needConsumeProducts: " + needConsumeProducts);
            alert("init success: " + products);
            
            mDelegate.onXIAPIinitSuccess(mInventory);
            
            // SDK的初始化是在进入主城后执行的，可以直接在这里�?始消费商品�??
            ConsumeOneUnexceptProduct();
		}
    	
    };
    
    // Callback for when a purchase is finished
    IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = new IabHelper.OnIabPurchaseFinishedListener() {

		@Override
		public void onIabPurchaseFinished(IabResult result, Purchase purchase) {
			logDebug("Purchase finished: " + result + ", purchase: " + purchase);
			
            // if we were disposed of in the meantime, quit.
            if (mInventory == null) return;
            
            if (result.isFailure()){
            	logError("Error purchasing: " + result);
                if(result.getResponse() == IabHelper.BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED){
                    // error code 7, means aready owned, need notice server then consume it
                    // refresh info, callback will handle it
                    try {
                        mHelper.queryInventoryAsync(true,mProductIdList,null,mGotInventoryListener);
                    } catch (IabAsyncInProgressException e) {
                        logError("Error querying inventory. Another async operation in progress.");
                    }
                    mDelegate.onXIAPBuyError(ERR_HAS_OWNED_NEED_CONSUME, "Error purchasing: " + result);
                }
                else{
                    mDelegate.onXIAPBuyError(-1, "Error purchasing: " + result);
                }
            	return;
            }
            mInventory.addPurchase(purchase);
            alert("Purchase: " + purchase);
            mDelegate.onXIAPBuySuccess(purchase);

            logDebug("Purchase successful.");
		}
    	
    };
    
    // Called when consumption is complete
    IabHelper.OnConsumeFinishedListener mConsumeFinishedListener = new IabHelper.OnConsumeFinishedListener() {

		@Override
		public void onConsumeFinished(Purchase purchase, IabResult result) {
			logDebug("Consumption finished. Purchase: " + purchase + ", result: " + result);

			if (result.isSuccess()) {
				// 通知服务器发货，这一步很关键，最好是能�?�知到服务器，不然会非常的尴�?
				logDebug("Consumption successful. Provisioning.");
				alert("Consume: " + purchase);
            }
            else {
            	logError("Error while consuming: " + result);
            }
			
			// no harm
			ConsumeOneUnexceptProduct();
			
			logDebug("End consumption flow.");
		}
    	
    };
    
    
    /************************* 定义回调接口格式   ***************************/
    public void setDelegate(Delegate delegate){
    	mDelegate = delegate;
    }
    // 回调处理
    private Delegate mDelegate = new Delegate(){

		@Override
		public void onXIAPIinitError(int code, String msg) {
			// TODO Auto-generated method stub
			
		}

		@Override
		public void onXIAPIinitSuccess(Inventory inventory) {
			// TODO Auto-generated method stub
			
		}

		@Override
		public void onXIAPBuyError(int code, String msg) {
			// TODO Auto-generated method stub
			
		}

		@Override
		public void onXIAPBuySuccess(Purchase purchase) {
			// TODO Auto-generated method stub
			
		}
    	
    };
    public interface Delegate {
    	/**
    	 * 初始化出错
    	 * @param code
    	 * @param msg
    	 */
    	void onXIAPIinitError(int code, String msg);
    	/**
    	 * 初始化成功，把google定义的inventory直接传过来，方便
    	 * @param inventory
    	 */
    	void onXIAPIinitSuccess(Inventory inventory);
    	/**
    	 * 购买失败
    	 * @param code
    	 * @param msg
    	 */
    	void onXIAPBuyError(int code, String msg);
    	/**
    	 * 购买成功，结果数据全部在purchase里
    	 * @param purchase
    	 */
    	void onXIAPBuySuccess(Purchase purchase);
    }
}
