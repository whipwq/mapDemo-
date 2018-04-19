//
//  MylocationViewController.m
//  AmapLocation
//
//  Created by yons on 16/8/31.
//  Copyright © 2016年 yons. All rights reserved.
//

#import "MylocationViewController.h"
#import "PoiInfoTableViewCell.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "RouteSearchViewController.h"
#import "userInfo.h"
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define UTBMKSPAN 0.002
@interface MylocationViewController ()<AMapLocationManagerDelegate,MAMapViewDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate>
@property(nonatomic,strong)MAMapView* mapView;
@property(nonatomic,strong)AMapLocationManager* locationManager;
@property(nonatomic,strong)MAUserLocation* userLocation;
@property(nonatomic,strong)AMapSearchAPI* search;
@property(nonatomic,strong)UITableView* poiInfoTabVew;
@property(nonatomic,assign)BOOL cellSelt;
@property(nonatomic,strong)UIImageView* flagImageView;
//遮盖mapView的view
@property(nonatomic,strong)UIView* searchView;
@property(nonatomic,strong)UISearchBar* searchBar;
//检索结果数组
@property(nonatomic,strong)NSMutableArray* poiInfosArray;
@property(nonatomic,strong)UIButton* searchBtn;
@property(nonatomic,strong)UITableView* searchResultTabView;
//Poi检索结果数组
@property(nonatomic,strong)NSMutableArray*searchResultArray;
@property(nonatomic,strong)UIBarButtonItem* routeBtnItem;
//是否为poi检索
@property(nonatomic,assign)BOOL isPoiSearch;

@end

@implementation MylocationViewController

//懒加载小红旗视图
-(UIImageView*)flagImageView{
    
    if (_flagImageView==nil) {
        
        _flagImageView       = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"flag"]];
        _flagImageView.frame = CGRectMake(self.view.center.x-15,self.view.center.y*0.5+32+40,40,30);
        
    }
    
    return _flagImageView;
}

-(UIButton*)searchBtn{
    
    if (_searchBtn== nil) {
        _searchBtn       = [UIButton buttonWithType:UIButtonTypeCustom];
        _searchBtn.frame = CGRectMake(0, 64,SCREENWIDTH, 40);
        
    }
    return _searchBtn;
}

-(UISearchBar*)searchBar{
    
    if (_searchBar == nil) {
        _searchBar              = [UISearchBar new];
        _searchBar.frame        = CGRectMake(0, 20, SCREENWIDTH-60, 44);
        _searchBar.delegate     = self;
        _searchBar.placeholder  = @"请输入你要搜索的内容";
        
    }
    
    return _searchBar;
}


-(UIView*)searchView{
    
    if (_searchView == nil) {
        _searchView                 = [UIView new];
        _searchView.frame           = self.view.bounds;
        _searchView.hidden          = YES;
        _searchView.backgroundColor =[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        
    }
    return _searchView;
}

-(UITableView*)searchResultTabView{
    
    if (_searchResultTabView == nil) {
        _searchResultTabView            = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, SCREENWIDTH, SCREENHEIGHT-64) style:UITableViewStylePlain];
        _searchResultTabView.dataSource = self;
        _searchResultTabView.delegate   = self;
        _searchResultTabView.hidden     = YES;
    }
    
    return _searchResultTabView;
}


// 懒加载mapView
-(MAMapView*)mapView{
    
    if (_mapView==nil) {
        _mapView=[[MAMapView alloc]initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+64+40, self.view.frame.size.width,SCREENHEIGHT*0.5)];
        _mapView.mapType           = MAMapTypeStandard;
        _mapView.showsUserLocation = YES;
        _mapView.delegate          = self;
        _mapView.userTrackingMode  = MAUserTrackingModeFollow;
    }
    return _mapView;
}
// 懒加载locationManager
-(AMapLocationManager*)locationManager{
    
    if (_locationManager==nil) {
        _locationManager                 = [AMapLocationManager new];
        _locationManager.delegate        = self;
        _locationManager.distanceFilter  = 5;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return _locationManager;
}
// 懒加载search
-(AMapSearchAPI*)search{
    
    if (_search==nil) {
        _search=[AMapSearchAPI new];
        _search.delegate=self;
    }
    
    return _search;
}

// 懒加载反地理编码检索结果数组
-(NSMutableArray*)poiInfosArray{
    
    if (_poiInfosArray==nil) {
        
        _poiInfosArray=[NSMutableArray array];
    }
    
    return _poiInfosArray;
}
// 懒加载Poi检索结果数组
-(NSMutableArray*)searchResultArray{
    
    if (_searchResultArray==nil) {
        _searchResultArray=[NSMutableArray array];
    }
    return _searchResultArray;
}

// 懒加载tableView
-(UITableView*)poiInfoTabVew{
    
    if (_poiInfoTabVew==nil) {
        
        _poiInfoTabVew = [[UITableView alloc]initWithFrame:CGRectMake(self.view.frame.origin.x, SCREENHEIGHT*0.5+64+40, SCREENWIDTH, SCREENHEIGHT*0.5-40) style:UITableViewStylePlain];
        _poiInfoTabVew.delegate = self;
        _poiInfoTabVew.dataSource = self;
    }
    
    return _poiInfoTabVew;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title=@"我的位置";
    [self.searchBtn addTarget:self action:@selector(searchBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.searchBtn setBackgroundImage:[UIImage imageNamed:@"searbutton"] forState:UIControlStateNormal];
    [self.view addSubview:self.searchBtn];
    [self.view insertSubview:self.mapView atIndex:0];
    [self.view addSubview:self.flagImageView];
    [self.view addSubview:self.poiInfoTabVew];
    //注册自定义cell
    [self.poiInfoTabVew registerNib:[UINib nibWithNibName:@"PoiInfoTableViewCell" bundle:nil] forCellReuseIdentifier:@"poiInfo"];
    [self.searchResultTabView registerNib:[UINib nibWithNibName:@"PoiInfoTableViewCell" bundle:nil] forCellReuseIdentifier:@"poiInfo"];
    //假设用户ios>8.0,开始定位
    [self.locationManager startUpdatingLocation];
    [self.view addSubview:self.searchView];
    [self.searchBar showsCancelButton];
    [self.searchView addSubview:self.searchBar];
    [self setNavigationItems];
}

-(void)searchBtnClicked{
    
    self.searchView.hidden=NO;
    [self.searchBar becomeFirstResponder];
    UIButton* searchCancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    searchCancelBtn.frame = CGRectMake(SCREENWIDTH-50, 20, 40, 44);
    searchCancelBtn.titleLabel.font=[UIFont systemFontOfSize:16];
    [searchCancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [searchCancelBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [searchCancelBtn addTarget:self action:@selector(searchCanelBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.searchBar setTranslucent:YES];
    [self.searchView addSubview:self.searchResultTabView];
    [self.searchView addSubview:searchCancelBtn];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    
}

-(void)setNavigationItems{
    
  
    
    self.routeBtnItem = [[UIBarButtonItem alloc]initWithTitle:@"路径规划" style:UIBarButtonItemStyleDone target:self action:@selector(routeBtnClicked)];
    
    self.navigationItem.leftBarButtonItem=self.routeBtnItem;
    
    
    
    
}

-(void)routeBtnClicked{
    
    RouteSearchViewController* routeVc = [RouteSearchViewController new];
    
    [self.navigationController pushViewController:routeVc animated:YES];
    
    
}


-(void)searchCanelBtnClicked{
    
    self.searchView.hidden=YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchBar resignFirstResponder];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

//成功定位
-(void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    [userInfo sharedUserInfo].latitude  = location.coordinate.latitude;
    [userInfo sharedUserInfo].longitude = location.coordinate.longitude;
    //地图移动到用户位置区域，触发代理方法regionDidChanged，在代理方法中做检索功能
    MACoordinateRegion region = MACoordinateRegionMake(location.coordinate, MACoordinateSpanMake(UTBMKSPAN, UTBMKSPAN));
    [self.mapView setRegion:region animated:YES];
    
    //开始反地理编码检索
    
    //[self startGeocodesearchWith:location.coordinate];
    
}
-(void)startGeocodesearchWith:(CLLocationCoordinate2D )coordinate{
    
    //反地理编码检索
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    //用户位置
    request.location = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    //按距离由近到远排序
    request.sortrule = 0;
    
    request.page = 1;
    request.offset = 20;
    //是否返回拓展信息
    request.requireExtension = YES;
    
    [self.search AMapPOIAroundSearch:request];

    
    
}

//发起poi检索
-(void)startPoisearchWith:(NSString*)keyWord{
    
    
    AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
    
    request.keywords            = keyWord;
    request.city                = @"成都";
    request.cityLimit           = YES;
    request.requireSubPOIs      = YES;
    self.isPoiSearch            = YES;
    [self.search AMapPOIKeywordsSearch:request];
    
    
    
    
}




// 反地理编码检索的结果数组
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0)
    {
        return;
    }
    
    if (self.isPoiSearch) {
        [self.searchResultArray removeAllObjects];
        [self.searchResultArray addObjectsFromArray:response.pois];
        [self.searchResultTabView reloadData];
        self.isPoiSearch = NO;
    }else{
    // 移除上一次所有检索结果
    [self.poiInfosArray removeAllObjects];
    // 保存本次检索的结果
    [self.poiInfosArray addObjectsFromArray:response.pois];
    // 刷新tableView
    [self.poiInfoTabVew reloadData];
    }

}



#pragma mark tableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
   
    if (tableView==self.poiInfoTabVew) {
        return self.poiInfosArray.count;
    }else{
        return self.searchResultArray.count;
    }
    
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView==self.poiInfoTabVew){
        //复用自定义cell
        PoiInfoTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"poiInfo" forIndexPath:indexPath];
        
        //取出indexPath对应的模型
        AMapPOI*poiInfo = self.poiInfosArray[indexPath.row];
        cell.nameLabel.text = poiInfo.name;
        cell.addressLabel.text = poiInfo.address;
        
        return cell;
    }
    
    else{
        
        //复用自定义cell
        PoiInfoTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"poiInfo" forIndexPath:indexPath];
        AMapPOI*poiInfo=self.searchResultArray[indexPath.row];
        cell.nameLabel.text=poiInfo.name;
        cell.addressLabel.text=poiInfo.address;
        
        return cell;
    };
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    if (tableView==self.poiInfoTabVew) {
        // 设置为点中cell状态
        self.cellSelt=YES;
        [self moveToRegionWithModleArray:self.poiInfosArray WithIndexPath:indexPath];
        
    }
    else{
        
        self.searchView.hidden=YES;
        [self.searchBar resignFirstResponder];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self moveToRegionWithModleArray:self.searchResultArray WithIndexPath:indexPath];
        
    }
    
}

-(void)moveToRegionWithModleArray:(NSArray*)modelArray WithIndexPath:(NSIndexPath *)indexPath{
    
    // 设置为地图中心
    AMapPOI*poiInfo = modelArray[indexPath.row];
    MACoordinateRegion region = MACoordinateRegionMake(CLLocationCoordinate2DMake(poiInfo.location.latitude, poiInfo.location.longitude), MACoordinateSpanMake(UTBMKSPAN, UTBMKSPAN));
    [self.mapView setRegion:region animated:NO];
    
    // 移除所有大头针
    NSArray* array = [NSArray arrayWithArray:self.mapView.annotations];
    [self.mapView removeAnnotations:array];
    
    // 在选中位置，创建大头针
    MAPointAnnotation* annotation = [MAPointAnnotation new];
    annotation.coordinate = CLLocationCoordinate2DMake(poiInfo.location.latitude, poiInfo.location.longitude);
    annotation.title = poiInfo.name;
    [self.mapView addAnnotation:annotation];
    
}


//自定义大头针
-(MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation{
    
    
    // 判断如果是用户位置，大头针为系统蓝点样式
    if ([annotation isKindOfClass:[MAUserLocation class]]) {
        return nil;
    }
    
    
    static NSString *identifier = @"annotation";
    MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    //如果没有可复用，就创建；如果有，把标注对象和标注视图绑定(赋值属性)
    if (annotationView==nil) {
        
        annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        //显示弹出框
        annotationView.canShowCallout = YES;
        //修改颜色
        annotationView.pinColor = MAPinAnnotationColorRed;
       
    }

        annotationView.annotation = annotation;
    
    
    return annotationView;
}

-(void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    
    //判断是否为cell点中致使的本次方法触发，如果是则此方法不做任何处理
    if (self.cellSelt) {
        
        //把cellSlet置为NO;
        self.cellSelt=NO;
        
        return;
    }
    
    //不是点中cell触发的region的改变，而是拖动地图发生的region变化，就根据拖动地图后，mapView中心的经纬度，发起发地理编码检索，刷新tableView，展示拖动地图后，周围的PoiInfos;
    
    //小红旗动画
    [self flagAnoimated];
    
    //开始反地理编码检索
    [self startGeocodesearchWith:mapView.centerCoordinate];
    
}

//小红旗动画
-(void)flagAnoimated{
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        CGRect frame=CGRectMake(self.flagImageView.frame.origin.x, self.flagImageView.frame.origin.y-20, self.flagImageView.frame.size.width, self.flagImageView.frame.size.height);
        self.flagImageView.frame=frame;
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            CGRect frame=CGRectMake(self.flagImageView.frame.origin.x, self.flagImageView.frame.origin.y+20, self.flagImageView.frame.size.width, self.flagImageView.frame.size.height);
            self.flagImageView.frame=frame;
            
        } completion:nil];
    }];
    
}

//点中搜索
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    self.searchResultTabView.hidden=NO;
    [self.searchBar resignFirstResponder];
    [self startPoisearchWith:self.searchBar.text];
    
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [self.searchBar resignFirstResponder];
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
