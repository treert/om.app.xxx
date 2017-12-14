package com.zhuguosen.u3d;

import android.os.Bundle;
import android.util.Log;

import com.unity3d.player.UnityPlayerActivity;

/**
 * Created by treertzhu on 2017/12/14.
 */

public class MyUnityAcitvity extends UnityPlayerActivity implements NativeInterface.Delegate {
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

    @Override
    public void RecvMsgFromUnity(String type, String json) {
        NativeInterface.SendMsgToUnity(type, json);
    }

    @Override
    public String GetInfoForUnity(String type, String json) {
        return type;
    }
}
