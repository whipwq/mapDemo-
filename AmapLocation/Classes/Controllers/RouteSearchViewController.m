//
//  RouteSearchViewController.m
//  AmapLocation
//
//  Created by yons on 16/9/5.
//  Copyright © 2016年 yons. All rights reserved.
//

#import "RouteSearchViewController.h"
#import "PoiInfoTableViewCell.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "userInfo.h"
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define UTBMKSPAN 0.002
@interface RouteSearchViewController ()<MAMapViewDelegate,AMapLocationManagerDelegate,AMapSearchDelegate,UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *startTexfiled;
@property (weak, nonatomic) IBOutlet UITextField *endTexfiled;
@property (weak, nonatomic) IBOutlet UIButton *moveStyle;
@property (nonatomic,strong) MAMapView* mapView;
@property (nonatomic,strong) AMapSearchAPI* search;
@property (nonatomic,strong) UIBarButtonItem* searchButtonItem;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic,retain) NSArray *pathPolylines;
@property (nonatomic,retain) UILongPressGestureRecognizer *longPressGesture;//长按手势
@property (nonatomic,retain) MAPointAnnotation *destinationPoint;//目标点
@end

@implementation RouteSearchViewController

- (NSArray *)pathPolylines
{
    if (!_pathPolylines) {
        _pathPolylines = [NSArray array];
    }
    return _pathPolylines;
}
// 懒加载mapView
-(MAMapView*)mapView{
    
    if (_mapView==nil) {
        _mapView=[[MAMapView alloc]initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+104, self.view.frame.size.width, self.view.frame.size.height-104)];
        _mapView.mapType           = MAMapTypeStandard;
        _mapView.showsUserLocation = YES;
        _mapView.delegate          = self;
        _mapView.userTrackingMode  = MAUserTrackingModeFollow;
    }
    return _mapView;
}

// 懒加载search
-(AMapSearchAPI*)search{
    
    if (_search==nil) {
        _search=[AMapSearchAPI new];
        _search.delegate=self;
    }
    
    return _search;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.mapView];
    [self moveToUserRegion];
    [self setNavigationItems];
    [self addGesture];
}

-(void)setNavigationItems{
    
    
    self.searchButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"查询" style:UIBarButtonItemStyleDone target:self action:@selector(searchBtnClicked)];
    
    self.navigationItem.rightBarButtonItem=self.searchButtonItem;
 
    
}

//添加手势
- (void)addGesture
{
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.delegate = self;
    [self.mapView addGestureRecognizer:self.longPressGesture];
}


//长按手势相应
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gesture locationInView:_mapView];
        NSLog(@"press on (%f, %f)", p.x, p.y);
    }
    CLLocationCoordinate2D coordinate = [_mapView convertPoint:[gesture locationInView:_mapView] toCoordinateFromView:_mapView];
    
    // 添加标注
    if (_destinationPoint != nil) {
        // 清理
        [_mapView removeAnnotation:_destinationPoint];
        _destinationPoint = nil;
    }
    _destinationPoint = [[MAPointAnnotation alloc] init];
    _destinationPoint.coordinate = coordinate;
    _destinationPoint.title = @"目标点";
    [_mapView addAnnotation:_destinationPoint];
    
}


-(void)searchBtnClicked{
    
    
    [self searchRoutePlanningBus];
    
}


- (void)moveToUserRegion{
    
    //地图移动到用户位置区域，触发代理方法regionDidChanged，在代理方法中做检索功能
    MACoordinateRegion region = MACoordinateRegionMake(CLLocationCoordinate2DMake([userInfo sharedUserInfo].latitude, [userInfo sharedUserInfo].longitude), MACoordinateSpanMake(UTBMKSPAN, UTBMKSPAN));
    [self.mapView setRegion:region animated:YES];
    
}

- (void)searchRoutePlanningBus
{
//    AMapTransitRouteSearchRequest *request = [[AMapTransitRouteSearchRequest alloc] init];
//
//    //设置起点，我选择了当前位置，mapView有这个属性
//    request.origin = [AMapGeoPoint locationWithLatitude:[userInfo sharedUserInfo].latitude longitude:[userInfo sharedUserInfo].longitude];
//    //设置终点
//    request.destination =[AMapGeoPoint locationWithLatitude:[userInfo sharedUserInfo].latitude+0.01 longitude:[userInfo sharedUserInfo].longitude+0.02];
//    
//    //    request.strategy = 2;//距离优先
//    //    request.requireExtension = YES;
//    
//    //发起路径搜索，发起后会执行代理方法
//    //这里使用的是步行路径
//    [self.search AMapTransitRouteSearch: request];
    
    
    //构造AMapDrivingRouteSearchRequest对象，设置驾车路径规划请求参数
    AMapWalkingRouteSearchRequest *request = [[AMapWalkingRouteSearchRequest alloc] init];
    NSLog(@"%f,%f",[userInfo sharedUserInfo].latitude,[userInfo sharedUserInfo].longitude);
        request.origin = [AMapGeoPoint locationWithLatitude:[userInfo sharedUserInfo].latitude longitude:[userInfo sharedUserInfo].longitude];
        request.destination = [AMapGeoPoint locationWithLatitude:self.destinationPoint.coordinate.latitude longitude:self.destinationPoint.coordinate.longitude];
    
    
//    request.origin = [AMapGeoPoint locationWithLatitude:[userInfo sharedUserInfo].latitude longitude:[userInfo sharedUserInfo].longitude];
//    
//    request.destination = [AMapGeoPoint locationWithLatitude:[userInfo sharedUserInfo].latitude+5 longitude:[userInfo sharedUserInfo].latitude+5];
    
    
    //    request.strategy = 2;//距离优先
    //    request.requireExtension = YES;
    
    //发起路径搜索
    [self.search AMapWalkingRouteSearch: request];
    
    
    //    [self drawPolygon];

    
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}


- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response{
    
    
    if(response.route == nil)
    {
        return;
    }
    
    //通过AMapNavigationSearchResponse对象处理搜索结果
    NSString *route = [NSString stringWithFormat:@"Navi: %@", response.route];
    NSLog(@"%@", route);
    AMapPath *path = response.route.paths[0]; //选择一条路径
    AMapStep *step = path.steps[0]; //这个路径上的导航路段数组
    NSLog(@"%@",step.polyline);   //此路段坐标点字符串
    
    if (response.count > 0)
    {
        //移除地图原本的遮盖
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
        
        // 只显示第⼀条 规划的路径
        _pathPolylines = [self polylinesForPath:response.route.paths[0]];
        NSLog(@"%@",response.route.paths[0]);
        //添加新的遮盖，然后会触发代理方法进行绘制
        [_mapView addOverlays:_pathPolylines];
    }
    
    
}


- (NSArray *)polylinesForPath:(AMapPath *)path
{
    if (path == nil || path.steps.count == 0)
    {
        return nil;
    }
    NSMutableArray *polylines = [NSMutableArray array];
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL *stop) {
        NSUInteger count = 0;
        CLLocationCoordinate2D *coordinates = [self coordinatesForString:step.polyline
                                                         coordinateCount:&count
                                                              parseToken:@";"];
        
        
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
        
        //          MAPolygon *polygon = [MAPolygon polygonWithCoordinates:coordinates count:count];
        
        [polylines addObject:polyline];
        free(coordinates), coordinates = NULL;
    }];
    return polylines;
}
//解析经纬度
- (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token
{
    if (string == nil)
    {
        return NULL;
    }
    
    if (token == nil)
    {
        token = @",";
    }
    
    NSString *str = @"";
    if (![token isEqualToString:@","])
    {
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    }
    
    else
    {
        str = [NSString stringWithString:string];
    }
    
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL)
    {
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D*)malloc(count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < count; i++)
    {
        coordinates[i].longitude = [[components objectAtIndex:2 * i]     doubleValue];
        coordinates[i].latitude  = [[components objectAtIndex:2 * i + 1] doubleValue];
    }
    
    
    return coordinates;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    /* 自定义定位精度对应的MACircleView. */
    
    //画路线
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        //初始化一个路线类型的view
        MAPolylineRenderer *polygonView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        //设置线宽颜色等
        polygonView.lineWidth = 3.f;
        polygonView.strokeColor = [UIColor colorWithRed:0.015 green:0.658 blue:0.986 alpha:1.000];
        polygonView.fillColor = [UIColor colorWithRed:0.940 green:0.771 blue:0.143 alpha:0.800];
        polygonView.lineJoin = kCGLineJoinRound;//连接类型
        //返回view，就进行了添加
        return polygonView;
    }
    return nil;
    
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
