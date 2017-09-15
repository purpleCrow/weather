//
//  APPVCWeather.m
//  Weather
//
//  Created by 文得炙 on 2017/9/14.
//  Copyright © 2017年 crow. All rights reserved.
//

#import "APPVCWeather.h"
#import <AVOSCloud/AVOSCloud.h>
#import "APPVCCity.h"
#import "CABasicAnimation+Category.h"
#import "LoadingView.h"

#define Screen_Width [UIScreen mainScreen].bounds.size.width
#define Screen_Height [UIScreen mainScreen].bounds.size.height

@interface UITableViewCellWeather : UITableViewCell

@property (nonatomic, weak) UILabel *lab; ///< date
@property (nonatomic, weak) UILabel *tem; ///< temperature
@property (nonatomic, weak) UIImageView *imgV; ///< weather image

- (void)setupDataWithDate:(NSString *)date tem:(NSString *)tem weatherImage:(UIImage *)image;

@end

@implementation UITableViewCellWeather

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // date
    CGFloat width = [@"OOOO,00 OOOO 0000" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 60) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:19]} context:nil].size.width;
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, width, 60)];
    lab.textColor = [UIColor colorWithRed:0.13 green:0.16 blue:0.17 alpha:1];
    lab.textAlignment = NSTextAlignmentLeft;
    lab.font = [UIFont systemFontOfSize:19];
    [self.contentView addSubview:lab];
    self.lab = lab;
    
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(Screen_Width - 12 - 44, (60-44)/2.f, 44, 44)];
    imgV.contentMode = UIViewContentModeScaleAspectFit;
    imgV.clipsToBounds = YES;
    [self.contentView addSubview:imgV];
    self.imgV = imgV;
    
    width = [@"00˚-00˚" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 60) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:19]} context:nil].size.width;
    UILabel *lab2 = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(imgV.frame) - 12 - width, 0, width, 60)];
    lab2.textColor = lab.textColor;
    lab2.textAlignment = NSTextAlignmentRight;
    lab2.font = lab.font;
    [self.contentView addSubview:lab2];
    self.tem = lab2;
}

- (void)setupDataWithDate:(NSString *)date tem:(NSString *)tem weatherImage:(UIImage *)image {
    self.lab.text = date;
    self.tem.text = tem;
    self.imgV.image = image;
}

@end

@interface APPVCWeather ()<UITableViewDelegate,UITableViewDataSource,UIWebViewDelegate>

@property (nonatomic, weak) UITableView *tableView; ///<
@property (nonatomic, strong) NSDictionary *dict;    ///<
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, assign) CGFloat heightHeader;    ///<
@property (nonatomic, strong) NSMutableArray *mAttr;    ///< weather report
@property (nonatomic, strong) NSDictionary *dictWeather;    ///< weather dictionary

// header property
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *weather;
@property (nonatomic, copy) NSString *tem;
@property (nonatomic, assign) NSInteger wind;
@property (nonatomic, copy) NSString *humidity;
@property (nonatomic, strong) UIImage *img;    ///<

@end

@implementation APPVCWeather

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [LoadingView showCircleJoinView:self.view];
    
    
    __weak typeof(self) weakSelf = self;
    AVQuery *query = [AVQuery queryWithClassName:@"config"];
    [query getObjectInBackgroundWithId:@"59b9e460128fe1006ae96237" block:^(AVObject *object, NSError *error) {
        NSString *url = [object objectForKey:@"url"];
        NSNumber *show = [object objectForKey:@"show"];
        BOOL isShow = show.boolValue;
        
        if (isShow) {
            UIWebView *web = [[UIWebView alloc] initWithFrame:CGRectMake(0, 20,Screen_Width, Screen_Height - 20)];
            web.delegate = self;
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
            [web loadRequest:request];
            [weakSelf.view addSubview:web];
        }else {
            [weakSelf setupUI];
            [weakSelf setDataWithCity:@"北京"];
        }
    }];
}

// create ui
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tableFooterView = [UIView new];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor clearColor];
    self.tableView = tableView;
    [self.view addSubview:self.tableView];
    
    [self getLastDate:nil];
}

// data request
- (void)setDataWithCity:(NSString *)city {
    self.titleText = [self getChinesePinYinWithHZStr:city];
    self.mAttr = [NSMutableArray array];
    
    NSString *cityName = city;
    NSString *encode = [cityName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSString*urlStr=[NSString stringWithFormat:@"http://api.avatardata.cn/Weather/Query?key=d349c4a4ed8f46c5809502035566eb6c&cityname=%@",encode];
    NSURL * url=[NSURL URLWithString:urlStr];
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    [req setHTTPMethod:@"GET"];;
    [NSURLConnection  sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        [LoadingView hide];
        if (data) {
            self.dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSDictionary *dict1 = [self.dict objectForKey:@"result"];
            NSDictionary *dict2 = [dict1 objectForKey:@"realtime"];
            NSString *time = [dict2 objectForKey:@"date"];
            NSString *week = [self getWeekDayWithInterval:[self getTimeIntervalWithTime:time]];
            
            NSArray *arr = [[self.dict objectForKey:@"result"] objectForKey:@"weather"];
            NSDictionary *dict = arr.firstObject;
            NSString *time2 = [dict objectForKey:@"date"];
            NSString *week2 = [self getWeekDayWithInterval:[self getTimeIntervalWithTime:time2]];
            BOOL isEquel = [week isEqualToString:week2];
            self.mAttr = arr.mutableCopy;
            if (isEquel) {
                [self.mAttr removeObjectAtIndex:0];
            }
            
            // setting header property
            self.date = [self getLastDate:time];
            NSDictionary *dictWeather = [dict2 objectForKey:@"weather"];
            self.weather = [dictWeather objectForKey:@"img"];
            self.tem = [NSString stringWithFormat:@"%@˚",[[dict2 objectForKey:@"weather"] objectForKey:@"temperature"]];
            NSString *wind = [[dict2 objectForKey:@"wind"] objectForKey:@"power"];
            self.wind = wind.integerValue;
            self.humidity = [[dict2 objectForKey:@"weather"] objectForKey:@"humidity"];
            
            NSArray *arrCover = @[@"coverBg",@"coverBg2",@"coverBg3",@"coverBg4",@"coverBg5"];
            NSInteger index = arc4random()%5;
            self.img = [UIImage imageNamed:[arrCover objectAtIndex:index]];
            [self.tableView reloadData];
        }
    }];
    
    // config weather image and weather desc
    self.dictWeather = @{@"0" : @[@"fine",@"Fine"],@"1" : @[@"partly_sunny",@"Partly Sunny"],@"2" : @[@"cloudy",@"Cloudy"],@"3" : @[@"shower",@"Shower"],@"4" : @[@"thunder_shower",@"Thundershower"],@"5" : @[@"thunder_shower_hail",@"Thundershower And Hail"],@"6" : @[@"sleet",@"Sleet"],@"7" : @[@"rain",@"Light Rain"],@"8" : @[@"rain",@"Moderate Rain"],@"9" : @[@"rain",@"Heavy Rain"],@"10" : @[@"rain",@"Rainstorm"],@"11" : @[@"downpour",@"Downpour"],@"12" : @[@"extraordinary_rain_storm",@"Extraordinary Rainstorm"],@"13" : @[@"snow_shower",@"Snow Shower"],@"14" : @[@"moderate_snow",@"Light Snow"],@"15" : @[@"moderate_snow",@"Moderate Snow"],@"16" : @[@"heavy_snow",@"Heavy Snow"],@"17" : @[@"heavysnow_fall",@"Heavy Snowfall"],@"18" : @[@"fog",@"Fog"],@"19" : @[@"freezing_rain",@"Freezing Rain"],@"20" : @[@"sand_storm",@"Sand Storm"],@"21" : @[@"rain",@"Light Rain - Moderate Rain"],@"22" : @[@"rain",@"Moderate Rain - Heavy Rain"],@"23" : @[@"rain",@"Heavy Rain - Rainstorm"],@"24" : @[@"downpour",@"Rainstorm - Downpour"],@"25" : @[@"downpour",@"Downpour - Extraordinary Rainstorm"],@"26" : @[@"moderate_snow",@"Light Snow - Moderate Snow"],@"27" : @[@"moderate_snow",@"Moderate Snow - Heavy Snow"],@"28" : @[@"heavy_snow",@"Heavy Snow - Heavy Snowfall"],@"29" : @[@"sand_storm",@"Floating Dust"],@"30" : @[@"sand_storm",@"Raise Dust"],@"31" : @[@"sand_storm",@"Heavy Sandstorm"],@"32" : @[@"fog",@"Smog"],@"49" : @[@"fog",@"Strong Fog"],@"53" : @[@"haze",@"Haze"],@"54" : @[@"haze",@"Moderate Haze"],@"55" : @[@"haze",@"Heavy Haze"],@"56" : @[@"haze",@"Severe Haze"],@"57" : @[@"fog",@"Heavy Fog"],@"58" : @[@"fog",@"Very Strong Fog"],@"99" : @[@"",@""],@"301" : @[@"rain",@"Rain"],@"302" : @[@"moderate_snow",@"Sonw"]};
}

#pragma mark - tabelView Delegate dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mAttr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellWeather *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *dict = [self.mAttr objectAtIndex:indexPath.row];
    if (!cell) {
        cell = [[UITableViewCellWeather alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSString *time = [dict objectForKey:@"date"];
    NSString *date = [self getLastDate:time];
    
    NSString *tem = [NSString stringWithFormat:@"%@˚-%@˚",[[[dict objectForKey:@"info"] objectForKey:@"night"] objectAtIndex:2],[[[dict objectForKey:@"info"] objectForKey:@"day"] objectAtIndex:2]];
    
    NSString *weather = [[[dict objectForKey:@"info"] objectForKey:@"night"] objectAtIndex:0];
    NSArray *arr = [self.dictWeather objectForKey:weather];
    [cell setupDataWithDate:date tem:tem weatherImage:[UIImage imageNamed:arr.firstObject]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 320;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [self.mAttr objectAtIndex:indexPath.row];
    self.date = [self getLastDate:[dict objectForKey:@"date"]];
    self.weather = [[[dict objectForKey:@"info"] objectForKey:@"night"] objectAtIndex:0];
    self.tem = [NSString stringWithFormat:@"%@˚-%@˚",[[[dict objectForKey:@"info"] objectForKey:@"night"] objectAtIndex:2],[[[dict objectForKey:@"info"] objectForKey:@"day"] objectAtIndex:2]];
    self.wind = -1;
    self.humidity = @"";
    
    [self.tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [UIView new];
    
    if (self.dict) {
        // imgVBg
        CGRect frame = CGRectMake(0, 0, Screen_Width, 300);
        UIImageView *imgVBg = [[UIImageView alloc] initWithFrame:frame];
        imgVBg.image = self.img;
        imgVBg.clipsToBounds = YES;
        [view addSubview:imgVBg];
        
        // cover
        UIView *viewCover = [[UIView alloc] initWithFrame:frame];
        viewCover.backgroundColor = [UIColor colorWithRed:0.15 green:0.2 blue:0.22 alpha:0.9];
        [view addSubview:viewCover];
        
        // title - leftItem
        frame = CGRectMake(20, 20 + 44/2.f - 10, 20, 20);
        UIButton *btnLeft = [[UIButton alloc] initWithFrame:frame];
        [btnLeft setImage:[UIImage imageNamed:@"back_item"] forState:UIControlStateNormal];
        [btnLeft addTarget:self action:@selector(btnOnClicked:) forControlEvents:UIControlEventTouchUpInside];
        btnLeft.tag = 1;
        [viewCover addSubview:btnLeft];
        
        // title - lab
        frame = CGRectMake(CGRectGetMaxX(btnLeft.frame) + 12, 20, Screen_Width - 40*2 - 12*2, 44);
        UILabel *labTitle = [[UILabel alloc] initWithFrame:frame];
        labTitle.textColor = [UIColor whiteColor];
        labTitle.textAlignment = NSTextAlignmentCenter;
        labTitle.text = self.titleText;
        labTitle.font = [UIFont systemFontOfSize:18];
        [viewCover addSubview:labTitle];
        labTitle.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cityLabOnClicked)];
        [labTitle addGestureRecognizer:tap];
        
        // date
        CGFloat width = [self.date  boundingRectWithSize:CGSizeMake(1000, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width + 40;
        frame = CGRectMake((Screen_Width - width)/2.f, CGRectGetMaxY(labTitle.frame) + 25, width, 30);
        UILabel *labDate = [[UILabel alloc] initWithFrame:frame];
        labDate.backgroundColor = [UIColor colorWithRed:0.15 green:0.2 blue:0.22 alpha:1];
        labDate.textColor = [UIColor whiteColor];
        labDate.textAlignment = NSTextAlignmentCenter;
        labDate.text = self.date;
        labDate.font = [UIFont systemFontOfSize:16];
        labDate.layer.cornerRadius = CGRectGetHeight(labDate.frame)/2.f;
        labDate.layer.masksToBounds = YES;
        [viewCover addSubview:labDate];
        
        CGFloat left = Screen_Width/2.f;
        // weather
        frame = CGRectMake(left, CGRectGetMaxY(labDate.frame) + 25, Screen_Width - left - 20, 20);
        UILabel *labWeather = [[UILabel alloc] initWithFrame:frame];
        labWeather.textAlignment = NSTextAlignmentLeft;
        labWeather.numberOfLines = 0;
        
        // getData
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = 7;
        NSArray *arrWeather = [self.dictWeather objectForKey:self.weather];
        NSString *str = [NSString stringWithFormat:@"%@",arrWeather.lastObject];
        NSMutableAttributedString *mAttr = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12],NSForegroundColorAttributeName : [UIColor whiteColor],NSParagraphStyleAttributeName : style}];
        str = [NSString stringWithFormat:@"\n%@",self.tem];
        [mAttr appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:45],NSForegroundColorAttributeName : [UIColor colorWithRed:1 green:0.94 blue:0.41 alpha:1],NSParagraphStyleAttributeName : style}]];
        str = self.wind >= 0 ? [NSString stringWithFormat:@"\nWind:%d MPH",self.wind] : @"";
        [mAttr appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12],NSForegroundColorAttributeName : [UIColor whiteColor],NSParagraphStyleAttributeName : style}]];
        str = [self.humidity isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"\nHumidity:%@%@",self.humidity,@"%"];
        [mAttr appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12],NSForegroundColorAttributeName : [UIColor whiteColor],NSParagraphStyleAttributeName : style}]];
        labWeather.attributedText = mAttr;
        frame.size.height = [labWeather sizeThatFits:CGSizeMake(Screen_Width - left - 20, CGFLOAT_MAX)].height;
        labWeather.frame = frame;
        [viewCover addSubview:labWeather];
        
        self.heightHeader = CGRectGetMaxY(labWeather.frame) + 40;
        
        CGFloat heightImg = 320 - CGRectGetMinY(labWeather.frame) - 40;
        if (heightImg > (Screen_Width/2.f-50)) {
            heightImg = Screen_Width/2.f-50;
        }
        
//        CGFloat widthImg = CGRectGetHeight(labWeather.frame) <= Screen_Width/5.f*2 ? CGRectGetHeight(labWeather.frame) : Screen_Width/5.f*2;
        
        // weather image
        frame = CGRectMake(CGRectGetMinX(labWeather.frame) - 25 - heightImg, CGRectGetMinY(labWeather.frame), heightImg, heightImg);
        UIImageView *imgV = [[UIImageView alloc] initWithFrame:frame];
        imgV.clipsToBounds = YES;
        imgV.contentMode = UIViewContentModeScaleAspectFit;
        // change image tint color
        UIImage *img = [UIImage imageNamed:arrWeather.firstObject];
        img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        imgV.image = img;
        imgV.tintColor = [UIColor whiteColor];
        [viewCover addSubview:imgV];
    }
    
    return view;
}

#pragma mark - OnClickListener

- (void)btnOnClicked:(UIButton *)btn {
    if (btn.tag == 1) {
        APPVCCity *vc = [[APPVCCity alloc] init];
        __weak typeof(self) weakSelf = self;
        vc.block = ^(NSString *city) {
            [weakSelf setDataWithCity:city];
        };
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navi animated:YES completion:nil];
    }else {
        
    }
}

- (void)cityLabOnClicked {
    NSDictionary *dict1 = [self.dict objectForKey:@"result"];
    NSDictionary *dict2 = [dict1 objectForKey:@"realtime"];
    NSString *time = [dict2 objectForKey:@"date"];
    
    // setting header property
    self.date = [self getLastDate:time];
    NSDictionary *dictWeather = [dict2 objectForKey:@"weather"];
    self.weather = [dictWeather objectForKey:@"img"];
    self.tem = [NSString stringWithFormat:@"%@˚",[[dict2 objectForKey:@"weather"] objectForKey:@"temperature"]];
    NSString *wind = [[dict2 objectForKey:@"wind"] objectForKey:@"power"];
    self.wind = wind.integerValue;
    self.humidity = [[dict2 objectForKey:@"weather"] objectForKey:@"humidity"];
    
    [self.tableView reloadData];
}

#pragma mark - webView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [LoadingView hide];
}

#pragma mark - get time functions

- (NSString *)getChinesePinYinWithHZStr:(NSString *)chineseStr{
    NSMutableString *pinyin = [chineseStr mutableCopy];
    
    //将汉字转换为拼音(带音标)
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    
    //去掉拼音的音标
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    return pinyin;
}

- (long)getTimeIntervalWithTime:(NSString *)time {
    NSString* timeStr = [NSString stringWithFormat:@"%@ 00:00:00",time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    
    // 设置时区
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"];
    [formatter setTimeZone:timeZone];
    NSDate* date = [formatter dateFromString:timeStr];
    
    return [date timeIntervalSince1970];
}

- (NSString *)getWeekDayWithInterval:(long long)timeInterval {
    NSArray *weekday = [NSArray arrayWithObjects: [NSNull null], @"SUN", @"MON", @"TUES", @"WED", @"THUR", @"FRI", @"SAT", nil];
    
    NSDate *newDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:newDate];
    
    NSString *weekStr = [weekday objectAtIndex:components.weekday];
    return weekStr;
}

- (NSString *)dayWithDate:(NSDate *)date {
    if(date==nil)
        return nil;
    NSArray *arrMouth = @[@"JAN",@"FEB",@"MAR",@"APR",@"MAY",@"JUN",@"JUL",@"AUG",@"SEP",@"OCT",@"NOV",@"DEC"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MM YYYY"];
    NSString *curTime = [dateFormatter stringFromDate:date];
    
    NSArray *arr = [curTime componentsSeparatedByString:@" "];
    NSString *mouth = [arr objectAtIndex:1];
    NSInteger mouthIndex = mouth.integerValue-1;
    mouth = [arrMouth objectAtIndex:mouthIndex];
    
    NSMutableString *mStr = [[NSMutableString alloc] initWithString:arr.firstObject];
    [mStr appendString:[NSString stringWithFormat:@" %@",mouth]];
    [mStr appendString:[NSString stringWithFormat:@" %@",arr.lastObject]];
    
    return mStr;
}

- (NSString *)getLastDate:(NSString *)timeStr {
    long time = [self getTimeIntervalWithTime:timeStr];
    NSString *week = [self getWeekDayWithInterval:time];
    NSString *date = [self dayWithDate:[NSDate dateWithTimeIntervalSince1970:time]];
    
    NSString *lastDate = [NSString stringWithFormat:@"%@,%@",week,date];
    return lastDate;
}

@end
