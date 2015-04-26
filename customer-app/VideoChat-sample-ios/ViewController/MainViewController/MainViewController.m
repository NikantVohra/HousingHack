//
//  MainViewController.m
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "AugmentedRealityController.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "PlacesLoader.h"
#import "Place.h"
#import "PlaceAnnotation.h"
#import "MarkerView.h"

#import <PubNub/PNImports.h>

NSString * const kNameKey = @"name";
NSString * const kReferenceKey = @"reference";
NSString * const kAddressKey = @"vicinity";
NSString * const kLatiudeKeypath = @"geometry.location.lat";
NSString * const kLongitudeKeypath = @"geometry.location.lng";

const int kInfoViewTag = 1001;

NSString * const kPhoneKey = @"formatted_phone_number";
NSString * const kWebsiteKey = @"website";


@interface MainViewController ()<CLLocationManagerDelegate,ARLocationDelegate, ARDelegate, ARMarkerDelegate, MarkerViewDelegate,PNDelegate>

@property (nonatomic, strong) NSMutableArray *geoLocations;
@property (nonatomic, strong) AugmentedRealityController *arController;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, strong) PNConfiguration *pubnubConfig;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) MarkerView *markerLabel;
@property (nonatomic, strong) MKUserLocation *userLocation;

@end

@implementation MainViewController

@synthesize opponentID;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.videoChat.useBackCamera = 1;
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    navBar.topItem.title = @"";
    callButton.hidden = YES;
    //[callButton setTitle:appDelegate.currentUser == 1 ? @"Call Client" : @"Call Client" forState:UIControlStateNormal];
    self.overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    self.overlayView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.overlayView];
    [self setUpPubnub];
    self.markerLabel = [[MarkerView alloc] initWithTitle:@"" distnace:@""];
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.overlayView addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.overlayView addGestureRecognizer:swiperight];
    
    UISwipeGestureRecognizer * swipetop=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipetop:)];
    swipetop.direction=UISwipeGestureRecognizerDirectionUp;
    [self.overlayView addGestureRecognizer:swipetop];
    
    UISwipeGestureRecognizer * swipedown=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedown:)];
    swipedown.direction=UISwipeGestureRecognizerDirectionDown;
    [self.overlayView addGestureRecognizer:swipedown];
}



-(void)swipeleft:(UISwipeGestureRecognizer*)gestureRecognizer
{
    NSString *message = [NSString stringWithFormat:@"{\"position\":\"%@\"}",@"left"];
    PNChannel *ch = [PNChannel channelWithName:@"HousingPosition" shouldObservePresence:YES
                     ];
    
    [PubNub sendMessage:message
              toChannel:ch];
}

-(void)swiperight:(UISwipeGestureRecognizer*)gestureRecognizer
{
    NSString *message = [NSString stringWithFormat:@"{\"position\":\"%@\"}",@"right"];
    PNChannel *ch = [PNChannel channelWithName:@"HousingPosition" shouldObservePresence:YES
                     ];
    
    [PubNub sendMessage:message
              toChannel:ch];
}

-(void)swipetop:(UISwipeGestureRecognizer*)gestureRecognizer
{
    NSString *message = [NSString stringWithFormat:@"{\"position\":\"%@\"}",@"up"];
    PNChannel *ch = [PNChannel channelWithName:@"HousingPosition" shouldObservePresence:YES
                     ];
    
    [PubNub sendMessage:message
              toChannel:ch];
}


-(void)swipedown:(UISwipeGestureRecognizer*)gestureRecognizer
{
    NSString *message = [NSString stringWithFormat:@"{\"position\":\"%@\"}",@"down"];
    PNChannel *ch = [PNChannel channelWithName:@"HousingPosition" shouldObservePresence:YES
                     ];
    
    [PubNub sendMessage:message
              toChannel:ch];
}


- (IBAction)videoFrontOrBack:(id)sender {
    [self videoOutputDidChange];
}

-(void)setUpPubnub {
    [PubNub setDelegate:self];
    NSLog(@"Sub key: %@\nPub key: %@\nSec key: %@\n"
          "Dev Console URL: http://www.pubnub.com/console?channel=apns&pub=%@&sub=%@",
          kPubNubSubscriptionKey, kPubNubPublishKey, kPubNubSecretKey, kPubNubPublishKey, kPubNubSubscriptionKey);
    
    
    self.pubnubConfig = [PNConfiguration configurationWithPublishKey:kPubNubPublishKey
                                                        subscribeKey:kPubNubSubscriptionKey
                                                           secretKey:kPubNubSecretKey];;
    [PubNub setClientIdentifier:@"sfsdf"];
    [PubNub setConfiguration:self.pubnubConfig];
    [self initializePubNubClient];
    [self connectToPubnub];
}

-(void)setupAugmentedRealityController {
    if(!_arController) {
        _arController = [[AugmentedRealityController alloc] initWithView:self.view parentViewController:self withDelgate:self];
    }
    
    [_arController setMinimumScaleFactor:0.5];
    [_arController setScaleViewsBasedOnDistance:YES];
    [_arController setRotateViewsBasedOnPerspective:YES];
    [_arController setDebugMode:NO];
}

- (void)generateGeoLocations {
    [self setGeoLocations:[NSMutableArray arrayWithCapacity:[_locations count]]];
    
    for(Place *place in _locations) {
        ARGeoCoordinate *coordinate = [ARGeoCoordinate coordinateWithLocation:[place location] locationTitle:[place placeName]];
        [coordinate calibrateUsingOrigin:[_userLocation location]];
        MarkerView *markerView = [[MarkerView alloc] initWithCoordinate:coordinate delegate:self];
        NSLog(@"Marker view %@", markerView);
        
        [coordinate setDisplayView:markerView];
        [_arController addCoordinate:coordinate];
        [_geoLocations addObject:coordinate];
    }
}

#pragma mark - ARLocationDelegate

-(NSMutableArray *)geoLocations {
    if(!_geoLocations) {
        [self generateGeoLocations];
    }
    return _geoLocations;
}

- (void)locationClicked:(ARGeoCoordinate *)coordinate {
    NSLog(@"Tapped location %@", coordinate);
}

#pragma mark - ARDelegate

-(void)didUpdateHeading:(CLHeading *)newHeading {
    
}

-(void)didUpdateLocation:(CLLocation *)newLocation {
    
}

-(void)didUpdateOrientation:(UIDeviceOrientation)orientation {
    
}

#pragma mark - ARMarkerDelegate

-(void)didTapMarker:(ARGeoCoordinate *)coordinate {
}

- (void)didTouchMarkerView:(MarkerView *)markerView {
    ARGeoCoordinate *tappedCoordinate = [markerView coordinate];
    CLLocation *location = [tappedCoordinate geoLocation];
    
    
    NSInteger index = NSNotFound;
    for(int i = 0;i < _locations.count;i++) {
        Place *tappedPlace = [_locations objectAtIndex:index];
        if([[tappedPlace location] isEqual:location]) {
            index = i;
            break;
        }
    }
    if(index != NSNotFound) {
        Place *tappedPlace = [_locations objectAtIndex:index];
        [[PlacesLoader sharedInstance] loadDetailInformation:tappedPlace successHanlder:^(NSDictionary *response) {
            NSLog(@"Response: %@", response);
            NSDictionary *resultDict = [response objectForKey:@"result"];
            [tappedPlace setPhoneNumber:[resultDict objectForKey:kPhoneKey]];
            [tappedPlace setWebsite:[resultDict objectForKey:kWebsiteKey]];
            [self showInfoViewForPlace:tappedPlace];
        } errorHandler:^(NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }
}

- (void)showInfoViewForPlace:(Place *)place {
    CGRect frame = [[self view] frame];
    UITextView *infoView = [[UITextView alloc] initWithFrame:CGRectMake(50.0f, 50.0f, frame.size.width - 100.0f, frame.size.height - 100.0f)];
    [infoView setCenter:[[self view] center]];
    [infoView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [infoView setText:[place infoText]];
    [infoView setTag:kInfoViewTag];
    [infoView setEditable:NO];
    [[self view] addSubview:infoView];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *infoView = [[self view] viewWithTag:kInfoViewTag];
    
    [infoView removeFromSuperview];	
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // Start sending chat presence
    //
    [[QBChat instance] addDelegate:self];
    [NSTimer scheduledTimerWithTimeInterval:30 target:[QBChat instance] selector:@selector(sendPresence) userInfo:nil repeats:YES];
}

- (void)audioOutputDidChange:(UISegmentedControl *)sender{
    if(self.videoChat != nil){
        self.videoChat.useHeadphone = sender.selectedSegmentIndex;
    }
}

- (void)videoOutputDidChange{
    //self.videoChat.useBackCamera = 1;
    if(self.videoChat != nil){
        self.videoChat.useBackCamera = 1;
        //[self setupAugmentedRealityController];
    }
}

- (void)call:(id)sender{
    // Call
    if(callButton.tag == 101){
        callButton.tag = 102;
        
        // Setup video chat
        //
        if(self.videoChat == nil){
            self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstance];
            UIView *videoView = [[UIView alloc] initWithFrame:self.view.frame];
            [self.view addSubview:videoView];
            [self.view sendSubviewToBack:videoView];
            self.videoChat.viewToRenderOpponentVideoStream = videoView;
            //self.videoChat.useBackCamera = 1;
        }
        
        // Set Audio & Video output
        //
        //self.videoChat.useBackCamera = 1;
    
        // Call user by ID
        //
        [self.videoChat callUser:[opponentID integerValue] conferenceType:QBVideoChatConferenceTypeAudioAndVideo];

        callButton.hidden = YES;
        ringigngLabel.hidden = NO;
        ringigngLabel.text = @"Calling...";
        ringigngLabel.frame = CGRectMake(128, 375, 90, 37);
        callingActivityIndicator.hidden = NO;
       // [self videoOutputDidChange];
    // Finish
    }else{
        callButton.tag = 101;
        
        // Finish call
        //
        [self.videoChat finishCall];
        

        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [callButton setTitle:appDelegate.currentUser == 1 ? @"Call Client" : @"Call Client" forState:UIControlStateNormal];
        

        
        
        // release video chat
        //
        [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
        self.videoChat = nil;
        
    }
}

- (void)reject{
    // Reject call
    //
    if(self.videoChat == nil){
        self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstanceWithSessionID:sessionID];
        
    }
    [self.videoChat rejectCallWithOpponentID:videoChatOpponentID];
    //
    //
    [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
    self.videoChat = nil;

    // update UI
    callButton.hidden = NO;
    ringigngLabel.hidden = YES;
    
    // release player
    ringingPlayer = nil;
}

- (void)accept{
    NSLog(@"accept");
    
    // Setup video chat
    //

    // Set Audio & Video output
    //
    //self.videoChat.useBackCamera = 1;
    
    // Accept call
    //
    if(self.videoChat == nil){
        self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstanceWithSessionID:sessionID];
        UIView *videoView = [[UIView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:videoView];
        [self.view sendSubviewToBack:videoView];
        self.videoChat.viewToRenderOpponentVideoStream = videoView;
    }
    [self.videoChat acceptCallWithOpponentID:videoChatOpponentID conferenceType:videoChatConferenceType];

    ringigngLabel.hidden = YES;
    callButton.hidden = NO;
    [callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    callButton.tag = 102;

    
    ringingPlayer = nil;
}

- (void)hideCallAlert{
    [self.callAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.callAlert = nil;
    
    callButton.hidden = NO;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    ringingPlayer = nil;
}


#pragma mark -
#pragma mark QBChatDelegate 
//
// VideoChat delegate

-(void) chatDidReceiveCallRequestFromUser:(NSUInteger)userID withSessionID:(NSString *)_sessionID conferenceType:(enum QBVideoChatConferenceType)conferenceType{
    NSLog(@"chatDidReceiveCallRequestFromUser %lu", (unsigned long)userID);
    
    // save  opponent data
    videoChatOpponentID = userID;
    videoChatConferenceType = conferenceType;
    sessionID = _sessionID;
    
    
    callButton.hidden = YES;
    
    // show call alert
    //
    if (self.callAlert == nil) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?", appDelegate.currentUser == 1 ? @"User 2" : @"User 1"];
        self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
        [self.callAlert show];
    }
    
    // hide call alert if opponent has canceled call
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCallAlert) object:nil];
    [self performSelector:@selector(hideCallAlert) withObject:nil afterDelay:4];
    
    // play call music
    //
    if(ringingPlayer == nil){
        NSString *path =[[NSBundle mainBundle] pathForResource:@"ringing" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        ringingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
        ringingPlayer.delegate = self;
        [ringingPlayer setVolume:1.0];
        [ringingPlayer play];
    }
}

-(void) chatCallUserDidNotAnswer:(NSUInteger)userID{
    NSLog(@"chatCallUserDidNotAnswer %lu", (unsigned long)userID);
    
    callButton.hidden = NO;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void) chatCallDidRejectByUser:(NSUInteger)userID{
     NSLog(@"chatCallDidRejectByUser %lu", (unsigned long)userID);
    
    callButton.hidden = NO;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void) chatCallDidAcceptByUser:(NSUInteger)userID{
    NSLog(@"chatCallDidAcceptByUser %lu", (unsigned long)userID);
     //self.videoChat.useBackCamera = 1;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    
    
    callButton.hidden = NO;
    [callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    callButton.tag = 102;
    //[self videoOutputDidChange];

}

-(void) chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status{
    NSLog(@"chatCallDidStopByUser %lu purpose %@", (unsigned long)userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
     
        ringigngLabel.hidden = YES;
        
        ringingPlayer = nil;
    
    }else{

        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [callButton setTitle:appDelegate.currentUser == 1 ? @"Call Client" : @"Call Client" forState:UIControlStateNormal];
        callButton.tag = 101;
    }
    
    callButton.hidden = NO;
    
    // release video chat
    //
    [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
    self.videoChat = nil;
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID sessionID:(NSString *)sessionID{
}

- (void)didStartUseTURNForVideoChat{
//    NSLog(@"_____TURN_____TURN_____");
}


#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        // Reject
        case 0:
            [self reject];
            break;
        // Accept
        case 1:
            [self accept];
            break;
            
        default:
            break;
    }
    
    self.callAlert = nil;
}


#pragma mark - CLLocationManager Delegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *lastLocation = [locations lastObject];
    
    CLLocationAccuracy accuracy = [lastLocation horizontalAccuracy];
    
    NSLog(@"Received location %@ with accuracy %f", lastLocation, accuracy);
    
    if(accuracy < 100.0) {

        
        
        [[PlacesLoader sharedInstance] loadPOIsForLocation:[locations lastObject] radius:1000 successHanlder:^(NSDictionary *response) {
            NSLog(@"Response: %@", response);
            if([[response objectForKey:@"status"] isEqualToString:@"OK"]) {
                id places = [response objectForKey:@"results"];
                NSMutableArray *temp = [NSMutableArray array];
                
                if([places isKindOfClass:[NSArray class]]) {
                    for(NSDictionary *resultsDict in places) {
                        CLLocation *location = [[CLLocation alloc] initWithLatitude:[[resultsDict valueForKeyPath:kLatiudeKeypath] floatValue] longitude:[[resultsDict valueForKeyPath:kLongitudeKeypath] floatValue]];
                        Place *currentPlace = [[Place alloc] initWithLocation:location reference:[resultsDict objectForKey:kReferenceKey] name:[resultsDict objectForKey:kNameKey] address:[resultsDict objectForKey:kAddressKey]];
                        [temp addObject:currentPlace];
                        
                    }
                }
                
                _locations = [temp copy];
                [self generateGeoLocations];
                NSLog(@"Locations: %@", _locations);
            }
        } errorHandler:^(NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
        [manager stopUpdatingLocation];
    }
}

- (void)initializePubNubClient {
    
    [PubNub setDelegate:self];
    
    
    // Subscribe for client connection state change
    // (observe when client will be disconnected)
    [[PNObservationCenter defaultCenter] addClientConnectionStateObserver:self
                                                        withCallbackBlock:^(NSString *origin,
                                                                            BOOL connected,
                                                                            PNError *error) {
                                                            
                                                            
                                                            if (!connected && error) {
                                                                
                                                                
                                                            }
                                                            else {
                                                                //[self subscribeAllJoinedChannels];
                                                            }
                                                        }];
    
    
    // Subscribe application delegate on subscription updates
    // (events when client subscribe on some channel)
    // Subscribe application delegate on subscription updates
    // (events when client subscribe on some channel)
    [[PNObservationCenter defaultCenter] addClientChannelSubscriptionStateObserver:self
                                                                 withCallbackBlock:^(PNSubscriptionProcessState state,
                                                                                     NSArray *channels,
                                                                                     PNError *subscriptionError) {
                                                                     
                                                                     switch (state) {
                                                                             
                                                                         case PNSubscriptionProcessNotSubscribedState:
                                                                             
                                                                             
                                                                             break;
                                                                             
                                                                         case PNSubscriptionProcessSubscribedState:
                                                                             
                                                                             
                                                                             break;
                                                                             
                                                                         case PNSubscriptionProcessWillRestoreState:
                                                                             
                                                                           
                                                                             break;
                                                                             
                                                                         case PNSubscriptionProcessRestoredState:
                                                                             
                                                                          
                                                                             break;
                                                                     }
                                                                 }];
    
    // Subscribe on message arrival events with block
    [[PNObservationCenter defaultCenter] addMessageReceiveObserver:self
                                                         withBlock:^(PNMessage *message) {
                                                             NSDictionary *messageDict = (NSDictionary *)message.message;
                                                             NSString *x = [messageDict objectForKey:@"x"];
                                                             double xVal = [x doubleValue];
                                                             NSString *y = [messageDict objectForKey:@"y"];
                                                             double yVal = [y doubleValue] ;
                                                             NSString *title = [messageDict objectForKey:@"title"];
                                                             NSString *distance = [messageDict objectForKey:@"distance"];
                                                             if([self.markerLabel superview]) {
                                                                 [self.markerLabel removeFromSuperview];
                                                             }
                                                             
                                                             self.markerLabel = [[MarkerView alloc]initWithTitle:title distnace:distance];
                                                              self.markerLabel.frame = CGRectMake(xVal, yVal - 40.0, 80, 60) ;
                                                             [self.overlayView addSubview:self.markerLabel];
                                                             
                                                         }];
    
    // Subscribe on presence event arrival events with block
    [[PNObservationCenter defaultCenter] addPresenceEventObserver:self
                                                        withBlock:^(PNPresenceEvent *presenceEvent) {
                                                            
                                                           
                                                        }];
    
}
-(void)connectToPubnub {
    [PubNub connectWithSuccessBlock:^(NSString *origin) {
        
        NSLog(@"connected to Pubnub");
        PNChannel *channel = [PNChannel channelWithName:@"Housing"
                                  shouldObservePresence:YES];
        NSLog(@"currentChannel:%p", channel);
        
        [PubNub subscribeOn:@[channel] withCompletionHandlingBlock:^(PNSubscriptionProcessState state, NSArray *channels, PNError *subscriptionError) {
            
            if (state == PNSubscriptionProcessNotSubscribedState) {
                NSLog(@"Error : could not Subscribe to channel");
            } else if (state == PNSubscriptionProcessSubscribedState) {
                NSLog(@"Subscribed to channel");
            }
        }];

    }
     
    errorBlock:^(PNError *connectionError) {
                             
            NSLog(@" Error connected to Pubnub");
                             
    }];
}



@end
