//
//  ORMDB.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import "ORMDB.h"
#import "ORM.h"
#import "ORMDBAttributes.h"
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
    NSMutableArray *properties=[ORM parseClass:cls];
    if (sqlite3_open([DBPath UTF8String], &queryDB)== SQLITE_OK&&(sqlite3_prepare_v2(queryDB, [sql UTF8String], -1, &statement, nil)==SQLITE_OK) ) {
        
        if(showsql){
            NSLog(@"%@",sql);
        }
        while (sqlite3_step(statement)==SQLITE_ROW){
            id object=[cls new];
            for (int i=0; i<properties.count; i++) {
                ORMDBAttributes *att=properties[i];
                if (att.propertyDataType!=DBDataTypeClass&&att.propertyDataType!=DBDataTypeArray) {
                    const char *c=(char *)sqlite3_column_text(statement,i) ;
                    if (!c) {
                        c="";
                    }
                    NSString* ucfirstName = [att.propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                      withString:[[att.propertyName substringToIndex:1] uppercaseString]];
                    NSString* selectorName = [NSString stringWithFormat:@"set%@:", ucfirstName];
                    SEL customPropertySetter = NSSelectorFromString(selectorName);
                    NSString *value=[[NSString alloc] initWithCString:c encoding:NSUTF8StringEncoding];
                    NSMethodSignature  *signature = [object methodSignatureForSelector:customPropertySetter];
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                    [invocation setTarget:object];
                    [invocation setSelector:customPropertySetter];
                    [invocation setArgument:&value atIndex:2];
                    [invocation invoke];
                }else{
                    
                    SEL foreignSelector=NSSelectorFromString(@"foreignKey");
                    Class fcls= NSClassFromString(att.classProperty);
                   
                    NSMethodSignature  *foreignSignature = [fcls methodSignatureForSelector:foreignSelector];
                    if(foreignSignature){
                        NSInvocation *foreignInvocation = [NSInvocation invocationWithMethodSignature:foreignSignature];
                        [foreignInvocation setTarget:[fcls class]];
                        [foreignInvocation setSelector:foreignSelector];
                        [foreignInvocation invoke];
                        
                        void *vres=nil;
                        [foreignInvocation getReturnValue:&vres];
                        id foreignObjvalue=(__bridge id )vres;
                        
                       
                        
                        SEL primarySelector=NSSelectorFromString(@"primarilyKey");
                        NSMethodSignature  *primarySignature = [[object class] methodSignatureForSelector:primarySelector];
                        NSInvocation *primaryInvocation = [NSInvocation invocationWithMethodSignature:primarySignature];
                        [primaryInvocation setTarget:[object class]];
                        [primaryInvocation setSelector:primarySelector];
                        [primaryInvocation invoke];
                        void *pres=nil;
                        [primaryInvocation getReturnValue:&pres];
                        id primaryObjvalue=(__bridge id )pres;
                        
                        SEL sel=NSSelectorFromString(primaryObjvalue);
                        NSMethodSignature  *pvSignature = [[object class] methodSignatureForSelector:primarySelector];
                        NSInvocation *pvInvocation = [NSInvocation invocationWithMethodSignature:pvSignature];
                        [pvInvocation setTarget:object];
                        [pvInvocation setSelector:sel];
                        [pvInvocation invoke];

                        void *pvores=nil;
                        [pvInvocation getReturnValue:&pvores];
                        id pvObjvalue=(__bridge id )pvores;
                        
                        NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@ %@",att.classProperty,[ORM createWherStateWith:@[foreignObjvalue] andValues:@[pvObjvalue]]];
                        NSMutableArray *a=[ORMDB queryDB:NSClassFromString(att.classProperty) andSql:sql];
                        id obj=a;
                        if (att.propertyDataType==DBDataTypeClass) {
                            if (a.count>0) {
                                obj=a[0];
                            }
                        }
                        NSString* ucfirstName = [att.propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                          withString:[[att.propertyName substringToIndex:1] uppercaseString]];
                        NSString* selectorName = [NSString stringWithFormat:@"set%@:", ucfirstName];
                        SEL customPropertySetter = NSSelectorFromString(selectorName);
                        NSMethodSignature  *signature = [object methodSignatureForSelector:customPropertySetter];
                        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                        [invocation setTarget:object];
                        [invocation setSelector:customPropertySetter];
                        [invocation setArgument:&obj atIndex:2];
                        [invocation invoke];
                    }else{
                        NSLog(@"==== %@ +(NSString *)foreignKey not found",fcls);
                    }
                }
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
     NSMutableArray *arr=[ORM parseClass:[entity class]];
    int y=1;
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        for (int i=0; i<arr.count; i++) {
            ORMDBAttributes *att=arr[i];
            if (att.propertyDataType!=DBDataTypeClass&&att.propertyDataType!=DBDataTypeArray) {
                NSMethodSignature  *signature = [entity methodSignatureForSelector:NSSelectorFromString(att.propertyName)];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setTarget:entity];
                [invocation setSelector:NSSelectorFromString(att.propertyName)];
                [invocation invoke];
                void *vres=nil;
                [invocation getReturnValue:&vres];
                id objvalue=(__bridge id )vres;
                if(att.propertyDataType==DBDataTypeInt||att.propertyDataType==DBDataTypeNumber) {
                    if (!objvalue||[objvalue isEqual:[NSNull null]]) {
                        objvalue=@(0);
                    }
                    
                    if ( CFNumberIsFloatType((CFNumberRef)objvalue)) {
                        sqlite3_bind_double(statement, y, [objvalue doubleValue]);
                    } else {
                        sqlite3_bind_int(statement, y, [objvalue intValue]);
                    }
                    
                }else if(att.propertyDataType==DBDataTypeFloat||att.propertyDataType==DBDataTypeDouble){
                    sqlite3_bind_text(statement, y, [[NSString stringWithFormat:@"%f",[objvalue doubleValue]] UTF8String],-1,NULL);
                }else{
                    if (!objvalue||[objvalue isEqual:[NSNull null]]||[objvalue compare:@"(null)"]==NSOrderedSame||[objvalue compare:@"<null>"]==NSOrderedSame) {
                        objvalue=@"";
                    }
                    sqlite3_bind_text(statement, y, [objvalue UTF8String], -1, NULL);
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
