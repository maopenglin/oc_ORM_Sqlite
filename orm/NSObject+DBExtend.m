//
//  NSObject+DBExtend.m
//  ocORM
//
//  Created by PengLinmao on 16/6/13.
//  Copyright © 2016年 pengLin. All rights reserved.
//

#import "NSObject+DBExtend.h"
#import "DBUtil.h"
#import "OCHibernate.h"

@implementation NSObject(DataBases)
- (void)save {
    [DBUtil saveEntity:self andWhereStateMent:nil];
}
-(void)save:(NSArray *)keyes
withTransactionStart:(BOOL)transactionStart transactionEnd:(BOOL)transactionEnd{
    [DBUtil saveEntity:self andWhereStateMent:keyes withTransactionStart:transactionStart transactionEnd:transactionEnd];
}
/**
 保存对象
 keyes 对象唯一条件字段
 **/
- (void)save:(NSArray *)keyes {
    [DBUtil saveEntity:self andWhereStateMent:keyes];
}

/**
 单个查询
 key  查询条件字段 数组
 value 条件值   数组
 **/
+ (id)getObject:(NSArray *)key withValue:(NSArray *)value {
    return [DBUtil get:[self class] andKey:key withValue:value];
}

/**
 集合查询
 key  查询条件字段 数组
 value 条件值   数组
 **/
+ (id)list:(NSArray *)key withValue:(NSArray *)value {
    return [DBUtil list:[self class] andKey:key withValue:value];
}
+(id)list:(NSArray *)key withValue:(NSArray *)value limit:(int)limit offset:(int)offset{
    return [DBUtil list:[self class] andKey:key withValue:value limit:limit offset:offset];
}
/**
 删除对象
 **/
- (void)deleteObject {
    [DBUtil deleteObject:self];
}

/**
 清空表数据
 **/
+ (void)clearTable {
    [DBUtil clearTable:[self class]];
}

+ (void)clearDatas:(NSArray *)key withValue:(NSArray *)value {
    [DBUtil clearDatas:[self class] andKey:key withValue:value];
}

- (void)descriptionObject {
    [DBUtil descObject:self];
}
@end
