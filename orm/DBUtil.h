//
//  DBUtil.h
//  sqlTest
//
//  Created by maopenglin on 14-5-14.
//  Copyright (c) 2014年 maopenglin. All rights reserved.
//

#import <Foundation/Foundation.h>


#define sqlText(name,size)  [NSString stringWithFormat:@"%@  TEXT(%i)   DEFAULT NULL",name,size]
#define sqlInteger(name) [NSString stringWithFormat:@"%@ integer ",name] 
#define ShowSql true
#define DBPath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"/pro.db"]

#define sqlDic(key,value) [NSDictionary dictionaryWithObject:value forKey:key]


typedef NS_ENUM(NSInteger, DBDataType) {
    DBDataTypeNumber,
    DBDataTypeInt,
    DBDataTypeFloat,
    DBDataTypeDouble,
    DBDataTypeString,
    DBDataTypeNOTSupport,
};
typedef NS_ENUM(NSInteger, DBSqlType) {
    DBSqlTypeSelect,
    DBSqlTypeDelete,
};
@interface DBUtil : NSObject

/**
  创建表
 **/
+(void)createTable:(Class)entity;

/**
  保存实体对象
  keyes 唯一条件key
 **/
+(void)saveEntity:(id)entity andWhereStateMent:(NSArray*)keyes;

+(void)saveEntity:(id)entity andWhereStateMent:(NSArray *)keyes
    withTransactionStart:(BOOL)transactionStart transactionEnd:(BOOL)transactionEnd;

/**
  查询单个对象 
  key 查询条件
  value 条件值  条件和值 一一对应
 **/
+(id)get:(Class)entity andKey:(NSArray*)key withValue:(NSArray*)value;

/**
  集合查询
 key 查询条件
 value 条件值  条件和值 一一对应
 **/
+(id)list:(Class)entity andKey:(NSArray*)key withValue:(NSArray*)value;

+(id)list:(Class)entity andKey:(NSArray *)key withValue:(NSArray *)value limit:(int)limit offset:(int)offset;
/**
  删除一个对象
  对象里面 所有 值不为空的为条件
 **/
+(void)deleteObject:(id)object;
/**
   清空表数据
 */
+(void)clearTable:(Class)tableName;
/**
  根据条件清空表数据
 */
+(void)clearDatas:(Class)entity andKey:(NSArray *)key withValue:(NSArray *)value;
/**
  执行sql 不执行 查询类型的sql
 **/
+(void)execSql:(NSString*)sql;

+(void)updates:(NSString*)tableName andFiledsAndValue:(NSArray*)fields andWhereKeyValues:(NSArray*)values;

+(void)update:(NSString*)tableName andUpdateKey:(NSString*)updatekey andUpdateValue:(NSString*)updateValue  andWhereKeyValue:(NSArray*)wherekey;

+(void)deleteTable:(NSString*)tableName  andWhereKeyValue:(NSArray*)wherekey;
+(void)descObject:(id)object;


@end
