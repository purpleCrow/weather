//
//  APPVCCity.m
//  Weather
//
//  Created by 文得炙 on 2017/9/14.
//  Copyright © 2017年 crow. All rights reserved.
//

#import "APPVCCity.h"

@interface APPVCCity ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) UITableView *tableView; ///<
@property (nonatomic, strong) NSMutableArray *mArrHeader;    ///<

@end

@implementation APPVCCity


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
    [self setupData];
}

- (void)setup {
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"citys";
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tableFooterView = [UIView new];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor clearColor];
    self.tableView = tableView;
    [self.view addSubview:self.tableView];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStyleDone target:self action:@selector(leftItemOnClicked)];
    leftItem.tintColor = [UIColor blackColor];
    [self.navigationItem setLeftBarButtonItem:leftItem];
}

- (void)leftItemOnClicked {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupData {
    self.mArrHeader = [NSMutableArray array];
    NSDictionary *dict = [self citiesWithDic];
    self.mArrHeader = [[dict allKeys] mutableCopy];
    
    [self.mArrHeader sortUsingSelector:@selector(compare:)];
    [self.tableView reloadData];
}

#pragma mark - tabelView Delegate dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dict = [self citiesWithDic];
    NSArray *arr = [dict objectForKey:[self.mArrHeader objectAtIndex:section]];
    return arr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.mArrHeader.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *dict = [self citiesWithDic];
    NSArray *arr = [dict objectForKey:[self.mArrHeader objectAtIndex:indexPath.section]];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [self getChinesePinYinWithHZStr:[arr objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [self citiesWithDic];
    NSArray *arr = [dict objectForKey:[self.mArrHeader objectAtIndex:indexPath.section]];
    NSString *city = [arr objectAtIndex:indexPath.row];
    
    self.block(city);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.mArrHeader objectAtIndex:section];
}

- (NSString *)getChinesePinYinWithHZStr:(NSString *)chineseStr{
    //将NSString装换成NSMutableString
    NSMutableString *pinyin = [chineseStr mutableCopy];
    
    //将汉字转换为拼音(带音标)
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    //    NSLog(@"dai%@", pinyin);
    
    //去掉拼音的音标
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    //        NSLog(@"城市 %@", pinyin);
    return pinyin;
}

- (NSDictionary *)citiesWithDic{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"citydict.plist" ofType:nil];
    NSDictionary *cityDic = [NSDictionary dictionaryWithContentsOfFile:path];
    return cityDic;
}

@end
