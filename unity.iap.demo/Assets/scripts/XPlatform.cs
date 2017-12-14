using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


class XPlatform : MonoBehaviour
{
    [SerializeField]
    UnityEngine.UI.Text _textStatus = null;
    public void SetStatusMsg(string msg)
    {
        _textStatus.text = msg;
    }

    public void SendMsgToNative(string type, string json = "")
    {
        XNativeInterface.SendMsg(type, json);
    }

    public void RecvNativeMsg(string json)
    {
        SetStatusMsg(json);
    }

    public string GetInfoFromNative(string type, string json = "")
    {
        return XNativeInterface.GetInfo(type, json);
    }


    static XPlatform _singleton = null;
    public static XPlatform singleton
    {
        get
        {
            if (_singleton == null)
            {
                _singleton = GameObject.Find("GamePoint").GetComponent<XPlatform>();
            }
            return _singleton;
        }
    }
}
