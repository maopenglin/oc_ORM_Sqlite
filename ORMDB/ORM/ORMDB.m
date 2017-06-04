//
//  ORMDB.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import "ORMDB.h"
#import "ORM.h"
#import <sqlite3.h>

@implementation ORMDB
sqlite3 *database;
+(void)beginTransaction{
    if (sqlite3_open([DBPath UTF8String], &database)== SQLITE_OK) {
        char *zErrorMsg =nil;
        if(showsql){
            NSLog(@"begin transaction ;");
        }
        sqlite3_exec( database, "begin transaction ;", 0, 0, &zErrorMsg );
    }
}
+(void)commitTransaction{
    char *zErrorMsg =nil;
    if (showsql) {
        NSLog(@"%@",@"commit transaction ;");
    }
    sqlite3_exec(database, "commit transaction ;", 0, 0, &zErrorMsg );
    sqlite3_close(database);

}

+(void)execsql:(NSString *)sql{
    if(showsql){
        NSLog(@"%@",sql);
    }
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    int result=sqlite3_step(statement);
    if (result == SQLITE_DONE) {
        
    }else{
        NSLog(@"数据库 访问错误...error code:%i %@",result,sql);
    }
    sqlite3_finalize(statement);
}
+ (NSMutableArray *)queryDB:(Class)cls andSql:(NSString *)sql{
    sqlite3 *queryDB;
     sqlite3_stmt *statement=nil;
    NSMutableArray *arr=[[NSMutableArray alloc] init];
    ORMDBClassInfo *obj= [ORMDBClassInfo metaWithClass:cls];
    if (sqlite3_open([DBPath UTF8String], &queryDB)== SQLITE_OK&&(sqlite3_prepare_v2(queryDB, [sql UTF8String], -1, &statement, nil)==SQLITE_OK) ) {
        
        if(showsql){
            NSLog(@"%@",sql);
        }
        while (sqlite3_step(statement)==SQLITE_ROW){
            id object=[cls new];
            int i=0;
            for (NSString *key in obj.propertyInfos) {
                ORMDBClassPropertyInfo *info=obj.propertyInfos[key];
                if (info.type!=ORMDBDataTypeClass&&
                    info.type!=ORMDBDataTypeArray&&
                    info.type!=ORMDBDataTypeMutableArray&&
                    info.type!=ORMDBDataTypeUnknown){
                    const char *c=(char *)sqlite3_column_text(statement,i) ;
                    if (!c) {
                        c="";
                    }
                    NSString *value=[[NSString alloc] initWithCString:c encoding:NSUTF8StringEncoding];
                    NSString* ucfirstName = [info.name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                               withString:[[info.name substringToIndex:1] uppercaseString]];
                    NSString* selectorName = [NSString stringWithFormat:@"set%@:", ucfirstName];
                    SEL setterMethod = NSSelectorFromString(selectorName);
                   
                    switch (info.type) {
                        case ORMDBDataTypeString:
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)object,setterMethod, value);
                            break;
                        case ORMDBDataTypeInt:
                            ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)object,setterMethod, [value intValue]);
                            break;
                        case ORMDBDataTypeBool:
                            ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)object,setterMethod, [value boolValue]);
                            break;
                        case ORMDBDataTypeFloat:
                            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)object,setterMethod, [value floatValue]);
                            break;
                        case ORMDBDataTypeDouble:
                            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)object,setterMethod, [value doubleValue]);
                            break;
                        case ORMDBDataTypeNumber:
                            
                            ((void (*)(id, SEL, NSNumber *))(void *) objc_msgSend)((id)object,
                                                                           setterMethod,
                                                                            (NSNumber *)ORMDBNumberCreateFromID(value));
                            break;
                        case ORMDBDataTypeDictionary:
                        case ORMDBDataTypeMutableDictionary:{
                            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                            NSDictionary *json = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                            if (info.type==ORMDBDataTypeMutableDictionary) {
                                ((void (*)(id, SEL, NSMutableDictionary *))(void *) objc_msgSend)((id)object,
                                                                               setterMethod,
                                                                               json.mutableCopy);
                            }else{
                                ((void (*)(id, SEL, NSDictionary *))(void *) objc_msgSend)((id)object,
                                                                               setterMethod,
                                                                               json);
                            }
                        }
                            break;
                        default:
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)object,setterMethod, value);
                            break;
                    }
                    
                    
                }else{
                    
                     SEL foreignSelector=NSSelectorFromString(@"foreignKey");
                    Class fcls= info.cls;
                    if (info.protocol) {
                        fcls=NSClassFromString(info.protocol);
                    }
                    NSMethodSignature  *foreignSignature = [fcls methodSignatureForSelector:foreignSelector];
                    if(foreignSignature){
                        
                        id foreignObjectValue=((id (*)(id, SEL))(void *) objc_msgSend)((id)[fcls class], foreignSelector);
                        SEL primarySelector=NSSelectorFromString(@"primarilyKey");
                        id primaryKey=((id (*)(id, SEL))(void *) objc_msgSend)((id)[object class], primarySelector);
                        SEL sel=NSSelectorFromString(primaryKey);
                        id primaryKeyValue=((id (*)(id, SEL))(void *) objc_msgSend)((id)object, sel);
                        
                        
                        
                        NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@ %@",info.protocol?info.protocol:info.cls,createWhereStatement(@[foreignObjectValue], @[primaryKeyValue])];
                        
                        NSMutableArray *a=[ORMDB queryDB:info.protocol?NSClassFromString(info.protocol):info.cls andSql:sql];
                        id obj=a;
                        if (info.type==ORMDBDataTypeUnknown&&info.cls) {
                            if (a.count>0) {
                                obj=a[0];
                            }
                        }
                        NSString* ucfirstName = [info.name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                   withString:[[info.name substringToIndex:1] uppercaseString]];
                        NSString* selectorName = [NSString stringWithFormat:@"set%@:", ucfirstName];
                        SEL customPropertySetter = NSSelectorFromString(selectorName);
                        
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)object,customPropertySetter,obj);
                    }else{
                        NSLog(@"==== %@ +(NSString *)foreignKey not found",fcls);
                    }
                }
                i++;
            }
            [arr addObject:object];
        }
        sqlite3_finalize(statement);
        sqlite3_close(queryDB);
    }
   
    return arr;
}
+(void)saveObject:(id)entity withSql:(NSString *)sql{
   
    if (showsql) {
        NSLog(@"%@",sql);
    }
    ORMDBClassInfo *obj= [ORMDBClassInfo metaWithClass:[entity class]];
    int y=1;
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        for (NSString *key in obj.propertyInfos) {
            ORMDBClassPropertyInfo *info=obj.propertyInfos[key];
            if (info.type!=ORMDBDataTypeClass&&
                info.type!=ORMDBDataTypeArray&&
                info.type!=ORMDBDataTypeMutableArray&&
                info.type!=ORMDBDataTypeUnknown){
                
                id objvalue=[entity valueForKey:info.name];
                switch (info.type) {
                    case ORMDBDataTypeInt:
                    case ORMDBDataTypeNumber:
                    case ORMDBDataTypeBool:{
                        if (!objvalue||[objvalue isEqual:[NSNull null]]) {
                            objvalue=@(0);
                        }
                        
                        if ( CFNumberIsFloatType((CFNumberRef)objvalue)) {
                            sqlite3_bind_double(statement, y, [objvalue doubleValue]);
                        } else {
                            sqlite3_bind_int(statement, y, [objvalue intValue]);
                        }
                    }
                        break;
                    case ORMDBDataTypeFloat:
                    case ORMDBDataTypeDouble:{
                        if (!objvalue) {
                            objvalue=@(0);
                        }
                        sqlite3_bind_text(statement, y, [[NSString stringWithFormat:@"%f",[objvalue doubleValue]] UTF8String],-1,NULL);
                    }
                        break;
                    case ORMDBDataTypeDictionary:
                    case ORMDBDataTypeMutableDictionary:{
                        if (!objvalue) {
                            objvalue=@{};
                        }
                        NSData *jsonData= [NSJSONSerialization dataWithJSONObject:objvalue options:0 error:NULL];
                        NSString *str= [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        
                        sqlite3_bind_text(statement, y, [str UTF8String], -1, NULL);
                    }
                        break;
                    default:{
                        if (!objvalue||[objvalue isEqual:[NSNull null]]||[objvalue compare:@"(null)"]==NSOrderedSame||[objvalue compare:@"<null>"]==NSOrderedSame) {
                            objvalue=@"";
                        }
                        sqlite3_bind_text(statement, y, [objvalue UTF8String], -1, NULL);
                    }
                        break;
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
}
@end
