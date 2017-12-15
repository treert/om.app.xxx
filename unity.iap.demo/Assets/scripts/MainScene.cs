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

    public void OnClickXIAPInit()
    {
        Dictionary<string, object> jsonData = new Dictionary<string, object>();
        //jsonData["publicKey"] = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAi5IX+YiRL0988WDsvVKF3bTfEqFuRm9PJ+n7dFkgW8S6GqaGF/k/O1RhVSgAk9gEUZCHjUG02SyA0KlWuAn8eHLPT6/Fm8x72tMl1WfvFjW1+4VFFf7/2Qgr1661jlnweYuVHP3J2e2s9v05CLNuBo2599y2a9BAK2vrTRBcu+/456aiFLVmpvZ3CXcAV6Qaps2BWe6DEEfAND2RSNYxdL0imOzUl9s4NKq/Z7IHKbavJTBct5ILjVshb5iwgFxWARYZKg6G/epcUOsJcM1AWBA2ik39gBkyGGYXIWp1Qjz4V9iPYVXWvFce7t7+9AVt0KGQ8sIfGD0j+jOEZTCL1wIDAQAB";
        jsonData["publicKey"] = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp2IBeOvkYOAVsyAhvFIRktYjInmjKFbqmdn5haLGKWi46QIbS82gPdAxYoq2dc5bC/zIXjBDns/LmbKE7hQy+VvsI4BZF+bhCQ50UKubMKeNH7AI/sQvNUgcpqseLppVylw56JKwRCLJoytSku/TvKulrgLx+DEyCwHdyxh/IQSAJGfE0sOg1eTMotxUG3KR0EnA9pnaP4S+Dka0f22fhYo2+MoGAYHyVfdlaGuXwve3kWiVSDiStn3sXCwmHpDtbtBEyjT7x6SOMygOhCdSM9W7rQoV8sZpBZxy+KWvn1ZxxMV9/x4CcRPT8zx3++bxJx6X+nxZqIu2Xbh3g65OfwIDAQAB";
        jsonData["productIdList"] = "premium,gas";

        var str = Json.Serialize(jsonData);
        XPlatform.singleton.SendMsgToNative("xiap.init", str);
    }

    public void OnClickXIAPBuy()
    {
        Dictionary<string, object> jsonData = new Dictionary<string, object>();
        jsonData["productId"] = "gas";
        jsonData["payload"] = System.DateTime.Now.ToLongDateString();

        var str = Json.Serialize(jsonData);
        XPlatform.singleton.SendMsgToNative("xiap.buy", str);
    }

    public void OnClickXIAPConsume()
    {

    }
}
