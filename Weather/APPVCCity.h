//
//  APPVCCity.h
//  Weather
//
//  Created by 文得炙 on 2017/9/14.
//  Copyright © 2017年 crow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APPVCCity : UIViewController

@property (nonatomic, copy) void(^block)(NSString *city);

@end
