//
//  TestEntity.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestBEntity.h"
#import "ClassC.h"
@interface TestEntity : NSObject
@property(nonatomic,strong)NSNumber *mId;
@property(nonatomic,strong)NSString *name;
@property(nonatomic,strong)NSNumber *age;
@property(nonatomic,assign)float age2;
@property(nonatomic,strong)TestBEntity *classB;
@property(nonatomic,strong)NSArray<ClassC> *clsC;
+(NSString *)primarilyKey;
@end
