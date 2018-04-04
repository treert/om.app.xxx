#import <Foundation/Foundation.h>

@interface XUtil : NSObject

// MD5加密
+ (NSString *)md5EncryptionWithString:(NSString *)string;
+ (NSString *)md5:(NSString *)string;

// 获取当前时间戳
+ (NSString *)getCurrentTime;

// Base64编码
+ (NSString *)base64EncodeWithString:(NSString *)string;

// json格式字符串与字典互转
+ (NSString *)dicToJson:(NSDictionary *)dic;
+ (NSDictionary *)dicWithJson:(NSString *)jsonStr;

// 数组转为json格式字符串
+ (NSString *)arrayToJson:(NSArray *)array;

@end
