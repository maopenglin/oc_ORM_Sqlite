//
//  NSObject+ORM.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import "NSObject+ORM.h"
#import "ORM.h"
@implementation NSObject(Extensions)
+ (void)createTable{
    [ORM createTableFromClass:[self class]];
}
- (void)save:(NSArray *)keyes{
    [ORM saveEntity:self with:keyes];
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

+ (void)clearTableWithKey:(NSArray *)keys withValue:(NSArray *)value{
    [ORM deleteObject:[self class] withKeys:keys andValues:value];
}
@end
