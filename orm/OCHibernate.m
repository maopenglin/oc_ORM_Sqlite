//
//  OCHibernate.m
//  sqlTest
//
//  Created by PengLinmao on 15/4/15.
//  Copyright (c) 2015年 maopenglin. All rights reserved.
//

#import "OCHibernate.h"
#import <objc/runtime.h>
#import <objc/message.h>



@implementation OCHibernate
+(NSString*)createTableFromEntity:(Class)entity{
    unsigned int propertyCount;
    NSString *sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",entity];
    objc_property_t *properties = class_copyPropertyList(entity,&propertyCount);
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        const char *attrs = property_getAttributes(property);
        NSString* propertyAttributes = @(attrs);
        NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        DBDataType dtype=[self evalDBType:propertyAttributes];
        if ([attributeItems containsObject:@"R"]||dtype==DBDataTypeNOTSupport) {
            continue;
        }
        switch (dtype) {
            case DBDataTypeNumber:
                sql=[NSString stringWithFormat:@"%@ %@ integer ,",sql,@(propertyName)];
                break;
            case DBDataTypeInt:
                sql=[NSString stringWithFormat:@"%@ %@ integer ,",sql,@(propertyName)];
                break;
            case DBDataTypeFloat:
                sql=[NSString stringWithFormat:@"%@ %@ float ,",sql,@(propertyName)];
                break;
            case DBDataTypeDouble:
                sql=[NSString stringWithFormat:@"%@ %@ double ,",sql,@(propertyName)];
                break;
            case DBDataTypeString:
                sql=[NSString stringWithFormat:@"%@ %@ TEXT  DEFAULT NULL ,",sql,@(propertyName)];
                break;
            default:
                break;
        }
        
    }
    if ([sql hasSuffix:@","]) {
        if (sql.length-1>0) {
            sql=[sql substringToIndex:sql.length-1];
        }
    }
    sql=[NSString stringWithFormat:@"%@ %@",sql,@" );"];
    return sql;
}
+(DBDataType)evalDBType:(NSString *)propertyAttributes{
    
    if ([propertyAttributes rangeOfString:@"NSNumber"].location>0&&[propertyAttributes rangeOfString:@"NSNumber"].location<1000) {
        return DBDataTypeNumber;
    }else if ([propertyAttributes hasPrefix:@"Ti,"]||[propertyAttributes hasPrefix:@"TB,"]||[propertyAttributes hasPrefix:@"Tq,"]){
        return  DBDataTypeInt;
    }else  if ([propertyAttributes hasPrefix:@"Tf,"]) {
        return  DBDataTypeFloat;
    }else if ([propertyAttributes hasPrefix:@"Td,"]) {
        return  DBDataTypeDouble;
    }else if([propertyAttributes rangeOfString:@"NSString"].location>0&&[propertyAttributes rangeOfString:@"NSString"].location<1000){
        return  DBDataTypeString;
    }
    
    return DBDataTypeNOTSupport;
}
+(NSString*)whereStatement:(id)entity andKeys:(NSArray*)keys{
    if (!keys||keys.count==0) {
        return @"";
    }
    NSString *whereSql=@"";
    for (int i=0; i<keys.count; i++) {
        NSString *type=[NSString stringWithFormat:@"%@",[[entity valueForKey:keys[i]] class]];
  
        if (i==0) {
            if ([type hasSuffix:@"NSCFNumber"]||[type hasSuffix:@"NSCFBoolean"]||[type compare:@"(null)"]==NSOrderedSame) {
                whereSql=[NSString stringWithFormat:@"WHERE %@ = %i ",keys[i],[[entity valueForKey:keys[i]] intValue]];
            }else{
                whereSql=[NSString stringWithFormat:@"WHERE %@ = '%@' ",keys[i],[entity valueForKey:keys[i]]];
            }
        }else{
            if ([type hasSuffix:@"NSCFNumber"]||[type hasSuffix:@"NSCFBoolean"]||[type compare:@"(null)"]==NSOrderedSame) {
                whereSql=[NSString stringWithFormat:@"%@ AND  %@ = %i  ",whereSql,keys[i],[[entity valueForKey:keys[i]] intValue]];
            }else{
                whereSql=[NSString stringWithFormat:@"%@ AND  %@ = '%@'  ",whereSql,keys[i],[entity valueForKey:keys[i]]];
            }
        }
    }
    whereSql=[NSString stringWithFormat:@"%@ ;",whereSql];
    return whereSql;
}

+(void)save:(id)entity andDataBase:(sqlite3 *)database{
    unsigned int propertyCount;
    NSMutableString *sql=[[NSMutableString alloc] initWithFormat:@"INSERT INTO  %@   (",[entity class]];
    objc_property_t *properties = class_copyPropertyList([entity class],&propertyCount);
    int pc=0;
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        const char *attrs = property_getAttributes(property);
        NSString* propertyAttributes = @(attrs);
        DBDataType dtype=[self evalDBType:propertyAttributes];
        NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        if ([attributeItems containsObject:@"R"]||dtype==DBDataTypeNOTSupport) {
            continue;
        }
        pc=pc+1;
        if (i!=propertyCount-1) {
            [sql appendFormat:@"%@ ,",@(propertyName)];
        }else{
            [sql appendFormat:@"%@ )",@(propertyName)];
        }
    }
    if ([sql hasSuffix:@","]) {
        if (sql.length-1>0) {
            [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
            [sql appendString:@")"];
        }
    }
    [sql appendString:@" VALUES ("];
    for (unsigned int i = 0; i < pc; i++) {
        if (i!=pc-1) {
            [sql appendString:@" ? , "];
        }else{
            [sql appendString:@" ? ) "];
        }
    }
    [sql appendString:@" ;"];
    if (ShowSql) {
        NSLog(@"%@",sql);
    }
    
    
    
    
    sqlite3_stmt *statement;
    int y=1;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        for (unsigned int i = 0; i < propertyCount; i++) {
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            const char *attrs = property_getAttributes(property);
            NSString* propertyAttributes = @(attrs);
            NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
            DBDataType dataType=[self evalDBType:propertyAttributes];
            if ([attributeItems containsObject:@"R"]||dataType==DBDataTypeNOTSupport) {
                continue;
            }
            if (dataType==DBDataTypeInt||dataType==DBDataTypeNumber) {
                NSNumber *objvalue=[entity valueForKey:@(propertyName)];
                if (!objvalue||[objvalue isEqual:[NSNull null]]) {
                    objvalue=@(0);
                }
                
                if ( CFNumberIsFloatType((CFNumberRef)objvalue)) {
                    sqlite3_bind_double(statement, y, [objvalue doubleValue]);
                } else {
                    sqlite3_bind_int(statement, y, [objvalue intValue]);
                }
                
            }else if(dataType==DBDataTypeFloat||dataType==DBDataTypeDouble){
                id objvalue=[entity valueForKey:@(propertyName)];
                sqlite3_bind_text(statement, y, [[NSString stringWithFormat:@"%f",[objvalue doubleValue]] UTF8String],-1,NULL);
            }else {
                NSString *str=[entity valueForKey:@(propertyName)];
                if (!str||[str isEqual:[NSNull null]]||[str compare:@"(null)"]==NSOrderedSame||[str compare:@"<null>"]==NSOrderedSame) {
                    str=@"";
                }
                sqlite3_bind_text(statement, y, [str UTF8String], -1, NULL);
            }
            
            y=y+1;
        }
        
    }
    
    int result=sqlite3_step(statement);
    if (result==SQLITE_DONE) {
    }else{
        NSLog(@"数据库保存错误:%i",result);
    }
    sqlite3_finalize(statement);
}
+(NSString  *)createWhereStatement:(Class)entity key:(NSArray *)key andValues:(NSArray *)value andType:(DBSqlType) sqlType{
    NSString *sql=[NSString stringWithFormat:@"SELECT * FROM  %@ ",entity];
    if (sqlType==DBSqlTypeDelete) {
        sql=[NSString stringWithFormat:@"DELETE FROM  %@ ",entity];
    }
    if (key) {
        if (key.count!=value.count) {
            NSLog(@"get:key!=value");
            return nil;
        }
        NSString *whereSql=@"";
        for (int i=0; i<key.count; i++) {
            NSString *type=[NSString stringWithFormat:@"%@",[value[i] class]];
            
            if (i==0) {
                if ([type hasSuffix:@"NSCFNumber"]||[type hasSuffix:@"NSCFBoolean"]) {
                    if ([type hasSuffix:@"NSCFNumber"]) {
                        NSNumber *number=value[i];
                        if(CFNumberIsFloatType((CFNumberRef)number))
                        {
                            whereSql=[NSString stringWithFormat:@"WHERE %@ = %@ ",key[i],value[i]];
                        }else{
                            whereSql=[NSString stringWithFormat:@"WHERE %@ = %i ",key[i],[value[i] intValue]];
                        }
                    }else{
                        whereSql=[NSString stringWithFormat:@"WHERE %@ = %i ",key[i],[value[i] intValue]];
                    }
                }else{
                    whereSql=[NSString stringWithFormat:@"WHERE %@ = '%@' ",key[i],value[i]];
                }
            }else{
                if ([type hasSuffix:@"NSCFNumber"]||[type hasSuffix:@"NSCFBoolean"]) {
                    if ([type hasSuffix:@"NSCFNumber"]) {
                        NSNumber *number=value[i];
                        if(CFNumberIsFloatType((CFNumberRef)number)){
                            whereSql=[NSString stringWithFormat:@"%@ AND  %@ = %@  ",whereSql,key[i],value[i]];
                        }else{
                            whereSql=[NSString stringWithFormat:@"%@ AND  %@ = %i  ",whereSql,key[i],[value[i] intValue]];
                        }
                        
                    }else{
                        whereSql=[NSString stringWithFormat:@"%@ AND  %@ = %i  ",whereSql,key[i],[value[i] intValue]];
                    }
                }else{
                    whereSql=[NSString stringWithFormat:@"%@ AND  %@ = '%@'  ",whereSql,key[i],value[i]];
                }
                
            }
        }
        sql=[NSString stringWithFormat:@"%@ %@",sql,whereSql];
        
    }
    sql=[NSString stringWithFormat:@"%@ ;",sql];
    return sql;
}



@end
