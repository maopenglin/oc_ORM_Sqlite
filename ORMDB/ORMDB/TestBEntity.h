//
//  TestBEntity.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestBEntity : NSObject
@property(nonatomic,strong)NSNumber *cID;
@property(nonatomic,strong)NSString *address;
+(NSString *)foreignKey;
@end
