using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

using UnityEngine;

class XNativeInterface
{

#if UNITY_ANDROID

#endif
#if UNITY_IPHONE
    [DllImport("__Internal")]
	private static extern void U3D_RecvMsgFromUnity(string type, string content);

    [DllImport("__Internal")]
	private static extern IntPtr U3D_GetInfoForUnity(string type, string content);
#endif

    const string AndoridNativeInterfaceClass = "com.zhuguosen.u3d.NativeInterface";
    private static void AndroidInvoke(string method, params object[] args)
    {
        if (Application.platform == RuntimePlatform.Android)
        {
            using (AndroidJavaClass jc = new AndroidJavaClass(AndoridNativeInterfaceClass))
            {
                jc.CallStatic(method, args);
            }
        }
    }

    private static T AndroidInvoke<T>(string method, params object[] args)
    {
        if (Application.platform == RuntimePlatform.Android)
        {
            using (AndroidJavaClass jc = new AndroidJavaClass(AndoridNativeInterfaceClass))
            {
                return jc.CallStatic<T>(method, args);
            }
        }
        return default(T);
    }

    public static void SendMsg(string type, string json)
    {
#if !UNITY_EDITOR
#if UNITY_ANDROID
            AndroidInvoke("RecvMsgFromUnity", type, json);
#elif UNITY_IPHONE
			U3D_RecvMsgFromUnity(type, json);
#endif
#endif
    }

    public static string GetInfo(string type, string json)
    {
        string defaultValue = "";
#if !UNITY_EDITOR
#if UNITY_ANDROID
            defaultValue = AndroidInvoke<string>("GetInfoForUnity", type, json);
#elif UNITY_IPHONE
			defaultValue = Marshal.PtrToStringAnsi(U3D_GetInfoForUnity(type, json));
#endif
#endif
        return defaultValue;
    }
}
