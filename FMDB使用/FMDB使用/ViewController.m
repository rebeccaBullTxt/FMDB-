//
//  ViewController.m
//  FMDB使用
//
//  Created by 刘渊 on 2019/9/25.
//  Copyright © 2019 刘渊. All rights reserved.
//

#import "ViewController.h"
#import <FMDB.h>
@interface ViewController ()
@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, copy  ) NSString *databasePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *lidDirPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *databasePath = [lidDirPath stringByAppendingPathComponent:@"DatabaseDemo.sqlite"];
    NSLog(@"path = %@",databasePath);
    self.databasePath = databasePath;
    // 根据指定的沙盒路径来创建数据对象，如果路径下的数据库不存在，就创建，如果存在就不创建
    self.database = [FMDatabase databaseWithPath:databasePath];
    if (self.database) {
        NSLog(@"create success");
    }else{
        NSLog(@"create failed");
    }
    if (![self.database open]) {
        return;
    }
    NSString *createTableSql = @"create table if not exists User(id integer primary key autoincrement, username text not null, phone text not null, age integer)";
    BOOL result = [self.database executeUpdate:createTableSql];
    if (result) {
        NSLog(@"创建表成功");
    } else {
        NSLog(@"创建表失败");
    }
    // 每次执行完对应SQL之后，要关闭数据库
    [self.database close];
    
    //插入命令
    if ([self.database open]) {
        NSString *insertSql = @"insert into User(username, phone, age) values(?, ?, ?)";
        BOOL result = [self.database executeUpdate:insertSql, @"user01", @"110", @(18)];
        if (result) {
            NSLog(@"插入数据成功");
        } else {
            NSLog(@"插入数据失败");
        }
        [self.database close];
    }
    
    //更新
    if ([self.database open]) {
        NSString *updateSql = @"update User set phone = ? where username = ?";
        BOOL result = [self.database executeUpdate:updateSql, @"15823456789", @"user01"];
        if (result) {
            NSLog(@"更新数据成功");
        } else {
            NSLog(@"更新数据失败");
        }
        [self.database close];
    }
    
    //查询
    if ([self.database open]) {
        NSString *selectSql = @"select * from User";
        FMResultSet *resultSet = [self.database executeQuery:selectSql];
        while ([resultSet next]) {
            NSString *username = [resultSet stringForColumn:@"username"];
            NSString *phone = [resultSet stringForColumn:@"phone"];
            NSInteger age = [resultSet intForColumn:@"age"];
            NSLog(@"username=%@, phone=%@, age=%ld \n", username, phone, age);
        }
        [self.database close];
    }
    
   
    
}


#pragma mark - 使用FMDBQueue
- (BOOL)createWithFMDB{
    /*
        在多个线程中同时使用一个FMDatabase实例是不明智的。现在你可以为每 个线程创建一个FMDatabase对象，不要让多个线程分享同一个实例，他无法在多个线程中同时使用。否则程序会时不时崩溃或者报告异常。所以，不要初始化FMDatabase对象，然后在多个线程中使用。这时候，我们就需要使 用FMDatabaseQueue来创建队列执行事务。
        */
       self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
       __block BOOL result = NO;
       [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
           // 要执行的SQL语句，要放在Block里执行，用inDatabase不用手动打开和关闭数据库
           // 创建表，增加，删除，更新，查询 操作
           // 编写需要执行的代码
           result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_student (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, score REAL DEFAULT 1);"];
       }];
    return result;
}
//更新
- (void)upateMethod{
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE t_person SET weight = 1500 WHERE name = 'zs';"];

        NSArray *array = @[@"abc"];
//        array[1];

        [db executeUpdate:@"UPDATE t_person SET weight = 500 WHERE name = 'ls';"];
    }];
}
//选择
- (void)selectMethod{
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        // FMResultSet结果集, 结果集其实和tablevivew很像
        FMResultSet *set = [db executeQuery:@"SELECT id, name, score FROM t_student;"];
        while ([set next]) { // next方法返回yes代表有数据可取
            int ID = [set intForColumnIndex:0];
            //        NSString *name = [set stringForColumnIndex:1];
            NSString *name = [set stringForColumn:@"name"]; // 根据字段名称取出对应的值
            double score = [set doubleForColumnIndex:2];
            NSLog(@"%d %@ %.1f", ID, name, score);
        }
    }];
}






@end
