
# ocORM
Objective C 实体对象转换成sql 语句，支持数据类型  int float double number class array

##安装
 pod 'ocORM', '~> 2.0.1'

##使用
```
#import "NSObject+ORM.h"
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


    //批量保存
    [Student saveListData:@[@"name"] andBlock:^(NSMutableArray *datas) {
    for(int i=0;i<20000;i++){
        [datas addObject:one];
    }

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
##清空表数据
```
    [ClassInfo clearTable];
```
####开启日志调试 运行生成sql语句效果如下
<img src="https://github.com/maopenglin/orm/blob/master/m1.png?raw=true" width="705" height="308" align=center/>
