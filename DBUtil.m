//
//  DBUtil.m
//  sqlTest
//
//  Created by maopenglin on 14-5-14.
//  Copyright (c) 2014年 maopenglin. All rights reserved.
//

#import "DBUtil.h"
#import "OCHibernate.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation DBUtil
/**
 创建表
 **/
+(void)createTable:(Class)entity{
    NSString *sql=[OCHibernate createTableFromEntity:entity];
    [self execSql:sql];
}
sqlite3 *transactionDatabases;
+(void)saveEntity:(id)entity andWhereStateMent:(NSArray *)keyes withTransactionStart:(BOOL)transactionStart transactionEnd:(BOOL)transactionEnd{
    
    if (transactionStart) {
        if (sqlite3_open([DBPath UTF8String], &transactionDatabases)== SQLITE_OK) {
            char *zErrorMsg =nil;
            if (ShowSql) {
                NSLog(@"%@",@"begin transaction ;");
            }
            sqlite3_exec( transactionDatabases, "begin transaction ;", 0, 0, &zErrorMsg );
        }
    }
    
    
    if (!keyes) {
        [OCHibernate save:entity andDataBase:transactionDatabases];
        
    }else{
        NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ %@",
                       [entity class],
                       [OCHibernate whereStatement:entity andKeys:keyes]];
        if (ShowSql) {
            NSLog(@"%@",sql);
        }
        sqlite3_stmt *statement;
        sqlite3_prepare_v2(transactionDatabases, [sql UTF8String], -1, &statement, NULL);
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        [OCHibernate save:entity andDataBase:transactionDatabases ];
        
    }
    
    if (transactionEnd) {
        char *zErrorMsg =nil;
        if (ShowSql) {
            NSLog(@"%@",@"commit transaction ;");
        }
        sqlite3_exec( transactionDatabases, "commit transaction ;", 0, 0, &zErrorMsg );
        sqlite3_close(transactionDatabases);
    }
    
}
/**
 保存对象
 **/
+(void)saveEntity:(id)entity andWhereStateMent:(NSArray*)keyes{
    sqlite3 *databases;
    if (sqlite3_open([DBPath UTF8String], &databases)== SQLITE_OK) {
        
        if (!keyes) {
            [OCHibernate save:entity andDataBase:databases ];
            
        }else{
            NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ %@",
                           [entity class],
                           [OCHibernate whereStatement:entity andKeys:keyes]];
            [self execSql:sql];
            [OCHibernate save:entity andDataBase:databases];
            
        }
        sqlite3_close(databases);
    }
}
/**
 查询单个
 **/
+(id)get:(Class)entity andKey:(NSArray*)key withValue:(NSArray*)value{
    
    id object=nil;
    NSString *sql=[OCHibernate createWhereStatement:entity key:key andValues:value andType:DBSqlTypeSelect];
    sqlite3 *database;
    sqlite3_stmt *statement=nil;
    if (sqlite3_open([DBPath UTF8String], &database)== SQLITE_OK&&(sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, nil)==SQLITE_OK) ) {
        
        if (ShowSql) {
            NSLog(@"%@",sql);
        }
        unsigned int propertyCount;
        objc_property_t *properties=class_copyPropertyList([entity class],&propertyCount);
        if (sqlite3_step(statement)==SQLITE_ROW)
        {
            object=[entity new];
            int  realPropertyCount=0;
            for (unsigned int i = 0; i < propertyCount; i++) {
                
                objc_property_t property = properties[i];
                const char *propertyName = property_getName(property);
                const char *attrs = property_getAttributes(property);
                NSString* propertyAttributes = @(attrs);
                 DBDataType dtype=[OCHibernate evalDBType:propertyAttributes];
                NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
                 if ([attributeItems containsObject:@"R"]||dtype==DBDataTypeNOTSupport) {
                    continue;
                }
                const char *c=(char *)sqlite3_column_text(statement,realPropertyCount) ;
                if (!c) {
                    c="";
                }
                NSString *value=[[NSString alloc] initWithCString:c encoding:NSUTF8StringEncoding];
                [self setPropertyValueForObject:propertyAttributes propertyName:@(propertyName) andObject:object andValue:value];
                realPropertyCount=realPropertyCount+1;
            }
        }
        
        sqlite3_finalize(statement);
        sqlite3_close(database);
        return object;
        
    }
    return object;
}
/**
 查询集合
 **/
+(id)list:(Class)entity andKey:(NSArray*)key withValue:(NSArray*)value{
    return  [self list:entity andKey:key withValue:value limit:-1 offset:-1];
}
+(id)list:(Class)entity andKey:(NSArray *)key withValue:(NSArray *)value limit:(int)limit offset:(int)offset{
    NSMutableArray *list=[[NSMutableArray alloc] init];
    NSString *sql=[OCHibernate createWhereStatement:entity key:key andValues:value andType:DBSqlTypeSelect];
    if (limit!=-1&&offset!=-1) {
        sql=[sql stringByReplacingOccurrencesOfString:@";" withString:[ NSString stringWithFormat:@" limit %i Offset %i ;",limit,offset]];
    }
    sqlite3 *database;
    sqlite3_stmt *statement=nil;
    if (sqlite3_open([DBPath UTF8String], &database)== SQLITE_OK&&(sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, nil)==SQLITE_OK) ) {
        
        if (ShowSql) {
            NSLog(@"%@",sql);
        }
        
        unsigned int propertyCount;
        objc_property_t *properties=class_copyPropertyList([entity class],&propertyCount);
        while (sqlite3_step(statement)==SQLITE_ROW) {
            id object=[entity new];
            int realPropertyCount=0;
            for (unsigned int i = 0; i < propertyCount; i++) {
                objc_property_t property = properties[i];
                const char *propertyName = property_getName(property);
                const char *attrs = property_getAttributes(property);
                NSString* propertyAttributes = @(attrs);
                DBDataType dtype=[OCHibernate evalDBType:propertyAttributes];
                NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
                if ([attributeItems containsObject:@"R"]||dtype==DBDataTypeNOTSupport) {
                    continue;
                }
                const char *c=(char *)sqlite3_column_text(statement,realPropertyCount);
                if (!c) {
                    c="";
                }
                NSString *value=[[NSString alloc] initWithCString:c encoding:NSUTF8StringEncoding];
                [self setPropertyValueForObject:propertyAttributes propertyName:@(propertyName) andObject:object andValue:value];
                realPropertyCount=realPropertyCount+1;
            }
            [list addObject:object];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return list;
}
+(void)setPropertyValueForObject:(NSString *)propertyAttributes propertyName:(NSString *)propertyName andObject:(id)object andValue:(NSString *)value{
    DBDataType dtype=[OCHibernate evalDBType:propertyAttributes];
    if (dtype==DBDataTypeNumber) {
        NSRange range=[value rangeOfString:@"."];
        NSNumber *number=@0;
        if (range.location>0&&range.location<100) {
            number=@([value doubleValue]);
        }else{
            number=@([value intValue]);
        }
        [object setValue:number forKey:propertyName];
    }else if (dtype==DBDataTypeInt) {
        if ([propertyAttributes hasPrefix:@"Ti,"]||[propertyAttributes hasPrefix:@"Tq,"]) {
            [object setValue:@([value intValue]) forKey:propertyName];
        }else{
            if ([value intValue]) {
                [object setValue:@YES forKey:propertyName];
            }else{
                [object setValue:@NO forKey:propertyName];
            }
        }
        
    }else if (dtype==DBDataTypeFloat) {
        [object setValue:@([value floatValue]) forKey:propertyName];
    }else if (dtype==DBDataTypeDouble) {
        [object setValue:@([value doubleValue]) forKey:propertyName];
    }else if (dtype==DBDataTypeString){
        if (!value||[value isEqual:[NSNull null]]||[value compare:@"(null)"]==NSOrderedSame||[value compare:@"<null>"]==NSOrderedSame) {
            value=@"";
        }
        [object setValue:value forKey:propertyName];
    }
    
}
+(void)clearDatas:(Class)entity andKey:(NSArray *)key withValue:(NSArray *)value{
    
    NSString *sql=[OCHibernate createWhereStatement:entity key:key andValues:value andType:DBSqlTypeDelete];
    
    [DBUtil execSql:sql];
}

+(void)setValueForObject:(id)objct withKey:(NSString*)key andValue:(NSObject*)value{
    NSString* ucfirstName = [key stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                         withString:[[key substringToIndex:1] uppercaseString]];
    NSString* selectorName = [NSString stringWithFormat:@"set%@:", ucfirstName];
    SEL customPropertySetter = NSSelectorFromString(selectorName);
    if ([objct respondsToSelector: customPropertySetter]) {
        ((void (*) (id, SEL, id))objc_msgSend)(objct,customPropertySetter, value);
    }
    
}
+(void)deleteObject:(id)object{
    if(object){
        unsigned int propertyCount;
        NSString *statement=@"";
        statement=[statement stringByAppendingString:[NSString stringWithFormat:@"DELETE FROM %@  WHERE",[object class]]];
        int y=0;
        objc_property_t *properties=class_copyPropertyList([object class],&propertyCount);
        for (unsigned int i = 0; i < propertyCount; i++) {
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            const char *attrs = property_getAttributes(property);
            NSString* propertyAttributes = @(attrs);
            NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
            if ([attributeItems containsObject:@"R"]) {
                continue;
            }
            if (([propertyAttributes rangeOfString:@"NSNumber"].location>0&&
                 [propertyAttributes rangeOfString:@"NSNumber"].location<1000)||
                [propertyAttributes hasPrefix:@"Ti,"]||
                [propertyAttributes hasPrefix:@"TB,"]||
                [propertyAttributes hasPrefix:@"Tf,"]||
                [propertyAttributes hasPrefix:@"Td,"]) {
                
                NSNumber * number=[object valueForKey:@(propertyName)];
                if(!number||[number isEqual:[NSNull null]])
                {
                    number=@(0);
                }
                if (number) {
                    if(y==0)
                    {
                        if ( CFNumberIsFloatType((CFNumberRef)number)) {
                            statement=[NSString stringWithFormat:@"%@ %@=%@",statement,@(propertyName),number];
                        }else{
                            statement=[NSString stringWithFormat:@"%@ %@=%i",statement,@(propertyName),[number intValue]];
                        }
                    }else{
                        if ( CFNumberIsFloatType((CFNumberRef)number)) {
                            statement=[NSString stringWithFormat:@" %@ AND %@=%@",statement,@(propertyName),number];
                        }else{
                            statement=[NSString stringWithFormat:@" %@ AND %@=%i",statement,@(propertyName),[number intValue]];
                        }
                    }
                    y=y+1;
                }
                
            }else{
                NSString *str=(NSString*)[object valueForKey:@(propertyName)];
                if (str) {
                    if(y==0)
                    {
                        statement=[NSString stringWithFormat:@"%@ %@='%@'",statement,@(propertyName),str];
                    }else{
                        statement=[NSString stringWithFormat:@" %@ AND %@='%@'",statement,@(propertyName),str];
                    }
                    y=y+1;
                }
            }
        }
        
        [DBUtil execSql:statement];
    }
    
}
+(void)descObject:(id)object{
    if (object) {
        unsigned int propertyCount;
        NSString *log=@"\n{\n";
        
        objc_property_t *properties=class_copyPropertyList([object class],&propertyCount);
        for (unsigned int i = 0; i < propertyCount; i++) {
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            const char *attrs = property_getAttributes(property);
            NSString* propertyAttributes = @(attrs);
            NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
            if ([attributeItems containsObject:@"R"]) {
                continue;
            }
            if (([propertyAttributes rangeOfString:@"NSNumber"].location>0&&
                [propertyAttributes rangeOfString:@"NSNumber"].location<1000)||[propertyAttributes hasPrefix:@"Ti,"]||[propertyAttributes hasPrefix:@"TB,"]||[propertyAttributes hasPrefix:@"Tf,"]||[propertyAttributes hasPrefix:@"Td,"]) {
                
                id number=[object valueForKey:@(propertyName)];
                if (!number||[number isEqual:[NSNull null]]) {
                    number=@(0);
                }
                if(i==0)
                {
                    if ( CFNumberIsFloatType((CFNumberRef)number)) {
                        log=[NSString stringWithFormat:@"%@ %@==>%f",log,@(propertyName),[number doubleValue]];
                    }else{
                        log=[NSString stringWithFormat:@"%@ %@==>%i",log,@(propertyName),[number intValue]];
                    }
                }else{
                    if ( CFNumberIsFloatType((CFNumberRef)number)) {
                        log=[NSString stringWithFormat:@" %@ ,\n %@==>%f",log,@(propertyName),[number doubleValue] ];
                    }else{
                        log=[NSString stringWithFormat:@" %@ ,\n %@==>%i",log,@(propertyName),[number intValue]];
                    }
                }
                
                
                
            }else{
                NSString *str=(NSString*)[object valueForKey:@(propertyName)];
                if (str) {
                    if(i==0)
                    {
                        log=[NSString stringWithFormat:@"%@ %@==>'%@'",log,@(propertyName),str];
                    }else{
                        log=[NSString stringWithFormat:@" %@ ,\n %@==>'%@'",log,@(propertyName),str];
                    }
                    
                }
            }
        }
        NSLog(@"\n%@,%@\n}",object,log);
    }else{
        NSLog(@"nil object");
    }
}
//插入或者更新
+(void)insertOrUpdate:(NSString*)tableName andAllFieldsValue:(NSArray*)values andWhereKeyValue:(NSArray*)wherekey{
    
    if(wherekey){
        NSString *sql=[NSString stringWithFormat:@"DELETE FROM  %@  WHERE ",tableName];
        for(int i=0;i<[wherekey count];i++){
            
            NSDictionary *dic=[wherekey objectAtIndex:i];
            NSString *key= [[dic allKeys] objectAtIndex:0];
            NSString *value=[dic valueForKey:key];
            if(i< [wherekey count]-1){
                sql=[NSString stringWithFormat:@"%@ %@='%@' AND ",sql,key,value];
            }else{
                sql=[NSString stringWithFormat:@"%@ %@='%@'",sql,key,value];
                
            }
        }
        sql=[NSString stringWithFormat:@"%@ %@",sql,@";"];
        
        [DBUtil execSql:sql];
    }else{
        [DBUtil insert:tableName andFieldsCount:values];
    }
    
}

//insert 语句
+(void)insert:(NSString*)tableName andFieldsCount:(NSArray*)values{
    NSString *sql=[NSString stringWithFormat:@"INSERT INTO %@ VALUES (",tableName];
    for(int i=0;i<[values count];i++){
        if (i<[values count]-1) {
            sql=[NSString stringWithFormat:@"%@ '%@',",sql,[values objectAtIndex:i]];
        }else{
            sql=[NSString stringWithFormat:@"%@ '%@'",sql,[values objectAtIndex:i]];
        }
    }
    sql=[NSString stringWithFormat:@"%@ %@",sql,@");"];
    
    [DBUtil execSql:sql];
    
}
+(void)execSql:(NSString*)sql{
    
    
    if(ShowSql){
        NSLog(@"%@",sql);
    }
    sqlite3 *database;
    
    
    if (sqlite3_open([DBPath UTF8String], &database)== SQLITE_OK) {
        sqlite3_stmt *statement;
        sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        int result=sqlite3_step(statement);
        if (result == SQLITE_DONE) {
            
        }else{
            
            
            NSLog(@"数据库 访问错误...error code:%i",result);
            
            
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }else{
        NSLog(@"db open error");
    }
    
    
    
    
}


//更新sql
+(void)updates:(NSString*)tableName andFiledsAndValue:(NSArray*)fields andWhereKeyValues:(NSArray*)values{
    
    NSString *sql=[NSString stringWithFormat:@"UPDATE %@ SET ",tableName];
    for(int i=0;i<[fields count];i++){
        
        NSDictionary *dic=[fields objectAtIndex:i];
        NSString *key= [[dic allKeys] objectAtIndex:0];
        NSString *value=[dic valueForKey:key];
        if(i< [fields count]-1){
            sql=[NSString stringWithFormat:@"%@ %@ = '%@' , ",sql,key,value];
        }else{
            sql=[NSString stringWithFormat:@"%@ %@ = '%@'",sql,key,value];
            
        }
    }
    sql=[NSString stringWithFormat:@"%@ WHERE ",sql];
    for(int i=0;i<[values count];i++){
        
        NSDictionary *dic=[values objectAtIndex:i];
        NSString *key= [[dic allKeys] objectAtIndex:0];
        NSString *value=[dic valueForKey:key];
        if(i< [values count]-1){
            sql=[NSString stringWithFormat:@"%@ (%@='%@') AND ",sql,key,value];
        }else{
            sql=[NSString stringWithFormat:@"%@ (%@='%@') ",sql,key,value];
            
        }
    }
    
    [DBUtil execSql:sql];
}
// update 语句
/*
 updatekey   要更新的 key
 updateValue 要更新的值
 wherekey 条件key
 wherevalue 条件值
 */
+(void)update:(NSString*)tableName andUpdateKey:(NSString*)updatekey andUpdateValue:(NSString*)updateValue  andWhereKeyValue:(NSArray*)wherekey{
    NSString *sql=[NSString stringWithFormat:@"UPDATE %@ set %@='%@' WHERE ",tableName,updatekey,updateValue];
    for(int i=0;i<[wherekey count];i++){
        
        NSDictionary *dic=[wherekey objectAtIndex:i];
        NSString *key= [[dic allKeys] objectAtIndex:0];
        NSString *value=[dic valueForKey:key];
        if(i< [wherekey count]-1){
            sql=[NSString stringWithFormat:@"%@ %@='%@' AND ",sql,key,value];
        }else{
            sql=[NSString stringWithFormat:@"%@ %@='%@'",sql,key,value];
            
        }
    }
    sql=[NSString stringWithFormat:@"%@ %@",sql,@";"];
    [DBUtil execSql:sql];
    
}
//删除
+(void)deleteTable:(NSString*)tableName  andWhereKeyValue:(NSArray*)wherekey{
    NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ WHERE ",tableName];
    for(int i=0;i<[wherekey count];i++){
        
        NSDictionary *dic=[wherekey objectAtIndex:i];
        NSString *key= [[dic allKeys] objectAtIndex:0];
        NSString *value=[dic valueForKey:key];
        if(i< [wherekey count]-1){
            sql=[NSString stringWithFormat:@"%@ %@='%@' AND ",sql,key,value];
        }else{
            sql=[NSString stringWithFormat:@"%@ %@='%@'",sql,key,value];
            
        }
    }
    sql=[NSString stringWithFormat:@"%@ %@",sql,@";"];
    
    
    [DBUtil execSql:sql];
    
}
//清空表数据
+(void)clearTable:(Class)tableName{
    NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ ;",tableName];
    [DBUtil execSql:sql];
}

//查询
+(NSString*)createSelectSql:(NSString*)tableName{
    NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@ ;",tableName];
    if (ShowSql) {
        NSLog(@":%@",sql);
    }
    return sql;
}
//查询
+(NSString*)createSelectSql:(NSString*)tableName andWhereKeyValue:(NSArray*)wherekey{
    NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@  WHERE",tableName];
    
    for(int i=0;i<[wherekey count];i++){
        
        NSDictionary *dic=[wherekey objectAtIndex:i];
        NSString *key= [[dic allKeys] objectAtIndex:0];
        NSString *value=[dic valueForKey:key];
        if(i< [wherekey count]-1){
            sql=[NSString stringWithFormat:@"%@ %@='%@' AND ",sql,key,value];
        }else{
            sql=[NSString stringWithFormat:@"%@ %@='%@'",sql,key,value];
            
        }
    }
    sql=[NSString stringWithFormat:@"%@ %@",sql,@";"];
    if (ShowSql) {
        NSLog(@":%@",sql);
    }
    return sql;
}
@end
