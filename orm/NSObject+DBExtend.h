//
//  NSObject+DBExtend.h
//  ocORM
//
//  Created by PengLinmao on 16/6/13.
//  Copyright © 2016年 pengLin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(DataBases)

- (void)save;

/**
 保存对象
 keyes 对象唯一条件字段
 **/
- (void)save:(NSArray *)keyes;
/**
 事务保存数据
 **/
-(void)save:(NSArray *)keyes
withTransactionStart:(BOOL)transactionStart transactionEnd:(BOOL)transactionEnd;
/**
 单个查询
 key  查询条件字段 数组
 value 条件值   数组
 **/
+ (id)getObject:(NSArray *)key withValue:(NSArray *)value;

/**
 集合查询
 key  查询条件字段 数组
 value 条件值   数组
 **/
+ (id)list:(NSArray *)key withValue:(NSArray *)value;

+(id)list:(NSArray *)key withValue:(NSArray *)value limit:(int)limit offset:(int)offset;
/**
 删除对象
 **/
- (void)deleteObject;

/**
 清空表数据
 **/
+ (void)clearTable;

+ (void)clearDatas:(NSArray *)key withValue:(NSArray *)value;

- (void)descriptionObject;

@end
