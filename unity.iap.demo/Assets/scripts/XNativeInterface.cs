using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;

using UnityEngine;

class XNativeInterface
{
    const string AndoridNativeInterfaceClass = "com.zhuguosen.u3d.NativeInterface";
#if UNITY_ANDROID

#endif
#if UNITY_IPHONE
    [DllImport("__Internal")]
	private static extern void U3D_SendMsg(string type, string content);

    [DllImport("__Internal")]
	private static extern IntPtr U3D_GetInfo(string type, string content);
#endif

    private static void AndroidInvoke(string _itf_obj_name, string method, params object[] args)
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
        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
        {
#if UNITY_ANDROID
            AndroidInvoke("SendMsg", type, json);
#elif UNITY_IPHONE
			U3D_SendMsg(type, json);
#endif
        }
    }

    public static string GetInfo(string type, string json)
    {
        string defaultValue = "";
        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
        {
#if UNITY_ANDROID
            defaultValue = AndroidInvoke<string>("GetInfo", type, json);
#elif UNITY_IPHONE
			defaultValue = Marshal.PtrToStringAnsi(U3D_GetInfo(type, json));
#endif
        }
        return defaultValue;
    }
}
