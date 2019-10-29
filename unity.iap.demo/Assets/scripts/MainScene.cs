using System.IO;

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using MiniJSON;
using System;
using System.Text;

public class MainScene : MonoBehaviour {

    [SerializeField]
    XSomeSetting m_some_setting;

    private string _sample_good;

    // Use this for initialization
    void Start () {
        if (Application.platform == RuntimePlatform.Android)
        {
            _sample_good = m_some_setting.SampleProductIdForGoogle;
        }
        else
        {
            _sample_good = m_some_setting.SampleProductIdForApple;
        }
    }
	
	// Update is called once per frame
	void Update () {
		
	}

    public void OnClickTest()
    {
        string[] infos = new string[] {
            "dataPath: " + Application.dataPath,
            "streamingAssetsPath: " + Application.streamingAssetsPath,
            "persistentDataPath: " + Application.persistentDataPath,
        };

        string str = string.Join("\n",infos);
        AssetBundle ab = null;
        StringBuilder sb = new StringBuilder();
        sb.AppendLine(str);

        if(Application.platform == RuntimePlatform.Android)
        {
            sb.AppendLine();
            str = Application.dataPath + "!assets/xx.txt.ab";// 这儿的assets之前没有/，和streamingAssetsPath不一样的。
            sb.AppendLine(str);
            sb.AppendLine(File.Exists(str).ToString());
            ab = AssetBundle.LoadFromFile(str);
            sb.AppendLine(ab == null ? "null" : "exsit");
            if (ab != null) ab.Unload(true);
        }

        sb.AppendLine();
        str = Application.streamingAssetsPath + "/xx.txt.ab";
        sb.AppendLine(str);
        sb.AppendLine(File.Exists(str).ToString());
        ab = AssetBundle.LoadFromFile(str);
        sb.AppendLine(ab == null ? "null" : "exsit");
        if (ab != null) ab.Unload(true);

        // 报错。
        //sb.AppendLine("Test File.Read");
        //var bytes = File.ReadAllBytes(str);
        //sb.AppendLine((bytes == null ? -1 : bytes.Length).ToString());

        // File.Exsits 在Android里不能用于StreamingAssets，里面的资源实际在压缩包里
        // 有种方法可以模拟，需要读取压缩包索引，非常骚操作
        // https://github.com/gwiazdorrr/BetterStreamingAssets

        XPlatform.singleton.SetStatusMsg(sb.ToString());
        //XPlatform.singleton.SendMsgToNative("test","");
    }

    public void OnClickXIAPInit()
    {
        Dictionary<string, object> jsonData = new Dictionary<string, object>();
        if (Application.platform == RuntimePlatform.Android)
        {
            // jsonData["publicKey"] = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp2IBeOvkYOAVsyAhvFIRktYjInmjKFbqmdn5haLGKWi46QIbS82gPdAxYoq2dc5bC/zIXjBDns/LmbKE7hQy+VvsI4BZF+bhCQ50UKubMKeNH7AI/sQvNUgcpqseLppVylw56JKwRCLJoytSku/TvKulrgLx+DEyCwHdyxh/IQSAJGfE0sOg1eTMotxUG3KR0EnA9pnaP4S+Dka0f22fhYo2+MoGAYHyVfdlaGuXwve3kWiVSDiStn3sXCwmHpDtbtBEyjT7x6SOMygOhCdSM9W7rQoV8sZpBZxy+KWvn1ZxxMV9/x4CcRPT8zx3++bxJx6X+nxZqIu2Xbh3g65OfwIDAQAB";
            jsonData["publicKey"] = m_some_setting.GoogleIAPBase64Key;
        }

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

    public void OnClickTestOBB()
    {
        XPlatform.singleton.SetStatusMsg("click test obb");

        string main_obb_file = XPlatform.singleton.GetInfoFromNative("obb.get.main.filepath");
        XPlatform.singleton.SetStatusMsg("obb file: " + main_obb_file);
        if (string.IsNullOrEmpty(main_obb_file) == false)
        {
            FileInfo file_info = new FileInfo(main_obb_file);
            XPlatform.singleton.SetStatusMsg("file info: " + file_info.Exists + (file_info.Exists ? file_info.Length: 0));
        }
    }
}
