//
//  TestBEntity.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import "TestBEntity.h"

@implementation TestBEntity
+(NSString *)foreignKey{
  return @"cID";
}
- (void)xxx{
    NSLog(@"print xxx");
}
- (void)testMedhod{
    testok();
   
    staticmethod();
}

 id  testok(){
     NSLog(@"abeeddd");
    return @"abcdef";
}
void staticmethod(){
    printf("abc");
}
@end
