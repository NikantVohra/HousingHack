//
//  MainViewController.h
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//
//
// This class demonstrates how to work with VideoChat API.
// It shows how to setup video conference between 2 users
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define kPubNubSubscriptionKey @"sub-c-aca06252-ab6c-11e4-a431-02ee2ddab7fe"
#define kPubNubPublishKey @"pub-c-aa71aec8-a302-4aa2-b541-433fd86db02c"
#define kPubNubSecretKey  @"sec-c-Y2IxMzQzMDgtMjIyMy00ZGVkLWJhNGEtZDdiNDgxNjVmMDUz"

@interface MainViewController : UIViewController <QBChatDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>{
    IBOutlet UIButton *callButton;
    IBOutlet UILabel *ringigngLabel;
    IBOutlet UIActivityIndicatorView *callingActivityIndicator;

    IBOutlet UINavigationBar *navBar;
;
    
    AVAudioPlayer *ringingPlayer;
    
    //
    NSUInteger videoChatOpponentID;
    enum QBVideoChatConferenceType videoChatConferenceType;
    NSString *sessionID;
}

@property (strong) NSNumber *opponentID;
@property (strong) QBVideoChat *videoChat;
@property (strong) UIAlertView *callAlert;

- (void)call:(id)sender;
- (void)reject;
- (void)accept;

@end
