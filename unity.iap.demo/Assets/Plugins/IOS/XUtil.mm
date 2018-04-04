#import "XUtil.h"

#import <CommonCrypto/CommonDigest.h>

// 加密私钥，写死在代码中
// 为了防止泄露，打包静态库，只提供.h和.a文件用于集成
static NSString * encryptionKey = @"eDaodut6k@jNscgc";

@implementation XUtil


#pragma mark - MD5加密

+ (NSString *)md5EncryptionWithString:(NSString *)string
{
	return [self md5:[NSString stringWithFormat:@"%@%@", encryptionKey, string]];
}

+ (NSString *)md5:(NSString *)string
{
	const char * cStr = [string UTF8String];

	// #define CC_MD5_DIGEST_LENGTH 16
	unsigned char digest[CC_MD5_DIGEST_LENGTH];

	// typedef uint32_t CC_LONG;
	// extern unsigned char *CC_MD5(const void *data, CC_LONG len, unsigned char *md);
	CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);

	NSMutableString * result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	{
		[result appendFormat:@"%02X", digest[i]];
	}

	return result;
}

/*
+ (NSString *)md5:(NSString *)string
{
    const char * cStr = [string UTF8String];

    unsigned char result[16];

	// This is the md5 call
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);

    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
*/


#pragma mark - 获取当前时间戳

+ (NSString *)getCurrentTime
{
    // 单位为秒
    NSDate * recordTime = [NSDate dateWithTimeIntervalSinceNow:0];
    
    NSString * localTime = [NSString stringWithFormat:@"%ld", (long)[recordTime timeIntervalSince1970]];

    /*
	// 格式化输出
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

	NSString * date = [formatter stringFromDate:[NSDate date]];

	NSString * localTime = [[NSString alloc] initWithFormat:@"%@", date];
     */
	
	return localTime;
}


#pragma mark - Base64编码

+ (NSString *)base64EncodeWithString:(NSString *)string
{
	NSData * stringData = [string dataUsingEncoding:NSASCIIStringEncoding];
    const uint8_t * input = (const uint8_t *)[stringData bytes];
    NSInteger length = [stringData length];

    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData * data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t * output = (uint8_t *)data.mutableBytes;

    NSInteger i;
    for (i=0; i < length; i += 3)
    {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++)
        {
            value <<= 8;

            if (j < length)
            {
                value |= (0xFF & input[j]);
            }
        }

        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}


#pragma mark - json格式字符串与字典互转

// 字典转换成json格式字符串
+ (NSString *)dicToJson:(NSDictionary *)dic
{
	NSError * parseError = nil;

	NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];

	NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	return jsonStr;
}

// json格式字符串转换成字典
+ (NSDictionary *)dicWithJson:(NSString *)jsonStr
{
	if (jsonStr == nil)
	{
		return nil;
	}

	NSData * jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    
	NSError * parseError = nil;
    
	NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&parseError];

	if (dic == nil)
	{
		NSLog(@"XUtil ::: json parse fail");

		return nil;
	}

	return dic;
}

// 数组转为json格式字符串
+ (NSString *)arrayToJson:(NSArray *)array;
{
    NSError * parseError = nil;
    
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&parseError];
    
    NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonStr;
}

@end
