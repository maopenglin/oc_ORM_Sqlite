//
//  Student.h
//  ORMDB
//
//  Created by mao PengLin on 2017/6/2.
//  Copyright © 2017年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Student
@end
@interface Student : NSObject
@property(nonatomic,strong)NSString *name;
@property(nonatomic,assign)int age;
@property(nonatomic,strong)NSNumber *classNumber;
@property (nonatomic,assign)int sid;
@end
