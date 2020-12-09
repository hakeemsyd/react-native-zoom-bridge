
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import "MobileRTC.h"

@interface RNZoomBridge : NSObject <RCTBridgeModule, MobileRTCAuthDelegate, MobileRTCMeetingServiceDelegate>

- (void)setMeetingTitleHidden:(BOOL)hidden;

- (void)setMeetingPasswordHidden:(BOOL)hidden;

- (void)setBottomBarHidden:(BOOL)hidden;

- (void)disableDriveMode:(BOOL)disabled;

@end
  
