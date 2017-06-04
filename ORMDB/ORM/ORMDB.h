//
//  ORMDB.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DBPath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"/orm.db"]
#define showsql false
@interface ORMDB : NSObject
+(void)beginTransaction;
+(void)commitTransaction;
+(void)execsql:(NSString *)sql;
+(void)saveObject:(id)object withSql:(NSString *)sql;
+ (NSMutableArray *)queryDB:(Class)cls andSql:(NSString *)sql;
@end
