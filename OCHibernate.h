//
//  OCHibernate.h
//  sqlTest
//
//  Created by PengLinmao on 15/4/15.
//  Copyright (c) 2015年 maopenglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBUtil.h"
#import "sqlite3.h"
@interface OCHibernate : NSObject
+(NSString*)createTableFromEntity:(Class)entity;
+(void)save:(id)entity andDataBase:(sqlite3 *)database;
+(NSString*)whereStatement:(id)entity andKeys:(NSArray*)keys;

+(NSString  *)createWhereStatement:(Class)entity key:(NSArray *)key andValues:(NSArray *)value andType:(DBSqlType) sqlType;

+(DBDataType)evalDBType:(NSString *)propertyAttributes;
@end
