using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.IO;
using System.Linq;
using System.Text;

using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(AudioSource))]
public class RecordMgr : MonoBehaviour {

    public Text text;
    public bool no_support = false;

    [TooltipAttribute("check at start, will change according to device")]
    public int in_sample_frequency = 44100;
    [Range(0,9)]
    public int quality = 3;
    [Range(16,320)]
    public int bit_rate = 16;
    [Range(10,300)]
    public int max_record_len = 60;

    string path_ = "om/record";
    string path_wav = "om/record.wav";
    string path_mp3 = "om/record.mp3";
    AudioSource _audio_source = null;

    AudioClip _recorder_clip = null;
    FileStream _recorder_file = null;
    int _recorder_pos = 0;

    void LOG(string msg)
    {
        Debug.Log(string.Format("[LocalRecord] {0}", msg));
    }

    // Use this for initialization
    void Start()
    {
        path_ = Path.Combine(Application.persistentDataPath, "om/record");
        path_wav = path_ + ".wav";
        path_mp3 = path_ + ".mp3";

        _audio_source = GetComponent<AudioSource>();

        if (Microphone.devices.Count() == 0)
        {
            LOG("Init Failed no devices");
            no_support = true;
            return;
        }

        // Check in sample frequency
        {
            int min_freq, max_frep;
            Microphone.GetDeviceCaps(null, out min_freq, out max_frep);
            if (max_frep == 0) max_frep = Int32.MaxValue;
            in_sample_frequency = Mathf.Clamp(in_sample_frequency, min_freq, max_frep);
        }

        // Make sure record dir exist
        Directory.CreateDirectory(Path.GetDirectoryName(path_));

        // Init recorder
        lame.InitRecorder(GetSamepleFrequency(), 16, 3, path_);
    }

    public void ConvertToMp3()
    {
        Func<string, int> get_file_length = (string path) =>
        {
            FileInfo file_info = new FileInfo(path);
            return (int)file_info.Length;
        };
        SetInfo(string.Format("conver to mp3 \n {0} : {1} \n {2} : {3}",
            path_wav, get_file_length(path_wav),
            path_mp3, get_file_length(path_mp3)));
    }

    public void PlayMp3()
    {
        StartCoroutine(ReadAndPlay(path_mp3));
    }
	
	// Update is called once per frame
	void Update () {
        if(!no_support)
        {
            if(_recorder_clip != null)
            {
                if (Microphone.IsRecording(null))
                {
                    float avg = WriteRecordData();
                    SetInfo(string.Format("{0:F2} volume: {1:F4}", _recorder_pos * 1.0 / in_sample_frequency, avg));
                }
                else
                {
                    EndRecord();
                    SetInfo(string.Format("{0:F2} auto end", _recorder_pos * 1.0 / in_sample_frequency)); ;
                }
            }
        }

	}


    float WriteRecordData()
    {
        int cur_pos = Microphone.GetPosition(null) - in_sample_frequency/10;// 结尾0.1的录音也不要。
        int len = cur_pos - _recorder_pos;
        float volume = 0;
        if(len > 0)
        {
            float[] samples = new float[len];
            _recorder_clip.GetData(samples, _recorder_pos);
            _recorder_pos += len;
            lame.AppendSameples(samples);
            
            for(int i = 0; i < len; ++i)
            {
                volume = Mathf.Max(volume, samples[i]);
            }
        }
        return volume;
    }

    void SetInfo(string info)
    {
        if (text != null)
        {
            text.text = info;
        }
    }

    public void StartRecord()
    {
        if (no_support)
        {
            return;
        }
        Debug.Log("StartRecord");
        if(_recorder_clip != null)
        {
            Debug.LogError("repeat start record");
            _recorder_clip = null;
            lame.EndRecord();
        }
        if (Microphone.IsRecording(null)) Microphone.End(null);

        _recorder_clip = Microphone.Start(null, false, GetMaxRecordLength(), GetSamepleFrequency());
        lame.ReadyToRecord();
        _recorder_pos = in_sample_frequency / 10;// 前0.1秒的声音不要了。
    }

    public void EndRecord()
    {
        if(no_support)
        {
            return;
        }
        Debug.Log("EndRecord");
        if (_recorder_clip == null) return;

        if(Microphone.IsRecording(null))
        {
            Microphone.End(null);
            // play it imm
            _audio_source.clip = _recorder_clip;
            _audio_source.Play();
        }

        _recorder_clip = null;
        lame.EndRecord();
    }

    public void PlayRecord()
    {
        Debug.Log("PlayRecord");
//#if UNITY_IOS || UNITY_ANDROID
//        StartCoroutine(ReadAndPlay(path_mp3));
//#else
        StartCoroutine(ReadAndPlay(path_wav));
//#endif
    }

    IEnumerator ReadAndPlay(string path,bool is_local = true)
    {
        if(is_local)
        {
            if(File.Exists(path) == false)
            {
                SetInfo("Local File does not exsits \n" + path);
                yield break;
            }
            path = "file://" + path;
        }

        WWW w = new WWW(path);
        yield return w;
        if(string.IsNullOrEmpty(w.error) == false)
        {
            SetInfo("WWW error:\n" + w.error + "\n" + path);
            yield break;
        }
        try
        {
            _audio_source.clip = w.GetAudioClip(false);// Not 3D, 3D will feel diffrent, too low or other
            _audio_source.Play();
            SetInfo("play \n" + path);
        }catch(Exception e)
        {
            SetInfo(e.Message);
        }
    }

    public void PrintDeviceInfo()
    {
        Debug.Log("PrintDeviceInfo");
        SetInfo(GetDebugInfo());
        //StartCoroutine(ReadAndPlay(Application.streamingAssetsPath + '/' + "xx.mp3", false));
    }

    // 获取录音采样率
    int GetSamepleFrequency()
    {
        return in_sample_frequency;
    }

    // 获取最大录音长度，单位秒
    int GetMaxRecordLength()
    {
        return max_record_len;
    }

    string GetDebugInfo()
    {
        if(no_support)
        {
            return "do not support record";
        }
        string info = "";

        info += "Devices:\n";
        for (int i = 0; i < Microphone.devices.Count(); ++i)
        {
            info += i + ". " + Microphone.devices[i] + "\n";
        }
        info += "\n";

        if(Microphone.devices.Count() > 0)
        {
            int min_freq, max_frep;
            Microphone.GetDeviceCaps(null, out min_freq, out max_frep);
            info += "sample frequency [" + min_freq + " ," + max_frep + "]\n";
            info += "working freq " + in_sample_frequency + "\n";
        }

        return info;
    }
}
