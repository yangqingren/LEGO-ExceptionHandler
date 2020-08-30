//
//  LEGOExceptionHandler.h
//  LEGO-ExceptionHandler_Example
//
//  Created by 杨庆人 on 2020/8/30.
//  Copyright © 2020 564008993@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LEGOExceptionHandler : NSObject

void RegisterExceptionHandler(void);

+ (NSDictionary *)getCrashInfoPathCache;

+ (void)removeCrashInfoPathCache;

@end

NS_ASSUME_NONNULL_END
