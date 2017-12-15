package com.zhuguosen.u3d;
import com.unity3d.player.UnityPlayer;
import org.json.*;

public class NativeInterface {
    public interface Delegate{
        void RecvMsgFromUnity(String type, String json);
        String GetInfoForUnity(String type, String json);
    }

    public static Delegate mDelegate = new Delegate() {
        @Override
        public void RecvMsgFromUnity(String type, String json) {

        }

        @Override
        public String GetInfoForUnity(String type, String json) {
            return "";
        }
    };

    public static void RecvMsgFromUnity(String type, String json){
        mDelegate.RecvMsgFromUnity(type, json);
    }

    public static void SendMsgToUnity(String type, Object json){
        JSONObject msg = new JSONObject();
        try{
            msg.put("type",type);
            msg.put("json",json);
        }catch (JSONException e){
            e.printStackTrace();
        }
        SendMsgToUnity(msg.toString());
    }

    public static  void SendMsgToUnity(String msg){
        UnityPlayer.UnitySendMessage("GamePoint","RecvNativeMsg",msg);
    }

    public static String GetInfoForUnity(String type, String json){
        return mDelegate.GetInfoForUnity(type, json);
    }
}
