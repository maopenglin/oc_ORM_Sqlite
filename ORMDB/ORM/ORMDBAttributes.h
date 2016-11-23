//
//  ORMDBAttributes.h
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DBDataType) {
    DBDataTypeNumber,
    DBDataTypeInt,
    DBDataTypeFloat,
    DBDataTypeDouble,
    DBDataTypeString,
    DBDataTypeArray,
    DBDataTypeClass
};
@interface ORMDBAttributes : NSObject
@property(nonatomic,strong)NSString *propertyName;
@property(nonatomic,strong)NSString *propertyAttributes;
@property(nonatomic,assign)DBDataType propertyDataType;
@property(nonatomic,strong)NSString *classProperty;
@end
