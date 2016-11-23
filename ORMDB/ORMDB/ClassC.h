//
//  ClassC.h
//  ORM
//
//  Created by PengLinmao on 16/11/23.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol ClassC
@end
@interface ClassC : NSObject
@property(nonatomic,strong)NSString *pA;
@property(nonatomic,strong)NSString *pB;
@property(nonatomic,strong)NSNumber *pID;

+(NSString *)foreignKey;
@end
