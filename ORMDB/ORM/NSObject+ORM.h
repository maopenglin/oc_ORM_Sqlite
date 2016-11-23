//
//  NSObject+ORM.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(Extensions)
+ (void)createTable;
- (void)save:(NSArray *)keyes;

+ (id)getObject:(NSArray *)keys withValue:(NSArray *)values;

+ (id)list:(NSArray *)keys withValue:(NSArray *)values;

+ (void)clearTable;

+ (void)clearTableWithKey:(NSArray *)keys withValue:(NSArray *)value;
@end
