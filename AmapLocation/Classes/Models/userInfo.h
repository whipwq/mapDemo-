//
//  userInfo.h
//  ShardLocation
//
//  Created by yons on 16/9/1.
//  Copyright © 2016年 yons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface userInfo : NSObject
@property(nonatomic,strong)UIImage*mapImage;
@property(nonatomic,assign)float latitude;
@property(nonatomic,assign)float longitude;
+(instancetype)sharedUserInfo;
@end
