//
//  userInfo.m
//  ShardLocation
//
//  Created by yons on 16/9/1.
//  Copyright © 2016年 yons. All rights reserved.
//

#import "userInfo.h"

@implementation userInfo

static userInfo* _userInfo=nil;

+(instancetype)sharedUserInfo{
    
    if (_userInfo==nil) {
        _userInfo=[[userInfo alloc]init];
    }
    
    return _userInfo;
}
@end
