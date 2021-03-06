//
//  MarkerView.h
//  Around Me
//
//  Created by jdistler on 11.02.13.
//  Copyright (c) 2013 Jean-Pierre Distler. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ARGeoCoordinate;
@protocol MarkerViewDelegate;

@interface MarkerView : UIView

@property (nonatomic, strong) ARGeoCoordinate *coordinate;
@property (nonatomic, weak) id <MarkerViewDelegate> delegate;
@property (nonatomic, strong) NSString *distance;
@property (nonatomic, strong) UILabel *lblDistance;
- (id)initWithCoordinate:(ARGeoCoordinate *)coordinate delegate:(id<MarkerViewDelegate>)delegate;
- (id)initWithTitle:(NSString *)titleString distnace:(NSString *)distance;

@end

@protocol MarkerViewDelegate <NSObject>

- (void)didTouchMarkerView:(MarkerView *)markerView;


@end
