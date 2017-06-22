//
//  NSObject+ORM.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(Extensions)
/**
 创建表
 
 **/
+ (void)createTable;
/**
 保存数据
 @param keyes 数据保存参数条件
 **/
- (void)save:(NSArray *)keyes;

/**
 查询单个对象
 @param keys 参数条件
 @param values 值
 **/
+ (id)getObject:(NSArray *)keys withValue:(NSArray *)values;

/**
 查询列表
 **/
+ (id)list:(NSArray *)keys withValue:(NSArray *)values;

/**
 清空表数据
 **/
+ (void)clearTable;

+ (void)clearTable:(NSArray *)keys withValue:(NSArray *)value;

/**
 保存列表集合数据
 @param keys 参数条件
 @param block 回调参数
 **/
+(void)saveListData:(NSArray *)keys andBlock:(void (^) (NSMutableArray *datas))block;
@end

@interface NSArray(ORM)
-(void)saveListDataWithKeys:(NSArray *)keys;
@end
