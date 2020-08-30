//
//  LEGOExceptionHandler.m
//  LEGO-ExceptionHandler_Example
//
//  Created by 杨庆人 on 2020/8/30.
//  Copyright © 2020 564008993@qq.com. All rights reserved.
//

#import "LEGOExceptionHandler.h"

#define CrashLogDirectory @"CrashLog"
#define CrashLogFileName @"crashLog.log"

NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

@interface LEGOExceptionHandler ()

@end

NSUncaughtExceptionHandler *OldHandler = nil;

@implementation LEGOExceptionHandler

void RegisterExceptionHandler(void) {
    if (NSGetUncaughtExceptionHandler() != ExceptionHandler) {
        OldHandler = NSGetUncaughtExceptionHandler();
    }
    NSSetUncaughtExceptionHandler(&ExceptionHandler);
}

void ExceptionHandler(NSException *exception) {
    NSArray *callStack = exception.callStackSymbols;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];

    [[[LEGOExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
    
    // 调用之前已经注册的handler
    if (OldHandler) {
        OldHandler(exception);
    }
}

- (void)handleException:(NSException *)exception{
    
    NSString *stackInfo = [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey];
    
    [self.class collectCrashInfoWithException:exception exceptionStackInfo:stackInfo];
    
//    NSSetUncaughtExceptionHandler(NULL);
    
    [exception raise];
}

+ (void)collectCrashInfoWithException:(NSException *)exception exceptionStackInfo:(NSString *)exceptionStackInfo {
    NSMutableDictionary *crashInfoDic = [NSMutableDictionary dictionary];

//require
    NSString *dateStr = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    [crashInfoDic setObject:dateStr forKey:@"date"];
    [crashInfoDic setObject:exception.name forKey:@"type"];
    [crashInfoDic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:@"version"];
    //exception log info
    NSMutableDictionary *exceptionInfoDic = [NSMutableDictionary dictionary];
    [exceptionInfoDic setObject:exception.name forKey:@"exception_name"];
    [exceptionInfoDic setObject:exception.reason forKey:@"exception_reason"];
    [exceptionInfoDic setObject:exceptionStackInfo forKey:@"exception_stackInfo"];
    [crashInfoDic setObject:exceptionInfoDic forKey:@"log"];
    
//optional
#ifdef DEBUG
    [crashInfoDic setObject:@"DEBUG" forKey:@"environment"];
#else
    [crashInfoDic setObject:@"RELEASE" forKey:@"environment"];
#endif
        
    //write
    NSData *newCrashData = [NSJSONSerialization dataWithJSONObject:crashInfoDic options:NSJSONWritingPrettyPrinted error:nil];
    
    @synchronized ([UIApplication sharedApplication]) {
        [newCrashData writeToFile:[self.class getCrashPathCache] atomically:YES];
    }
}


+ (NSString *)getCrashPathCache {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *crashCache = [[paths firstObject] stringByAppendingPathComponent:@"crashInfo"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:crashCache isDirectory:&isDir];
    if (!(isDir == YES && existed == YES) ) {
        [fileManager createDirectoryAtPath:crashCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return [crashCache stringByAppendingPathComponent:@"crashInfo"];
}

+ (NSDictionary *)getCrashInfoPathCache
{
    @synchronized ([UIApplication sharedApplication]) {
        
        NSData *data = [NSData dataWithContentsOfFile:[self.class getCrashPathCache]];
        if (data) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            return dic;
        }
        else {
            return nil;
        }
    }
}

+ (void)removeCrashInfoPathCache
{
    [[NSFileManager defaultManager] removeItemAtPath:[self.class getCrashPathCache] error:nil];
}



@end
