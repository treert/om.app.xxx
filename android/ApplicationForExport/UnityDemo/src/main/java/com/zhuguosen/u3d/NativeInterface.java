package com.zhuguosen.u3d;
import com.unity3d.player.UnityPlayer;
import org.json.*;

public class NativeInterface {
    public static void RecvMsgFromUnity(String type, String json){

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

    public static String GetInfo(String type, String json){
        return "GetInfo";
    }
}
