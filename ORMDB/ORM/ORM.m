//
//  ORM.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import "ORM.h"
#import "ORMDB.h"

static force_inline ORMDBDataType ORMDBGetDataType(const char *typeEncoding){
    
    char *type = (char *)typeEncoding;
    if (!type) return ORMDBDataTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return ORMDBDataTypeUnknown;
    switch (*type) {
        case 'B': return ORMDBDataTypeBool;
        case 'c': return ORMDBDataTypeInt;
        case 'C': return ORMDBDataTypeInt;
        case 's': return ORMDBDataTypeInt;
        case 'S': return ORMDBDataTypeInt;
        case 'i': return ORMDBDataTypeInt;
        case 'I': return ORMDBDataTypeInt;
        case 'l': return ORMDBDataTypeInt;
        case 'L': return ORMDBDataTypeInt;
        case 'q': return ORMDBDataTypeInt;
        case 'Q': return ORMDBDataTypeInt;
        case 'f': return ORMDBDataTypeFloat;
        case 'd': return ORMDBDataTypeDouble;
        case 'D': return ORMDBDataTypeDouble;
        default:return  ORMDBDataTypeUnknown;
            
    }
    return ORMDBDataTypeUnknown;
}



@implementation ORMDBClassPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property{
    if (!property) return nil;
    self = [super init];
    _property=property;
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    _type=ORMDBDataTypeUnknown;
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        switch (attrs[i].name[0]) {
            case 'T':{
                _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                if (attrs[i].value) {
                    _type=ORMDBGetDataType(attrs[i].value);
                    
                    if(_type==ORMDBDataTypeUnknown){
                        NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                        if (![scanner scanString:@"@\"" intoString:NULL]) continue;
                        
                        NSString *clsName = nil;
                        if ([scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                            if (clsName.length) {
                                _cls = objc_getClass(clsName.UTF8String);
                                if ([clsName compare:@"NSString"]==NSOrderedSame) {
                                    _type=ORMDBDataTypeString;
                                }else if([clsName compare:@"NSNumber"]==NSOrderedSame){
                                    _type=ORMDBDataTypeNumber;
                                }else if([clsName compare:@"NSArray"]==NSOrderedSame){
                                    _type=ORMDBDataTypeArray;
                                }else if([clsName compare:@"NSMutableArray"]==NSOrderedSame){
                                    _type=ORMDBDataTypeMutableArray;
                                }
                                else if([clsName compare:@"NSDictionary"]==NSOrderedSame){
                                    _type=ORMDBDataTypeDictionary;
                                }else if([clsName compare:@"NSMutableDictionary"]==NSOrderedSame){
                                    _type=ORMDBDataTypeMutableDictionary;
                                }else if([clsName compare:@"NSDate"]==NSOrderedSame){
                                    _type=ORMDBDataTypeNSDate;
                                }
                            };
                        }
                        while ([scanner scanString:@"<" intoString:NULL]) {
                            NSString* protocol = nil;
                            if ([scanner scanUpToString:@">" intoString: &protocol]) {
                                _protocol=protocol;
                                break;
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                        
                    }
                    
                }
            }
                break;
        }
    }
    return self;
}

@end


@implementation ORMDBClassInfo
- (instancetype)initWithClass:(Class)cls {
    if (!cls) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        
        unsigned int propertyCount = 0;
        NSArray *ignoreColumn=nil;
        NSMethodSignature  *foreignSignature = [cls methodSignatureForSelector:NSSelectorFromString(@"sqlIgnoreColumn")];
        if (foreignSignature) {
            ignoreColumn=((NSArray * (*)(id, SEL))(void *) objc_msgSend)((id)cls, NSSelectorFromString(@"sqlIgnoreColumn"));
        }
        
        NSDictionary *foreignKeyOperation=nil;
        NSMethodSignature  *foreignKeyOperationSignature = [cls methodSignatureForSelector:NSSelectorFromString(@"foreignKeyNotCreateTable")];
        if (foreignKeyOperationSignature) {
            foreignKeyOperation=((NSDictionary * (*)(id, SEL))(void *) objc_msgSend)((id)cls, NSSelectorFromString(@"foreignKeyNotCreateTable"));
        }
        
        Class tmpCls=cls;
        while (tmpCls!=[NSObject class]) {
            objc_property_t *properties = class_copyPropertyList(tmpCls, &propertyCount);
            if(properties){
                
                if (!_propertyInfos) {
                    NSMutableArray *propertyInfos = [NSMutableArray new];
                    _propertyInfos = propertyInfos;
                }
                
                for (unsigned int i = 0; i < propertyCount; i++) {
                    ORMDBClassPropertyInfo *property=[[ORMDBClassPropertyInfo alloc] initWithProperty:properties[i]];
                    if (ignoreColumn&&[ignoreColumn containsObject:property.name ]) {
                        continue;
                    }
                    
                    if (foreignKeyOperation) {
                        property.foreignTableName=foreignKeyOperation[property.name];
                    }
                    if(property.name) [_propertyInfos addObject:property];
                    
                    
                }
                free(properties);
            }
            tmpCls=[tmpCls superclass];
        }
    }
    return self;
}
+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    ORMDBClassInfo *meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!meta) {
        meta = [[ORMDBClassInfo alloc] initWithClass:cls];
        if (meta) {
            
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}


@end

@implementation ORM

+ (void)createTableFromClass:(Class) cls{
    
    ORMDBClassInfo *obj=[ORMDBClassInfo metaWithClass:cls];
    if(!obj)return;
    
    NSString *sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( autoIncrementId INTEGER PRIMARY KEY AUTOINCREMENT ,",cls];
    for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
        
        switch (info.type) {
            case ORMDBDataTypeNumber:
            case ORMDBDataTypeInt:
            case ORMDBDataTypeBool:{
                sql=[NSString stringWithFormat:@"%@ %@ integer ,",sql,info.name];
            }
                break;
            case ORMDBDataTypeFloat:
                sql=[NSString stringWithFormat:@"%@ %@ float ,",sql,info.name];
                break;
            case ORMDBDataTypeDouble:
            case ORMDBDataTypeNSDate:
                sql=[NSString stringWithFormat:@"%@ %@ double ,",sql,info.name];
                break;
            case ORMDBDataTypeString:
            case ORMDBDataTypeDictionary:
            case ORMDBDataTypeMutableDictionary:{
                sql=[NSString stringWithFormat:@"%@ %@ TEXT  DEFAULT NULL ,",sql,info.name];
            }
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
    
    for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
        if (info.foreignTableName) {
            continue;
        }
        if (info.protocol) {
            [ORM createTableFromClass:NSClassFromString(info.protocol) ];
        }else if(info.type==ORMDBDataTypeUnknown&&info.cls){
            [ORM createTableFromClass:info.cls];
        }
    }
    
    [ORMDB beginTransaction];
    [ORMDB  execsql:sql];
    [ORMDB commitTransaction];
    
}
+ (void)saveEntity:(id)entity with:(NSArray *)keys{
    
    if (!entity) {
        return;
    }
    
    if (keys&&keys.count>0) {
        
        NSString *selectSql=[NSString stringWithFormat:@"SELECT * FROM %@ %@",[entity class],[ORM createWherStatement:entity andKeys:keys]];
        BOOL exist= [ORMDB rowExist:selectSql];
        if (exist) {
            NSMutableString *sql=[[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ",[entity class]];
            ORMDBClassInfo *obj=[ORMDBClassInfo metaWithClass:[entity class]];
            
            for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
                
                if (info.type!=ORMDBDataTypeClass&&info.type!=ORMDBDataTypeArray&&info.type!=ORMDBDataTypeMutableArray&&info.type!=ORMDBDataTypeUnknown) {
                    [sql appendFormat:@" %@=?,",info.name];
                    
                }
                
            }
            if (sql.length-1>0) {
                [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
                [sql appendFormat:@" %@ ",[ORM createWherStatement:entity andKeys:keys]];
            }
            
            [ORMDB saveObject:entity withSql:sql];
            for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
                
                if (info.type==ORMDBDataTypeClass||
                    info.type==ORMDBDataTypeArray||
                    info.type==ORMDBDataTypeMutableArray||
                    (info.type==ORMDBDataTypeUnknown&&info.cls)){
                    id res=((id (*)(id, SEL))(void *) objc_msgSend)((id)entity, NSSelectorFromString(info.name));
                    if(res){
                        if ([res isKindOfClass:[NSArray class]]||[res isKindOfClass:[NSMutableArray class]]) {
                            NSArray *arr=(NSArray *)res;
                            for (int i=0; i<arr.count; i++) {
                                id obj=arr[i];
                                if (info.foreignTableName) {//插入或者更新指定表不删除
                                    [ORM updateTable:res andPropertyName:NSClassFromString(info.foreignTableName) andParentEntity:entity];
                                }else{
                                    //直接删除
                                    [ORM saveClassPropertyValue:obj andPropertyName:NSClassFromString(info.protocol) andParentEntity:entity];
                                }
                            }
                        }else{
                            if (info.foreignTableName) {//插入或者更新指定表不删除
                                [ORM updateTable:res andPropertyName:NSClassFromString(info.foreignTableName) andParentEntity:entity];
                            }else{
                                //直接删除
                                [ORM saveClassPropertyValue:res andPropertyName:info.cls andParentEntity:entity];
                            }
                        }
                    }
                }
            }
            
        }else{
            [ORM insert:entity];
        }
        
    }else{
        [ORM insert:entity];
    }
    
    
    
}
+ (void)insert:(id)entity{
    ORMDBClassInfo *obj=[ORMDBClassInfo metaWithClass:[entity class]];
    NSMutableString *sql=[[NSMutableString alloc] initWithFormat:@"INSERT INTO  %@   (",[entity class]];
    NSMutableString *valueSql=[[NSMutableString alloc] initWithString:@" VALUES ( "];
    for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
        if (info.type!=ORMDBDataTypeClass&&info.type!=ORMDBDataTypeArray&&info.type!=ORMDBDataTypeMutableArray&&info.type!=ORMDBDataTypeUnknown) {
            [sql appendFormat:@"%@ ,",info.name];
            [valueSql appendFormat:@"?,"];
        }
    }
    
    if (sql.length-1>0) {
        [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
        [sql appendString:@")"];
    }
    [sql appendString:valueSql];
    if (sql.length-1>0) {
        [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
        [sql appendString:@")"];
    }
    [sql appendString:@" ;"];
    
    [ORMDB saveObject:entity withSql:sql];
    
    for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
        
        if (info.type==ORMDBDataTypeClass||
            info.type==ORMDBDataTypeArray||
            info.type==ORMDBDataTypeMutableArray||
            (info.type==ORMDBDataTypeUnknown&&info.cls)){
            id res=((id (*)(id, SEL))(void *) objc_msgSend)((id)entity, NSSelectorFromString(info.name));
            if(res){
                if ([res isKindOfClass:[NSArray class]]||[res isKindOfClass:[NSMutableArray class]]) {
                    NSArray *arr=(NSArray *)res;
                    for (int i=0; i<arr.count; i++) {
                        id obj=arr[i];
                        if (info.foreignTableName) {//插入或者更新指定表不删除
                            [ORM updateTable:res andPropertyName:NSClassFromString(info.foreignTableName) andParentEntity:entity];
                        }else{
                            //直接删除
                            [ORM saveClassPropertyValue:obj andPropertyName:NSClassFromString(info.protocol) andParentEntity:entity ];
                        }
                    }
                }else{
                    if (info.foreignTableName) {//插入或者更新指定表不删除
                        [ORM updateTable:res andPropertyName:NSClassFromString(info.foreignTableName) andParentEntity:entity];
                    }else{
                        //直接删除
                        [ORM saveClassPropertyValue:res andPropertyName:info.cls andParentEntity:entity];
                    }
                }
            }
        }
    }
}
+ (void)updateTable:(id)res andPropertyName:(Class)cls andParentEntity:(id)entity{
    SEL foreignSelector=NSSelectorFromString(@"foreignKey");
    
    NSMethodSignature  *foreignSignature = [[cls class] methodSignatureForSelector:foreignSelector];
    if (foreignSignature) {
        NSString *foreignKey=((NSString * (*)(id, SEL))(void *) objc_msgSend)((id)[cls class], foreignSelector);
        NSString *primarilyKey=((NSString * (*)(id, SEL))(void *) objc_msgSend)((id)[entity class], NSSelectorFromString(@"primarilyKey"));
        
        
        NSString *resPrimaryKey=nil;
        id resPrimarylyValue=nil;
        if ([cls respondsToSelector:NSSelectorFromString(@"primarilyKey")]) {
            resPrimaryKey=((NSString * (*)(id, SEL))(void *) objc_msgSend)((id)[cls class], NSSelectorFromString(@"primarilyKey"));
            resPrimarylyValue=[res valueForKey:resPrimaryKey];
        }
        id primarilyKeyValue=[entity valueForKey:primarilyKey];
        if (![res valueForKey:foreignKey]) {
            [res setValue:primarilyKeyValue forKey:foreignKey];
        }
        
        NSString *selectSql=[NSString stringWithFormat:@"SELECT %@ from %@ WHERE %@='%@' ;",resPrimaryKey,cls,foreignKey,primarilyKeyValue];
        
        
        if (resPrimarylyValue) {
            if (!([resPrimarylyValue isKindOfClass:[NSNumber class]]&&[resPrimarylyValue integerValue]==0)) {
                selectSql=[NSString stringWithFormat:@"SELECT %@ from %@ WHERE %@='%@'  ;",resPrimaryKey,cls,resPrimaryKey,resPrimarylyValue];
            }
            
        }
        
        BOOL result=[ORMDB rowExist:selectSql];
        
        if (result) {
            NSMutableString *sql=[[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ",cls];
            ORMDBClassInfo *obj=[ORMDBClassInfo metaWithClass:[res class]];
            
            for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
                
                if (info.type!=ORMDBDataTypeClass&&info.type!=ORMDBDataTypeArray&&info.type!=ORMDBDataTypeMutableArray&&info.type!=ORMDBDataTypeUnknown) {
                    [sql appendFormat:@" %@=?,",info.name];
                    
                }
                
            }
            if (sql.length-1>0) {
                [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
                
                if (resPrimaryKey&&!([resPrimarylyValue isKindOfClass:[NSNumber class]]&&[resPrimarylyValue integerValue]==0)) {
                    [sql appendFormat:@" WHERE %@='%@'",resPrimaryKey,resPrimarylyValue];
                }else{
                    [sql appendFormat:@" WHERE %@='%@'",foreignKey,primarilyKeyValue];
                }
            }
            
            [sql appendString:@" ;"];
            [ORMDB saveObject:res withSql:sql];
        }else{
            
            NSMutableString *sql=[[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ ( ",cls];
            ORMDBClassInfo *obj=[ORMDBClassInfo metaWithClass:[res class]];
            NSMutableString *valueSql=[[NSMutableString alloc] initWithString:@" VALUES ( "];
            for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
                
                if (info.type!=ORMDBDataTypeClass&&info.type!=ORMDBDataTypeArray&&info.type!=ORMDBDataTypeMutableArray&&info.type!=ORMDBDataTypeUnknown) {
                    [sql appendFormat:@"%@ ,",info.name];
                    [valueSql appendFormat:@"?,"];
                }
                
            }
            if (sql.length-1>0) {
                [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
                [sql appendString:@")"];
            }
            [sql appendString:valueSql];
            if (sql.length-1>0) {
                [sql deleteCharactersInRange:NSMakeRange([sql length]-1, 1)];
                [sql appendString:@")"];
            }
            [sql appendString:@" ;"];
            
            [ORMDB saveObject:res withSql:sql];
        }
        
    }else{
        NSLog(@"%@ foreignKey not found",[entity class]);
    }
}
+ (void)saveClassPropertyValue:(id)res andPropertyName:(Class)cls andParentEntity:(id)entity{
    SEL foreignSelector=NSSelectorFromString(@"foreignKey");
    
    NSMethodSignature  *foreignSignature = [[cls class] methodSignatureForSelector:foreignSelector];
    if (foreignSignature) {
        NSString *foreignKey=((NSString * (*)(id, SEL))(void *) objc_msgSend)((id)[cls class], foreignSelector);
        NSString *primarilyKey=((NSString * (*)(id, SEL))(void *) objc_msgSend)((id)[entity class], NSSelectorFromString(@"primarilyKey"));
        id primarilyKeyValue=((id (*)(id, SEL))(void *) objc_msgSend)((id)entity, NSSelectorFromString(primarilyKey));
        NSString* ucfirstName = [foreignKey stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                    withString:[[foreignKey substringToIndex:1] uppercaseString]];
        NSString* foreignKeySetter = [NSString stringWithFormat:@"set%@:", ucfirstName];
        if (![res valueForKey:foreignKey]) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)res,NSSelectorFromString(foreignKeySetter),primarilyKeyValue);
            
        }
        
        
        NSString *resPrimaryKey=nil;
        id resPrimarylyValue=nil;
        if ([cls respondsToSelector:NSSelectorFromString(@"primarilyKey")]) {
            resPrimaryKey=((NSString * (*)(id, SEL))(void *) objc_msgSend)((id)[cls class], NSSelectorFromString(@"primarilyKey"));
            resPrimarylyValue=[res valueForKey:resPrimaryKey];
        }
        
        if (resPrimaryKey||foreignKey) {
            if (resPrimaryKey&&!([resPrimarylyValue isKindOfClass:[NSNumber class]]&&[resPrimarylyValue integerValue]==0)) {
                [ORM saveEntity:res with:@[resPrimaryKey]];
            }else{
                [ORM saveEntity:res with:@[foreignKey]];
            }
            
        }else{
            [ORM saveEntity:res with:nil];
        }
    }else{
        NSLog(@"===class :%@ +(NSString *)foreignKey ",res);
    }
}
+ (id)get:(Class)cls withKeys:(NSArray *)keys andValues:(NSArray *)values{
    if (keys||values) {
        if (keys.count!=values.count) {
            return nil;
        }
    }
    
    
    
    NSString *sql=[NSString stringWithFormat:@"SELECT %@ FROM  %@ %@",SelectColumn(cls),cls,createWhereStatement(keys, values)];
    
    NSMutableArray *arr=[ORMDB queryDB:cls andSql:sql];
    if (arr.count>0) {
        return arr[0];
    }
    
    return  nil;
}
+ (void)deleteObject:(Class)cls withKeys:(NSArray *)keys andValues:(NSArray *)values{
    NSString *sql=[NSString stringWithFormat:@"DELETE FROM  %@ %@",cls,createWhereStatement(keys, values)];
    [ORMDB beginTransaction];
    [ORMDB execsql:sql];
    [ORMDB commitTransaction];
}
+ (NSMutableArray *)list:(Class)cls withKeys:(NSArray *)keys andValues:(NSArray *)values{
    if (keys||values) {
        if (keys.count!=values.count) {
            return nil;
        }
    }
    NSString *sql=[NSString stringWithFormat:@"SELECT %@ FROM  %@ %@",SelectColumn(cls),cls,createWhereStatement(keys, values)];
    NSMutableArray *arr=[ORMDB queryDB:cls andSql:sql];
    return  arr;
}



+(NSString *)createWherStatement:(id)entity andKeys:(NSArray *)keys{
    if (!keys||keys.count==0) {
        return @"";
    }
    NSString *whereSql=@"";
    for (int i=0; i<keys.count; i++) {
        NSString *method=keys[i];
        NSMethodSignature  *signature = [entity methodSignatureForSelector:NSSelectorFromString(method)];
        if (!signature) {
            NSLog(@"%@ not found",method);
            return @"";
        }
        
        id objvalue=[entity valueForKey:keys[i]];
        
        NSString *type=[NSString stringWithFormat:@"%@",[objvalue class]];
        
        if (i==0) {
            if ([type hasSuffix:@"NSCFNumber"]||[type hasSuffix:@"NSCFBoolean"]||[type compare:@"(null)"]==NSOrderedSame) {
                whereSql=[NSString stringWithFormat:@"WHERE %@ = %li ",keys[i],[[entity valueForKey:keys[i]] longValue]];
            }else{
                whereSql=[NSString stringWithFormat:@"WHERE %@ = '%@' ",keys[i],[entity valueForKey:keys[i]]];
            }
        }else{
            if ([type hasSuffix:@"NSCFNumber"]||[type hasSuffix:@"NSCFBoolean"]||[type compare:@"(null)"]==NSOrderedSame) {
                whereSql=[NSString stringWithFormat:@"%@ AND  %@ = %li  ",whereSql,keys[i],[[entity valueForKey:keys[i]] longValue]];
            }else{
                whereSql=[NSString stringWithFormat:@"%@ AND  %@ = '%@'  ",whereSql,keys[i],[entity valueForKey:keys[i]]];
            }
        }
    }
    whereSql=[NSString stringWithFormat:@"%@ ;",whereSql];
    return whereSql;
    
}


@end
