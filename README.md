
# ocORM
Objective C 实体对象转换成sql 语句，支持数据类型  int float double number class array

##安装 
###最新的版本4.0.2
 pod 'ocORM', '~> 4.0.2'

##使用
```
#import "NSObject+ORM.h"
```
##配置数据库路径
```
 [ORMDB configDBPath:@"/Users/test/dbpath/test.db"];
```
 
##创建数据库 
```
[ClassInfo createTable];
```
##数据保存 
```
    //开启事务
    
    ClassInfo *classInfo=[[ClassInfo alloc] init];
    classInfo.className=@"三班";
    classInfo.roomId=120;
    classInfo.classNumber=@(1);
    classInfo.classAddress=@"北京市海淀区";
    classInfo.dataInfo=@{@"a":@"b",@"c":@"d"};


    Student *one=[[Student alloc] init];
    one.name=@"小红";
    one.age=15;

    Student *two=[[Student alloc] init];
    two.name=@"小民";
    two.age=18;

    Teacher *teacher=[[Teacher alloc] init];
    teacher.name=@"班主任";

    classInfo.student=@[one,two].copy;
    classInfo.teacher=teacher;

    [classInfo save:@[@"classNumber"]];


}];

    
```

##查询数据
```
    ClassInfo *t=[ClassInfo getObject:@[@"classNumber"] withValue:@[@(1)]];
```
##查询数据列表
```
    NSMutableArray *arrt=[ClassInfo list:@[@"classNumber"] withValue:@[@(1)] ];
```
##自定义查询并封装为对象
```
   NSMutableArray *resultArray = [Test queryForObjectArray:@"Select * from Test"];
```
##自定义查询一行记录并封装为字典
```
 NSMutableDictionary *resultDic = [Test queryForDictionary:@"Select * from Test"];
```
##保存数组
```
  [arr saveListDataWithKeys:@[@"id"]];
```

##自定义sql操作
```
[Test execSql:^(SqlOperationQueueObject *db) {
                [db execDelete:@"delte from Test"];//删除sql语句
                [db execUpdate:@"update Test set xxx=x where xxx=x "];//upate sql语句
               BOOL result = [db rowExist:@"select * from Test where xxx=x"];
            }];
```

##清空表数据
```
    [ClassInfo clearTable];
```
##根据条件删除数据
```
[Test clearTable:@[@"key1",@[@"key2"]] withValue:@[@"value1",@"value2"]];
```

#模型类方法
##ignore column
```
+(NSArray<NSString *> *_Nonnull)sqlIgnoreColumn;
```
## Set Primary key
```
+(NSString * _Nonnull)primarilyKey;
```
## Set foreign key
```
+(NSString * _Nonnull)foreignKey;
```

## foreign update or insert 
```
+(NSDictionary<NSString *, NSString *> *_Nonnull)foreignKeyNotCreateTable;
```


####开启日志调试 运行生成sql语句效果如下
<img src="https://github.com/maopenglin/orm/blob/master/demo.png?raw=true" width="705" height="308" align=center/>
