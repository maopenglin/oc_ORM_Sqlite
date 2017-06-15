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
static dispatch_queue_t    _queue;
static dispatch_once_t onceToken;
+ (void)createTable{
    [ORM createTableFromClass:[self class]];
    dispatch_once(&onceToken, ^{
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"ORMDB.%@", self] UTF8String], NULL);
    });
}
- (void)save:(NSArray *)keyes{
    dispatch_sync(_queue, ^() {
        [ORMDB beginTransaction];
        [ORM saveEntity:self with:keyes];
        [ORMDB commitTransaction];
    });
}
+(void)saveListData:(NSArray *)keys andBlock:(void (^) (NSMutableArray *datas))block{
    dispatch_sync(_queue, ^() {
        [ORMDB beginTransaction];
        NSMutableArray *arr=[[NSMutableArray alloc] init];
        block(arr);
        for (id obj in arr) {
            [ORM saveEntity:obj with:keys];
        }
        [ORMDB commitTransaction];
    });
}

+ (id)getObject:(NSArray *)keys withValue:(NSArray *)values{
    return  [ORM get:[self class] withKeys:keys andValues:values];
}

+ (id)list:(NSArray *)keys withValue:(NSArray *)values{
    return  [ORM list:[self class] withKeys:keys andValues:values];
}

+ (void)clearTable{
    dispatch_sync(_queue, ^() {
        [ORM deleteObject:[self class] withKeys:nil andValues:nil];
    });
}

+ (void)clearTable:(NSArray *)keys withValue:(NSArray *)value{
    dispatch_sync(_queue, ^() {
        [ORM deleteObject:[self class] withKeys:keys andValues:value];
    });
}
@end

@implementation NSArray(ORM)

-(void)saveListDataWithKeys:(NSArray *)keys{
    dispatch_sync(_queue, ^() {
        [ORMDB beginTransaction];
        for (id obj in self) {
            [ORM saveEntity:obj with:keys];
        }
        [ORMDB commitTransaction];
    });
}

@end
