//
//  NotificationViewController.m
//  SchoolMessage
//
//  Created by wulin on 15/2/1.
//  Copyright (c) 2015年 whwy. All rights reserved.
//

#import "NotificationViewController.h"

#import "MJRefresh.h"

#import "NotificationCell.h"
#import "NotificationDetailViewController.h"
#import "NotificationAddViewController.h"

@interface NotificationViewController ()<UITableViewDataSource,UITableViewDelegate,NotificationAddDalagate>
{
    MJRefreshFooterView *fooder_;
    MJRefreshHeaderView *header_;
}

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSMutableArray * data;

@property (nonatomic,assign) NSInteger page;



@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"班级通知";
    
//    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    addBtn.frame = CGRectMake(0, 0, 44, 44);
//    [addBtn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
//    [addBtn addTarget:self action:@selector(push2Add:) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
//    self.navigationItem.rightBarButtonItem = addItem;
    
    self.data = [NSMutableArray array];
    
    self.page = 0;
    
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-64)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    //    [self creatRefreshFooder:self.tableView];
    [self creatRefreshHeader:self.tableView];
    [header_ beginRefreshing];
}

-(void)push2Add:(id)sender
{
    NotificationAddViewController *vc = [[NotificationAddViewController alloc] init];
    vc.classInfo = self.classInfo;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)creatRefreshHeader:(UIScrollView *)scr
{
    MJRefreshHeaderView *header = [MJRefreshHeaderView header];
    __weak typeof(self) weak = self;
    header.beginRefreshingBlock = ^(MJRefreshBaseView *Refresh)
    {
        weak.page = 0;
        [self getBulletins:^(BOOL succeed, NSDictionary *result) {
            [Refresh endRefreshing];
            if (succeed) {
                if (result.count>9) {
                    [weak creatRefreshFooder:weak.tableView];
                }
                [self.data removeAllObjects];
                [self addResult:[result objectForKey:S_OBJ]];
                [self.tableView reloadData];
            }
            
        }];
        
    };
    header.scrollView = self.tableView;
    header_ = header;
}

-(void)creatRefreshFooder:(UIScrollView *)scr
{
    if (fooder_) {
        return;
    }
    MJRefreshFooterView *fooder = [MJRefreshFooterView footer];
    __weak typeof(self) weak = self;
    fooder.beginRefreshingBlock = ^(MJRefreshBaseView *Refresh)
    {
        weak.page++;
        [weak getBulletins:^(BOOL succeed, NSDictionary *result) {
            [Refresh endRefreshing];
            if (succeed) {
                [self addResult:[result objectForKey:S_OBJ]];
                [self.tableView reloadData];
            }
        }];
    };
    fooder.scrollView = self.tableView;
    fooder_ = fooder;
}


-(void)addResult:(NSArray *)array
{
    for (NSDictionary *dic in array) {
        [self.data addObject:[NSMutableDictionary dictionaryWithDictionary:dic]];
    }
}


-(void)getBulletins:(void(^)(BOOL succeed,NSDictionary *result))callback;
{
    NSString *classId = [[AccountManager sharedInstance].LoginInfos getClassId];
    NSString *studentId = [[AccountManager sharedInstance].LoginInfos getStudentId];
    
    NSDictionary *dic = @{@"1":classId,@"2":studentId,@"4":@"15",@"5":[NSString stringWithFormat:@"%ld",(long)self.page]};
    [[ObjectManager sharedInstance] requestDataOnPost:dic ByFlag:@"21303" callback:callback];
}

-(void)isRead:(NSString *)noticeId callback:(void(^)(BOOL succeed,NSDictionary *result))callback
{
    NSString *sName = [[AccountManager sharedInstance].LoginInfos getStudentName];
    NSString *studentId = [[AccountManager sharedInstance].LoginInfos getStudentId];
    NSString *pName = [[AccountManager sharedInstance].LoginInfos getRelation];
    NSString *pId = [[AccountManager sharedInstance].LoginInfos getParentsId];
    
    NSDictionary *dic = @{@"1":noticeId,@"2":studentId,@"3":sName,@"4":pId,@"5":pName};
    [[ObjectManager sharedInstance] requestDataOnPost:dic ByFlag:@"21302" callback:callback];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSDictionary *dic = [self.data objectAtIndex:indexPath.row];
    NSNumber *readFlag = [dic objectForKey:@"ReadFlag"];
    if (readFlag.intValue !=1) {
        [self isRead:[dic objectForKey:@"Id"] callback:^(BOOL succeed, NSDictionary *result) {
            
        }];
    }
     NSString *classId = [self.classInfo objectForKey:@"ClassId"];
    [dic setValue:[NSNumber numberWithInt:1] forKey:@"ReadFlag"];
    [self.tableView reloadData];
    NotificationDetailViewController * vc = [[NotificationDetailViewController alloc] initByClassId:classId detail:dic];
    [self.navigationController pushViewController:vc animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSDictionary *dic = [self.data objectAtIndex:indexPath.row];
//    NSString *content = [dic objectForKey:@"Content"];
//    CGSize size = [content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(tableView.frame.size.width-50, MAXFLOAT)];
//    NSLog(@"height : %@",NSStringFromCGSize(size));
    return (20+55+42);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [NotificationCell identifier];
    NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[NotificationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSDictionary *dic = [self.data objectAtIndex:indexPath.row];
    [cell setupNotificationViews:dic];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.clipsToBounds = YES;
    return cell;
}

-(void)NotificationOnAdd:(NSDictionary *)dic
{
    [self.data insertObject:dic atIndex:0];
    [self.tableView reloadData];
}

-(void)dealloc
{
    [header_ free];
    [fooder_ free];
}
@end
