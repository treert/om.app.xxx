
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lame.h"

// 强制使用小端序
static void write_16_bits_low_high(FILE * fp, int val)
{
    unsigned char bytes[2];
    bytes[0] = (val & 0xff);
    bytes[1] = ((val >> 8) & 0xff);
    fwrite(bytes, 2, 1, fp);
}

static void write_32_bits_low_high(FILE * fp, int val)
{
    unsigned char bytes[4];
    bytes[0] = (val & 0xff);
    bytes[1] = ((val >> 8) & 0xff);
    bytes[2] = ((val >> 16) & 0xff);
    bytes[3] = ((val >> 24) & 0xff);
    fwrite(bytes, 4, 1, fp);
}

#define RECORD_WAV 1

#define MP3BUF_SIZE 8192
#define ENCODE_SAMPLES_LIMIT 512 //
//#define be_short(s) ((short) ((unsigned short) (s) << 8) | ((unsigned short) (s) >> 8))

static lame_t lame = NULL;
static char path_wav[256] = {0};
static FILE *outfile_wav = NULL;
static char path_mp3[256] = {0};
static FILE *outfile_mp3 = NULL;
static int pcm_count = 0;
static int pcm_freq = 0;

int
is_lame_global_flags_valid(const lame_global_flags * gfp);

int Lame_InitRecorder(int in_samplerate, int brate, int quality, const char *record_path)
{
    lame = lame_init();
    if (!is_lame_global_flags_valid(lame))
    {
        return -1;
    }

	lame_set_num_channels(lame, 1);// Only support one channel
	lame_set_in_samplerate(lame, in_samplerate);
    //lame_set_out_samplerate(lame, out_samplerate); // not used for MP3 decoding
    //lame_set_mode(lame, STEREO);// 不懂有什么影响，默认MONO
	lame_set_brate(lame, brate);// 固定比特率
	//lame_set_VBR(lame, vbr_default);// 动态比特率
	lame_set_quality(lame, quality);// 压缩质量，影响压缩速度

    lame_set_scale(lame, 4);// 放大音量，噪音会增大

	pcm_freq = in_samplerate;

	strcpy(path_wav,record_path);
	strcat(path_wav,".wav");
    strcpy(path_mp3,record_path);
	strcat(path_mp3,".mp3");

	return lame_init_params(lame);
}

int Lame_DestroyEncoder()
{
	return lame_close(lame);
}

static int WriteWaveHeader(FILE * const fp, int pcmbytes, int freq, int channels, int bits)
{
    int     bytes = (bits + 7) / 8;

    /* quick and dirty, but documented */
    fwrite("RIFF", 1, 4, fp); /* label */
    write_32_bits_low_high(fp, pcmbytes + 44 - 8); /* length in bytes without header */
    fwrite("WAVEfmt ", 2, 4, fp); /* 2 labels */
    write_32_bits_low_high(fp, 2 + 2 + 4 + 4 + 2 + 2); /* length of PCM format declaration area */
    write_16_bits_low_high(fp, 1); /* is PCM? */
    write_16_bits_low_high(fp, channels); /* number of channels */
    write_32_bits_low_high(fp, freq); /* sample frequency in [Hz] */
    write_32_bits_low_high(fp, freq * channels * bytes); /* bytes per second */
    write_16_bits_low_high(fp, channels * bytes); /* bytes per sample time */
    write_16_bits_low_high(fp, bits); /* bits per sample */
    fwrite("data", 1, 4, fp); /* label */
    write_32_bits_low_high(fp, pcmbytes); /* length in bytes of raw PCM data */

    return ferror(fp) ? -1 : 0;
}

int Lame_ReadyToRecord()
{
    if(outfile_mp3 != NULL) {
        fclose(outfile_mp3);outfile_mp3 = NULL;
        #if RECORD_WAV
        fclose(outfile_wav);outfile_wav = NULL;
        #endif // RECORD_WAV
        return -1;
    }

    outfile_mp3 = fopen(path_mp3, "wb");
#if RECORD_WAV
    outfile_wav = fopen(path_wav, "wb");
    char pad[44] = {0};
    fwrite(pad,44,1,outfile_wav);
#endif // RECORD_WAV
    return 0;
}

int Lame_AppendSameples(const float *samples, int len)
{
    if(outfile_mp3 == NULL) return -1;

	uint8_t output[MP3BUF_SIZE];
	int nb_write = 0;
    int idx = 0;
    int once = 0;
    while(idx < len)
    {
        once = len - idx;
        if( once > ENCODE_SAMPLES_LIMIT) once = ENCODE_SAMPLES_LIMIT;
        nb_write = lame_encode_buffer_ieee_float(lame,
                samples + idx, samples + idx, once,
                output, MP3BUF_SIZE);
		fwrite(output, nb_write, 1, outfile_mp3);
		idx += once;
    }
#if RECORD_WAV
    int16_t sample;
    for(idx = 0; idx < len; ++idx)
    {
        sample = samples[idx]*32767;
        write_16_bits_low_high(outfile_wav, sample);
    }
    pcm_count += 2*len;
#endif // RECORD_WAV
    return 0;
}

int Lame_EndRecord()
{
    if(outfile_mp3 == NULL) return -1;

    uint8_t output[MP3BUF_SIZE];
	int nb_write = lame_encode_flush(lame, output, MP3BUF_SIZE);
	fwrite(output, nb_write, 1, outfile_mp3);
	fclose(outfile_mp3);
	outfile_mp3 = NULL;
#if RECORD_WAV
    fseek(outfile_wav,0l,SEEK_SET);
    WriteWaveHeader(outfile_wav, pcm_count, pcm_freq, 1, 16);
    fclose(outfile_wav);
    outfile_wav = NULL;
#endif // RECORD_WAV
    return 0;
}
