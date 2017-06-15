//
//  main.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ClassInfo.h"
#import "NewOjb.h"

#import "NSObject+ORM.h"
#import "Test.h"
#import "Test2.h"
#import "ORMDB.h"
double t(double last, char* key){
    clock_t now = clock();
    printf("time:%fs \t key:%s \n", (last != 0) ? (double)(now - last) / CLOCKS_PER_SEC : 0, key);
    return now;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
    
        [ORMDB configDBPath:@"/Users/maopenglin/test.db"];
        
        //return 0;
        
        dispatch_queue_t dispatchQueue = dispatch_queue_create("com.queue.test", DISPATCH_QUEUE_CONCURRENT);
        dispatch_group_t dispatchGroup = dispatch_group_create();
        
        [ClassInfo createTable];
        [Test createTable];
        [NewOjb createTable];
        
     
        for (int i=0; i<2000; i++) {
            dispatch_async(dispatch_queue_create("abc", DISPATCH_QUEUE_SERIAL), ^{
                NewOjb *n1=[[NewOjb alloc] init];
                n1.aaa=@(1);
                n1.bbb=@"ccc";
                [n1 save:@[@"aaa"]];
                
                NewOjb *n2=[[NewOjb alloc] init];
                n2.aaa=@(1);
                n2.bbb=@"ddd";
                [n2 save:@[@"aaa"]];
                [ORMDB queryDB:[NewOjb class] andSql:@"select * from NewOjb"];
                
            });
            [ORMDB queryDB:[NewOjb class] andSql:@"select * from NewOjb"];
        }
        
    for(int i=0;i<20;i++){
        dispatch_group_async(dispatchGroup, dispatchQueue, ^{
            ClassInfo *classInfo=[[ClassInfo alloc] init];
            classInfo.className=@"三班";
            classInfo.roomId=120;
            classInfo.classNumber=@(1);
            //classInfo.classAddress=@"北京市海淀区";
            classInfo.dataInfo=@{@"a":@"b",@"c":@"d"};
            
            
            Student *one=[[Student alloc] init];
            one.name=@"小红";
            one.age=15;
            one.sid=100;
            
            Student *two=[[Student alloc] init];
            two.name=@"小民";
            two.age=18;
            two.sid=102;
            
            Teacher *teacher=[[Teacher alloc] init];
            teacher.name=@"班主任";
            
            classInfo.student=@[one,two].copy;
            classInfo.teacher=teacher;
            
            [classInfo save:@[@"classNumber"]];
            
            
            Test *test=[[Test alloc] init];
            test.one=295;
            
            
            Test2 *t2=[[Test2 alloc] init];
            t2.age=10;
            t2.sid=210;
            t2.name=@"明2";
            test.test=t2;
            
            [test save:@[@"one"]];
            
            [Test getObject:nil withValue:nil];
            [ORMDB queryWithSql:@"Select * from Test"];
          NSArray *arr= [ORMDB queryDB:[NewOjb class] andSql:@"select * from NewOjb"];
           
        });
    }
        
        NSArray *arr= [ORMDB queryDB:[NewOjb class] andSql:@"SELECT * FROM NewOjb"];
        NSLog(@"arr.count:%@",arr);
        
//        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
//            NSLog(@"=3333===");
//            NewOjb *n1=[[NewOjb alloc] init];
//            n1.aaa=@(1);
//            n1.bbb=@"ccc";
//            [n1 save:@[@"aaa"]];
//            
//            NewOjb *n2=[[NewOjb alloc] init];
//            n2.aaa=@(1);
//            n2.bbb=@"ddd";
//            [n2 save:@[@"aaa"]];
//        });
        
        
      //  sleep(10);
    }
    return 0;
}
