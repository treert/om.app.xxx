using System;
using System.Runtime.InteropServices;
using UnityEngine;
using System.Collections;
using System.IO;

public class lame
{
#if UNITY_IPHONE
    [DllImport("__Internal")]
    public static extern int InitRecorder(int in_samplerate, int brate, int quality, string record_path);
    [DllImport("__Internal")]
    public static extern int DestroyEncoder();
    [DllImport("__Internal")]
    public static extern int ReadyToRecord();
    [DllImport("__Internal")]
    public static extern int EndRecord();
    [DllImport("__Internal")]
    public static extern int AppendSameples(float[] samples, int len);
#else
    [DllImport("mp3lame")]
    public static extern int InitRecorder(int in_samplerate, int brate, int quality,string record_path);
    [DllImport("mp3lame")]
    public static extern int DestroyEncoder();
    [DllImport("mp3lame")]
    public static extern int ReadyToRecord();
    [DllImport("mp3lame")]
    public static extern int EndRecord();
    [DllImport("mp3lame")]
    public static extern int AppendSameples(float[] samples, int len);

#endif
    public static int AppendSameples(float[] samples)
    {
        return AppendSameples(samples, samples.Length);
    }
}