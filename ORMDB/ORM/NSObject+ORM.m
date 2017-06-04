//
//  NSObject+ORM.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import "NSObject+ORM.h"
#import "ORM.h"
#import "ORMDB.h"
@implementation NSObject(Extensions)
+ (void)createTable{
    [ORM createTableFromClass:[self class]];
}
- (void)save:(NSArray *)keyes{
    [ORMDB beginTransaction];
    [ORM saveEntity:self with:keyes];
    [ORMDB commitTransaction];
}
+(void)saveListData:(NSArray *)keys andBlock:(void (^) (NSMutableArray *datas))block{
    [ORMDB beginTransaction];
    
    NSMutableArray *arr=[[NSMutableArray alloc] init];
    block(arr);
    for (id obj in arr) {
        [ORM saveEntity:obj with:keys];
    }
    [ORMDB commitTransaction];
}

+ (id)getObject:(NSArray *)keys withValue:(NSArray *)values{
    return  [ORM get:[self class] withKeys:keys andValues:values];
}

+ (id)list:(NSArray *)keys withValue:(NSArray *)values{
    return  [ORM list:[self class] withKeys:keys andValues:values];
}

+ (void)clearTable{
    [ORM deleteObject:[self class] withKeys:nil andValues:nil];
}

+ (void)clearTable:(NSArray *)keys withValue:(NSArray *)value{
    [ORM deleteObject:[self class] withKeys:keys andValues:value];
}
@end
