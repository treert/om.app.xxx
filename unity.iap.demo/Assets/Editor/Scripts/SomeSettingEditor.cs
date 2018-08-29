using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class SomeSettingEditor : EditorWindow {

	[MenuItem("Assets/Create/SomeSetting")]
    static void CreateSomeSetting()
    {
        var path = Path.Combine(GetSelectedDir(), "XSomeSetting.asset");
        XSomeSetting data = ScriptableObject.CreateInstance<XSomeSetting>();
        AssetDatabase.CreateAsset(data, path);
        AssetDatabase.SaveAssets();
    }

    public static string GetSelectedDir()
    {
        string dir = "Assets";
        foreach (UnityEditor.DefaultAsset obj in Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets))
        {
            var path = AssetDatabase.GetAssetPath(obj);
            if (!string.IsNullOrEmpty(path) && Directory.Exists(path))
            {
                dir = path;
                break;
            }
        }
        return dir;
    }

    //public static string GetSelectedPathOrFallback()
    //{
    //    string path = "Assets";
    //    foreach (UnityEngine.Object obj in Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets))
    //    {
    //        path = AssetDatabase.GetAssetPath(obj);
    //        if (!string.IsNullOrEmpty(path) && File.Exists(path))
    //        {
    //            path = Path.GetDirectoryName(path);
    //            break;
    //        }
    //    }
    //    return path;
    //}
}
