
# ocORM
Objective C 实体对象转换成sql 语句，支持数据类型  int float double number class array

##安装
 pod 'ocORM', '~> 2.0.1'

##使用
```
#import "NSObject+ORM.h"
#import "ORMDB.h"
```

##创建数据库 
```
[TestEntity createTable];
```
##数据保存 
```
    //开启事务
    [ORMDB beginTransaction];
    TestEntity *test=[[TestEntity alloc] init];
    test.name=@"测试";
    test.age=@(18);
    test.mId=@(1);

    TestBEntity *b=[[TestBEntity alloc] init];
    b.address=@"北京市海淀区";
    test.classB=b;

    NSMutableArray *arr=[[NSMutableArray alloc] init];
    ClassC *c1=[[ClassC alloc] init];
    c1.pA=@"pa 1";
    c1.pB=@"pb 1";
    [arr addObject:c1];

    ClassC *c2=[[ClassC alloc] init];
    c2.pA=@"pa 2";
    c2.pB=@"pb 2";
    [arr addObject:c2];
    test.clsC=@[c1,c2].mutableCopy;

    [test save:@[@"mId"]];//保存数据
    [ORMDB commitTransaction];
```

##查询数据
```
    TestEntity *t=[TestEntity getObject:@[@"mId"] withValue:@[@(1)]];
```
##查询数据列表
```
    NSMutableArray *arrt=[TestEntity list:@[@"mId"] withValue:@[@(1)] ];
```
##清空表数据
```
    [TestEntity clearTable];
```
####开启日志调试 运行生成sql语句效果如下
<img src="https://github.com/maopenglin/orm/blob/master/m1.png?raw=true" width="705" height="308" align=center/>