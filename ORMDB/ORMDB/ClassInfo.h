//
//  ClassInfo.h
//  ORMDB
//
//  Created by mao PengLin on 2017/6/2.
//  Copyright © 2017年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Student.h"
#import "Teacher.h"

@interface ClassInfo : NSObject
@property(nonatomic,strong)NSNumber *classNumber;
@property(nonatomic,strong)NSString *className;
@property(nonatomic,strong)NSString *classAddress;
@property(nonatomic,strong)NSArray<Student> *student;
@property(nonatomic,strong)Teacher *teacher;

@property(nonatomic,assign)NSInteger roomId;
@property(nonatomic,strong)NSDictionary *dataInfo;
@end
