//
//  Test.m
//  ORMDB
//
//  Created by mao PengLin on 2017/6/8.
//  Copyright © 2017年 PengLinmao. All rights reserved.
//

#import "Test.h"

@implementation Test
+(NSString *)primarilyKey{
    return  @"one";
}
+(NSDictionary<NSString *, NSString *> *_Nonnull)foreignKeyNotCreateTable{
    return @{@"test":@"Student"};
}
@end
