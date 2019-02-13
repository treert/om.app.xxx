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

    [MenuItem("Assets/BuildAB",priority = 900)]
    static void BuildAB()
    {
        UnityEngine.Object[] objs = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets);
        if(objs.Length > 0)
        {
            var obj = objs[0];
            var path = AssetDatabase.GetAssetPath(obj);
            var dir = Path.GetDirectoryName(path);

            dir = "Assets/StreamingAssets/";
            Directory.CreateDirectory(dir);

            var name = Path.GetFileName(path);
            AssetBundleBuild build = new AssetBundleBuild();
            build.assetBundleName = name + ".ab";
            build.assetNames = new string[] { path };

            Debug.Log(build.assetBundleName);
            BuildPipeline.BuildAssetBundles(dir,
                new AssetBundleBuild[] { build },
                BuildAssetBundleOptions.ChunkBasedCompression, 
                EditorUserBuildSettings.activeBuildTarget);
            AssetDatabase.ImportAsset(dir + build.assetBundleName);
        }
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
