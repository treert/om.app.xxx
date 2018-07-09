using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;
using UnityEngine;


class XPlatform : MonoBehaviour
{
    [SerializeField]
    UnityEngine.UI.Text _textStatus = null;

    LinkedList<string> _texts = new LinkedList<string>();
    public void SetStatusMsg(string msg)
    {
        _texts.AddFirst("<color=red>#</color> " + msg);
        if(_texts.Count > 10)
        {
            _texts.RemoveLast();
        }
        _textStatus.text = string.Join("\n",_texts.ToArray());
    }

    public void SendMsgToNative(string type, string json = "")
    {
        SetStatusMsg(type + " : " + json); 
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
