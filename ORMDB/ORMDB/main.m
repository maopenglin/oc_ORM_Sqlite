//
//  main.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TestEntity.h"

#import "NSObject+ORM.h"
#import "ORMDB.h"

#import "ORM.h"
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        ORM *orm=[[ORM alloc] init];
        [orm test:[TestEntity class]];
        
        NSString *s=@"123456789";
        NSRange range=NSMakeRange(2, 3);
       NSLog(@"range:%@", [s substringWithRange:range]);
        
        /*
        [TestEntity createTable];
        [ORMDB beginTransaction];
        TestEntity *test=[[TestEntity alloc] init];
        test.name=@"测试";
        test.age=@(18);
        test.mId=@(1);
        
        TestBEntity *b=[[TestBEntity alloc] init];
        b.address=@"北京市海淀区";
        test.classB=b;
        
        NSMutableArray *arr=[[NSMutableArray alloc] init];
        ClassC *c1=[[ClassC alloc] init];
        c1.pA=@"pa 1";
        c1.pB=@"pb 1";
        [arr addObject:c1];
        
        ClassC *c2=[[ClassC alloc] init];
        c2.pA=@"pa 2";
        c2.pB=@"pb 2";
        [arr addObject:c2];
        test.clsC=@[c1,c2].mutableCopy;
        
        [test save:@[@"mId"]];
        [ORMDB commitTransaction];
        
        TestEntity *t=[TestEntity getObject:@[@"mId"] withValue:@[@(1)]];
        
        NSMutableArray *arrt=[TestEntity list:@[@"mId"] withValue:@[@(1)] ];
        NSLog(@"arrt %@",arrt);
        for (int i=0; i<t.clsC.count; i++) {
            ClassC *c=t.clsC[i];
            NSLog(@"c pa:%@,c pb:%@",c.pA,c.pB);
        }
        NSLog(@"test.b:%@ classB cID %i count:%i",t.name,[t.classB.cID intValue],(int)t.clsC.count);
        [TestEntity clearTable];
        t=[TestEntity getObject:@[@"mId"] withValue:@[@(1)]];
        NSLog(@"test.b:%@ classB cID %i count:%i",t.name,[t.classB.cID intValue],(int)t.clsC.count);
         */
    }
    return 0;
}
