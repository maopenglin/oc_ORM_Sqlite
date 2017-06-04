//
//  main.m
//  ORM
//
//  Created by PengLinmao on 16/11/22.
//  Copyright © 2016年 PengLinmao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ClassInfo.h"


#import "NSObject+ORM.h"
#import "ORMDB.h"
double t(double last, char* key){
    clock_t now = clock();
    printf("time:%fs \t key:%s \n", (last != 0) ? (double)(now - last) / CLOCKS_PER_SEC : 0, key);
    return now;
}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
      
      
        //return 0;
        [ClassInfo createTable];
        
       ClassInfo *a= [ClassInfo getObject:@[@"classNumber"] withValue:@[@(1)]];
        NSLog(@"a.dataInfo:%@ ,%@",a.dataInfo,a.dataInfo.class);
        //return 0;
      
            ClassInfo *classInfo=[[ClassInfo alloc] init];
            classInfo.className=@"三班";
            classInfo.roomId=120;
            classInfo.classNumber=@(1);
            classInfo.classAddress=@"北京市海淀区";
            classInfo.dataInfo=@{@"a":@"b",@"c":@"d"};
            //[classInfo save:@[@"classNumber"]];
        
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
        
        [classInfo save:@[@"classNumber"]];
        double t1 = t(0, "");
        
        
            [classInfo save:@[@"classNumber"]];
    

        
       
       
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            [Student saveListData:@[@"name"] andBlock:^(NSMutableArray *datas) {
                for(int i=0;i<20000;i++){
                    [datas addObject:one];
                }
                
            }];
       // });
        
        t(t1, "end");
       //ClassInfo *dbResult= [ClassInfo getObject:@[@"classNumber"] withValue:@[@1]];
        
        NSLog(@"%@", @[@"a",@"b",@"c"].description);
    }
    return 0;
}
