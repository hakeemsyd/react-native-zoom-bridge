
#import "RNZoomBridge.h"

@implementation RNZoomBridge
{
  BOOL hasListeners;
  BOOL isInitialized;
  RCTPromiseResolveBlock initializePromiseResolve;
  RCTPromiseRejectBlock initializePromiseReject;
  RCTPromiseResolveBlock meetingPromiseResolve;
  RCTPromiseRejectBlock meetingPromiseReject;
}

- (instancetype)init {
  if (self = [super init]) {
    isInitialized = NO;
    initializePromiseResolve = nil;
    initializePromiseReject = nil;
    meetingPromiseResolve = nil;
    meetingPromiseReject = nil;
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"ZoomMeetingState"];
}

-(void)startObserving {
    hasListeners = YES;
  NSLog(@"ZoomMeetingState startObserving");
}

-(void)stopObserving {
    hasListeners = NO;
  NSLog(@"ZoomMeetingState stopObserving");
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(
  initialize: (NSString *)appKey
  withAppSecret: (NSString *)appSecret
  withWebDomain: (NSString *)webDomain
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
  if (isInitialized) {
    resolve(@"Already initialize Zoom SDK successfully.");
    return;
  }

  isInitialized = true;

  @try {
    initializePromiseResolve = resolve;
    initializePromiseReject = reject;

    [[MobileRTC sharedRTC] setMobileRTCDomain:webDomain];

    MobileRTCAuthService *authService = [[MobileRTC sharedRTC] getAuthService];
    if (authService)
    {
      authService.delegate = self;

      authService.clientKey = appKey;
      authService.clientSecret = appSecret;

      [authService sdkAuth];
    } else {
      NSLog(@"onZoomSDKInitializeResult, no authService");
    }
  } @catch (NSError *ex) {
      isInitialized = NO;
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing initialize", ex);
  }
}

RCT_EXPORT_METHOD(
  startMeeting: (NSString *)displayName
  withMeetingNo: (NSString *)meetingNo
  withUserId: (NSString *)userId
  withUserType: (NSInteger)userType
  withZoomAccessToken: (NSString *)zoomAccessToken
  withZoomToken: (NSString *)zoomToken
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
  @try {
    meetingPromiseResolve = resolve;
    meetingPromiseReject = reject;

    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    if (ms) {
      ms.delegate = self;

      MobileRTCMeetingStartParam4WithoutLoginUser * params = [[MobileRTCMeetingStartParam4WithoutLoginUser alloc]init];
      params.userName = displayName;
      params.meetingNumber = meetingNo;
      params.userID = userId;
      params.userType = (MobileRTCUserType)userType;
      params.zak = zoomAccessToken;
      params.userToken = zoomToken;

      MobileRTCMeetError startMeetingResult = [ms startMeetingWithStartParam:params];
      NSLog(@"startMeeting, startMeetingResult=%d", startMeetingResult);
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing startMeeting", ex);
  }
}

RCT_EXPORT_METHOD(
  joinMeeting: (NSString *)displayName
  withMeetingNo: (NSString *)meetingNo
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
  @try {
    meetingPromiseResolve = resolve;
    meetingPromiseReject = reject;

    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    if (ms) {
      ms.delegate = self;

      NSDictionary *paramDict = @{
        kMeetingParam_Username: displayName,
        kMeetingParam_MeetingNumber: meetingNo
      };

      MobileRTCMeetError joinMeetingResult = [ms joinMeetingWithDictionary:paramDict];
      NSLog(@"joinMeeting, joinMeetingResult=%d", joinMeetingResult);
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing joinMeeting", ex);
  }
}

RCT_EXPORT_METHOD(
    joinMeetingWithPassword: (NSString *)displayName
    withMeetingNo: (NSString *)meetingNo
    withPassword: (NSString *)password
    withResolve: (RCTPromiseResolveBlock)resolve
    withReject: (RCTPromiseRejectBlock)reject
)
{
    @try {
      meetingPromiseResolve = resolve;
      meetingPromiseReject = reject;

      MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
      [self setMeetingTitleHidden:YES];
      [self setMeetingPasswordHidden:YES];
      [self setBottomBarHidden:YES];
      [self disableDriveMode:YES];
      [self setAutoConnectInternetAudio:YES];
      [self setTopBarHidden:NO];
      if (ms) {
        ms.delegate = self;

        NSDictionary *paramDict = @{
          kMeetingParam_Username: displayName,
          kMeetingParam_MeetingNumber: meetingNo,
          kMeetingParam_MeetingPassword: password
        };

        MobileRTCMeetError joinMeetingResult = [ms joinMeetingWithDictionary:paramDict];
        NSLog(@"joinMeeting, joinMeetingResult=%d", joinMeetingResult);
      }
    } @catch (NSError *ex) {
        reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing joinMeeting", ex);
    }
}

- (void)onMobileRTCAuthReturn:(MobileRTCAuthError)returnValue {
  NSLog(@"nZoomSDKInitializeResult, errorCode=%d", returnValue);
  if(returnValue != MobileRTCAuthError_Success) {
    isInitialized = NO;
    initializePromiseReject(
      @"ERR_ZOOM_INITIALIZATION",
      [NSString stringWithFormat:@"Error: %d", returnValue],
      [NSError errorWithDomain:@"us.zoom.sdk" code:returnValue userInfo:nil]
    );
  } else {
    initializePromiseResolve(@"Initialize Zoom SDK successfully.");
  }
}

- (void)onMeetingReturn:(MobileRTCMeetError)errorCode internalError:(NSInteger)internalErrorCode {
  NSLog(@"onMeetingReturn, error=%d, internalErrorCode=%zd", errorCode, internalErrorCode);

  if (!meetingPromiseResolve) {
    return;
  }

  if (errorCode != MobileRTCMeetError_Success || errorCode != 0) {
    meetingPromiseReject(
      @"ERR_ZOOM_MEETING",
      [NSString stringWithFormat:@"Error: %d, internalErrorCode=%zd", errorCode, internalErrorCode],
      [NSError errorWithDomain:@"us.zoom.sdk" code:errorCode userInfo:nil]
    );
  } else {
    meetingPromiseResolve(@"Connected to zoom meeting");

  }

  meetingPromiseResolve = nil;
  meetingPromiseReject = nil;
}

- (void)onMeetingStateChange:(MobileRTCMeetingState)state {
  NSLog(@"onMeetingStatusChanged, meetingState=%d", state);
    switch (state) {
        case MobileRTCMeetingState_Connecting:
            [self sendEventWithName:@"ZoomMeetingState" body:@"meeting-started"];
            break;
        case MobileRTCMeetingState_Idle:
            [self sendEventWithName:@"ZoomMeetingState" body:@"meeting-ended"];
            break;
        default:
            [self sendEventWithName:@"ZoomMeetingState" body:@"meeting state change"];
            break;
    }

  if (state == MobileRTCMeetingState_InMeeting || state == MobileRTCMeetingState_Idle) {
    if (!meetingPromiseResolve) {
      return;
    }

    meetingPromiseResolve(@"Connected to zoom meeting");

    meetingPromiseResolve = nil;
    meetingPromiseReject = nil;
  }
}

- (void)onMeetingError:(MobileRTCMeetError)errorCode message:(NSString *)message {
  NSLog(@"onMeetingError, errorCode=%d, message=%@", errorCode, message);

  if (!meetingPromiseResolve) {
    return;
  }

   if (errorCode != MobileRTCMeetError_Success || errorCode != 0) {

  meetingPromiseReject(
    @"ERR_ZOOM_MEETING",
    [NSString stringWithFormat:@"Error: %d, internalErrorCode=%@", errorCode, message],
    [NSError errorWithDomain:@"us.zoom.sdk" code:errorCode userInfo:nil]
  );

   }

  meetingPromiseResolve = nil;
  meetingPromiseReject = nil;
}

- (void)setMeetingTitleHidden:(BOOL)hidden
{
    [[MobileRTC sharedRTC] getMeetingSettings].meetingTitleHidden = hidden;
}

- (void)setMeetingPasswordHidden:(BOOL)hidden
{
    [[MobileRTC sharedRTC] getMeetingSettings].meetingPasswordHidden = hidden;
}

- (void)setBottomBarHidden:(BOOL)hidden
{
    [[MobileRTC sharedRTC] getMeetingSettings].bottomBarHidden = hidden;
}

- (void)disableDriveMode:(BOOL)disabled
{
    [[[MobileRTC sharedRTC] getMeetingSettings] disableDriveMode:disabled];
}

- (void)setAutoConnectInternetAudio:(BOOL)connected
{
    [[[MobileRTC sharedRTC] getMeetingSettings] setAutoConnectInternetAudio:connected];
}

- (void)setTopBarHidden:(BOOL)hidden
{
    [[MobileRTC sharedRTC] getMeetingSettings].topBarHidden = hidden;
}

@end
