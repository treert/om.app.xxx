package com.zhuguosen.u3d;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import com.unity3d.player.UnityPlayerActivity;
import com.unity3d.player.UnityPlayerNativeActivity;
import com.zhuguosen.android.iap.XIAPHelper;
import com.zhuguosen.android.iap.util.Inventory;
import com.zhuguosen.android.iap.util.Purchase;
import com.zhuguosen.android.iap.util.SkuDetails;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.Arrays;
import java.util.List;

/**
 * Created by treertzhu on 2017/12/14.
 */

public class MyUnityAcitvity extends UnityPlayerNativeActivity implements NativeInterface.Delegate {
    protected void onCreate(Bundle savedInstanceState) {
        // set native delegate
        NativeInterface.mDelegate = this;
        // call UnityPlayerActivity.onCreate()
        super.onCreate(savedInstanceState);
        // print debug message to logcat
        Log.d("OverrideActivity", "onCreate called!");
    }
    public void onBackPressed()
    {
        // instead of calling UnityPlayerActivity.onBackPressed() we just ignore the back button event
        // super.onBackPressed();
    }

    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        XIAPHelper.getInstance().handleActivityResult(requestCode, resultCode, data);
    }

    protected void onDestroy()
    {
        super.onDestroy();

        XIAPHelper.getInstance().onDestroy();
    }

    @Override
    public void RecvMsgFromUnity(String type, String json) {
        Log.v("OM",String.format("type: %s, json: %s", type, json));
        if(type.equals("xiap.init")){
            try {
                JSONObject data = new JSONObject(json);
                String publicKey = data.getString("publicKey");
                String content = data.getString("productIdList");

                String[] productIdList = content.split(",");
                XIAPHelper.getInstance().mBase64EncodedPublicKey = publicKey;
                XIAPHelper.getInstance().setDelegate(mXIAPDelegate);
//                XIAPHelper.getInstance().mShowAlert = true;
                XIAPHelper.getInstance().init(this, Arrays.asList(productIdList));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        else if(type.equals("xiap.buy")){
            try {
                JSONObject data = new JSONObject(json);
                String productId = data.getString("productId");
                String payload = data.getString("payload");

                Log.i("OM", "xiap.buy buy productId:"+productId+" extData:"+payload);
                XIAPHelper.getInstance().buy(productId, payload);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        else if(type.equals("xiap.consume")){
            try {
                JSONObject data = new JSONObject(json);
                String productId = data.getString("productId");

                Log.i("OM", "xiap.consume buy productId:"+productId);
                XIAPHelper.getInstance().consume(productId);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        else
        {
            NativeInterface.SendMsgToUnity(type, json);
        }
    }

    XIAPHelper.Delegate mXIAPDelegate = new XIAPHelper.Delegate() {
        @Override
        public void onXIAPIinitError(int code, String msg) {
            Log.e("XIAP", "onXIAPIinitError errCode:"+code + " errMsg:"+msg);
            try {
                JSONObject obj = new JSONObject();
                obj.put("err_code", code);
                obj.put("err_msg", msg);
                NativeInterface.SendMsgToUnity("xiap.init.error", obj);
            } catch (JSONException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }

        @Override
        public void onXIAPIinitSuccess(Inventory inventory) {
            Log.i("XIAP", "onXIAPIinitSuccess init success");
            List<SkuDetails> products = inventory.getAllSkus();

            JSONObject price_map = new JSONObject();
            for(int i = 0; i < products.size(); ++i)
            {
                SkuDetails sku = products.get(i);
                try {
                    price_map.put(sku.getSku(),sku.getPrice());
                } catch (JSONException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
            }

            NativeInterface.SendMsgToUnity("xiap.init.success", price_map);
        }

        @Override
        public void onXIAPBuyError(int code, String msg) {
            Log.e("XIAP", "onXIAPBuyError errCode:"+code + " errMsg:"+msg);
            try {
                JSONObject obj = new JSONObject();
                obj.put("err_code", code);
                obj.put("err_msg", msg);
                NativeInterface.SendMsgToUnity("xiap.buy.error", obj);
            } catch (JSONException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }

        @Override
        public void onXIAPBuySuccess(Purchase purchase) {
            Log.i("XIAP", "onXIAPBuySuccess , productId:" + purchase.getSku() + " payload:" + purchase.getDeveloperPayload());
            try {
                JSONObject obj = new JSONObject();
                obj.put("token", purchase.getOriginalJson());
                obj.put("payload", purchase.getDeveloperPayload());
                obj.put("googleSign", purchase.getSignature());
                obj.put("productId", purchase.getSku());
                NativeInterface.SendMsgToUnity("xiap.buy.success" ,obj);

            } catch (JSONException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
    };

    @Override
    public String GetInfoForUnity(String type, String json) {
        if (type.equals("obb.get.main.filepath")) {
            try {
                Context context = this;
                File obb_dir = context.getObbDir();
                PackageManager manager = context.getPackageManager();
                PackageInfo info = manager.getPackageInfo(context.getPackageName(), 0);
                return String.format("%s/main.%d.%s.obb",obb_dir.getPath(), info.versionCode, info.packageName);
            } catch (Exception e) {
                e.printStackTrace();
                return "";
            }
        }
        return type;
    }
}
