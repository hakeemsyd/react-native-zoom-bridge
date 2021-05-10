
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#import <React/RCTEventEmitter.h>
#else
#import <React/RCTBridgeModule.h>
#endif

#import "MobileRTC.h"

@interface RNZoomBridge : RCTEventEmitter <RCTBridgeModule, MobileRTCAuthDelegate, MobileRTCMeetingServiceDelegate>

- (void)setMeetingTitleHidden:(BOOL)hidden;

- (void)setMeetingPasswordHidden:(BOOL)hidden;

- (void)setBottomBarHidden:(BOOL)hidden;

- (void)disableDriveMode:(BOOL)disabled;

- (void)setAutoConnectInternetAudio:(BOOL)connected;

- (void)setTopBarHidden:(BOOL)hidden;

@end
  
