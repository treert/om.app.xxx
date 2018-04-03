using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using MiniJSON;

public class MainScene : MonoBehaviour {

    

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    public void OnClickTest()
    {
        XPlatform.singleton.SetStatusMsg("click test");
        XPlatform.singleton.SendMsgToNative("test","");
    }
#if UNITY_IPHONE
    private string _sample_good = "4181_0_1_180";
#else
    private string _sample_good = "gas";
#endif

    public void OnClickXIAPInit()
    {
        Dictionary<string, object> jsonData = new Dictionary<string, object>();
        if (Application.platform == RuntimePlatform.Android)
        {
            jsonData["publicKey"] = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp2IBeOvkYOAVsyAhvFIRktYjInmjKFbqmdn5haLGKWi46QIbS82gPdAxYoq2dc5bC/zIXjBDns/LmbKE7hQy+VvsI4BZF+bhCQ50UKubMKeNH7AI/sQvNUgcpqseLppVylw56JKwRCLJoytSku/TvKulrgLx+DEyCwHdyxh/IQSAJGfE0sOg1eTMotxUG3KR0EnA9pnaP4S+Dka0f22fhYo2+MoGAYHyVfdlaGuXwve3kWiVSDiStn3sXCwmHpDtbtBEyjT7x6SOMygOhCdSM9W7rQoV8sZpBZxy+KWvn1ZxxMV9/x4CcRPT8zx3++bxJx6X+nxZqIu2Xbh3g65OfwIDAQAB";
        }
        //jsonData["productIdList"] = "premium,gas";
        jsonData["productIdList"] = _sample_good;

        var str = Json.Serialize(jsonData);
        XPlatform.singleton.SendMsgToNative("xiap.init", str);
    }

    public void OnClickXIAPBuy()
    {
        Dictionary<string, object> jsonData = new Dictionary<string, object>();
        jsonData["productId"] = _sample_good;
        jsonData["payload"] = System.DateTime.Now.ToLongDateString();

        var str = Json.Serialize(jsonData);
        XPlatform.singleton.SendMsgToNative("xiap.buy", str);
    }

    public void OnClickXIAPConsume()
    {
        Dictionary<string, object> jsonData = new Dictionary<string, object>();
        jsonData["productId"] = _sample_good;

        var str = Json.Serialize(jsonData);
        XPlatform.singleton.SendMsgToNative("xiap.consume", str);
    }
}
