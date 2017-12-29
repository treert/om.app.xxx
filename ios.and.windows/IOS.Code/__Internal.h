/*header
    > File Name: __Internal.h
    > Create Time: 2017-12-28 星期四 20时59分10秒
    > Athor: treertzhu
*/
#ifndef ____Internal__
#define ____Internal__

#ifdef _cplusplus  
extern "C" {
#endif


    void U3D_RecvMsgFromUnity(const char * type , const char * content);
    const char * U3D_GetSDKConfig(const char * type, const char * content);

#ifdef _cplusplus  
}
#endif

#endif
