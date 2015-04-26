//
//  MarkerView.m
//  Around Me
//
//  Created by jdistler on 11.02.13.
//  Copyright (c) 2013 Jean-Pierre Distler. All rights reserved.
//

#import "MarkerView.h"

#import "ARGeoCoordinate.h"

const float kWidth = 150.0f;
const float kHeight = 100.0f;

@interface MarkerView ()


@end


@implementation MarkerView



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithTitle:(NSString *)titleString distnace:(NSString *)distance{
    if((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kWidth, kHeight)])) {

        
        [self setUserInteractionEnabled:YES];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.image = [UIImage imageNamed:@"pin"];
        [self addSubview:imageView];
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(31.0f, 0.0f, 70.0f, 20.0f)];
        [title setTextColor:[UIColor whiteColor]];
        [title setTextAlignment:NSTextAlignmentCenter];
        [title setText:titleString];
        [title sizeToFit];
        [title setBackgroundColor:[UIColor clearColor]];
        
        _lblDistance = [[UILabel alloc] initWithFrame:CGRectMake(31.0f, 21.0f, 70.0f, 20.0f)];
        [_lblDistance setBackgroundColor:[UIColor clearColor]];
        [_lblDistance setTextColor:[UIColor whiteColor]];
        [_lblDistance setTextAlignment:NSTextAlignmentCenter];
        [_lblDistance setText:distance];
        [_lblDistance sizeToFit];
        
        self.distance = distance;
        [self addSubview:title];
        [self addSubview:_lblDistance];
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:0.3f]
         ];
    }
    
    return self;
}

- (id)initWithCoordinate:(ARGeoCoordinate *)coordinate delegate:(id<MarkerViewDelegate>)delegate {
	if((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kWidth, kHeight)])) {
		_coordinate = coordinate;
		_delegate = delegate;
		
		[self setUserInteractionEnabled:YES];
		
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kWidth, 40.0f)];
		[title setBackgroundColor:[UIColor colorWithWhite:0.3f alpha:0.7f]];
		[title setTextColor:[UIColor blackColor]];
		[title setTextAlignment:NSTextAlignmentCenter];
		[title setText:[coordinate title]];
		[title sizeToFit];
		
		_lblDistance = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 45.0f, kWidth, 40.0f)];
		
		[_lblDistance setBackgroundColor:[UIColor colorWithWhite:0.3f alpha:0.7f]];
		[_lblDistance setTextColor:[UIColor whiteColor]];
		[_lblDistance setTextAlignment:NSTextAlignmentCenter];
		[_lblDistance setText:[NSString stringWithFormat:@"%.2f km", [coordinate distanceFromOrigin] / 1000.0f]];
		[_lblDistance sizeToFit];
		
		[self addSubview:title];
		[self addSubview:_lblDistance];
		
		[self setBackgroundColor:[UIColor clearColor]];
	}

	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
    [[self lblDistance] setText:self.distance];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if(_delegate && [_delegate conformsToProtocol:@protocol(MarkerViewDelegate)]) {
		[_delegate didTouchMarkerView:self];
	}
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    CGRect theFrame = CGRectMake(0, 0, kWidth, kHeight);
    
	return CGRectContainsPoint(theFrame, point);
}

@end
