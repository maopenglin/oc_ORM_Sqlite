//
//  ORM.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORM : NSObject

- (void)test:(Class )cls;
+ (void)createTableFromClass:(Class) cls;
+ (void)saveEntity:(id)entity with:(NSArray *)keys;
+ (NSMutableArray *)parseClass:(Class)cls;
+ (NSString *)createWherStateWith:(NSArray *)key andValues:(NSArray *)value;
+ (id)get:(Class)cls withKeys:(NSArray *)keys andValues:(NSArray *)values;
+ (NSMutableArray *)list:(Class)cls withKeys:(NSArray *)keys andValues:(NSArray *)values;
+ (void)deleteObject:(Class)cls withKeys:(NSArray *)keys andValues:(NSArray *)values;
@end
