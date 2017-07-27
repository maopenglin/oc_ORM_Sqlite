//
//  ORM.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#define force_inline __inline__ __attribute__((always_inline))


static force_inline NSNumber * _Nullable ORMDBNumberCreateFromID(__unsafe_unretained id _Nullable value) {
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    if (!value || value == (id)kCFNull) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num) {
            if (num == (id)kCFNull) return nil;
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        } else {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            return @(atoll(cstring));
        }
    }
    return nil;
}

static force_inline NSString * _Nullable createWhereStatement(NSArray * _Nullable key,NSArray * _Nullable value){
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
            }
            else{
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
    return whereSql;
}

typedef NS_OPTIONS (NSUInteger ,ORMDBDataType){
    ORMDBDataTypeUnknown,
    ORMDBDataTypeBool,
    ORMDBDataTypeInt,
    ORMDBDataTypeFloat,
    ORMDBDataTypeDouble,
    ORMDBDataTypeClass,
    ORMDBDataTypeString,
    ORMDBDataTypeNumber,
    ORMDBDataTypeArray,
    ORMDBDataTypeMutableArray,
    ORMDBDataTypeDictionary,
    ORMDBDataTypeMutableDictionary,
    ORMDBDataTypeNSDate
    
};

@protocol ORM <NSObject>
@optional
/**
 创建表时忽略字段
 **/
+(NSArray<NSString *> *_Nonnull)sqlIgnoreColumn;
/**
 主键
 **/
+(NSString * _Nonnull)primarilyKey;

/**
 外键
 **/
+(NSString * _Nonnull)foreignKey;

/**
 外键映射表操作类型
 实现此方法 标识 关联字段不创建表，而是自动插入 或者 更新 到指定的表
 key=>column
 value=>tableName
 
 +(NSDictionary<NSString *, NSString *> *_Nonnull)foreignKeyNotCreateTable{
	return @{@"conversation_user":@"EXUPersonInfo"};
 }
 **/
+(NSDictionary<NSString *, NSString *> *_Nonnull)foreignKeyNotCreateTable;
@end
@interface ORM : NSObject

+ (void)createTableFromClass:(Class _Nullable ) cls;
+ (void)saveEntity:(id _Nullable )entity with:(NSArray *_Nullable)keys;
+ (id _Nullable )get:(Class _Nullable )cls withKeys:(NSArray *_Nullable)keys andValues:(NSArray *_Nullable)values;
+ (NSMutableArray *_Nullable)list:(Class _Nullable )cls withKeys:(NSArray *_Nullable)keys andValues:(NSArray *_Nullable)values;
+ (void)deleteObject:(Class _Nullable )cls withKeys:(NSArray *_Nullable)keys andValues:(NSArray *_Nullable)values;

@end


@interface ORMDBClassPropertyInfo : NSObject
@property (nonatomic, assign, readonly) objc_property_t _Nullable property;
@property (nonatomic, strong, readonly) NSString * _Nullable name;
@property (nonatomic, strong, readonly) NSString * _Nullable typeEncoding;
@property (nonatomic, assign, readonly) ORMDBDataType type;
@property (nullable, nonatomic, assign, readonly) Class cls;
@property (nullable, nonatomic, strong, readonly) NSString *protocol;
@property (nonatomic, strong) NSString  * _Nullable foreignTableName;
@end


@interface ORMDBClassInfo : NSObject

+ (instancetype _Nullable )metaWithClass:(Class _Nullable )cls;

@property (nonatomic, assign, readonly) Class _Nullable cls;
@property (nonatomic, strong, readonly) NSString * _Nullable name;
@property (nullable, nonatomic, strong, readonly) NSMutableArray *propertyInfos;

@end

static force_inline NSString* _Nullable SelectColumn(Class _Nullable cls){
    ORMDBClassInfo *obj=[ORMDBClassInfo metaWithClass:cls];
    NSMutableString *column=[[NSMutableString alloc] init];
    for (ORMDBClassPropertyInfo *info in obj.propertyInfos) {
        
        if (info.type!=ORMDBDataTypeClass&&
            info.type!=ORMDBDataTypeArray&&
            info.type!=ORMDBDataTypeMutableArray&&
            info.type!=ORMDBDataTypeUnknown){
            [column appendFormat:@"%@,",info.name];
        }
    }
    if (column.length-1>0) {
        [column deleteCharactersInRange:NSMakeRange([column length]-1, 1)];
        
    }
    return column;
    
}
