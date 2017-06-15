//
//  Test.h
//  ORMDB
//
//  Created by mao PengLin on 2017/6/8.
//  Copyright © 2017年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Test2.h"
@interface Test : NSObject
@property(nonatomic,assign)int one;
@property(nonatomic,strong) Test2 *test;
@end
