#import "RNAirplay.h"
#import "RNAirplayManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AudioToolbox/AudioToolbox.h>


@implementation RNAirplay
{
  bool hasListeners;
}
@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(startScan)
{
    // Add observer which will call "deviceChanged" method when audio outpout changes
    // e.g. headphones connect / disconnect
    [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector: @selector(deviceChanged:)
    name:AVAudioSessionRouteChangeNotification
    object:[AVAudioSession sharedInstance]];

    // Also call sendEventAboutConnectedDevice method immediately to send currently connected device
    // at the time of startScan
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sendEventAboutConnectedDevice];
    });
}

RCT_EXPORT_METHOD(disconnect)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(showMenu)
{
    AVRoutePickerView *routePickerView = [[AVRoutePickerView alloc] init];
    [routePickerView setHidden:YES];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:routePickerView];

    for (UIView *subview in routePickerView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [(UIButton*)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

RCT_EXPORT_METHOD(overrideOutputAudioPort)
{
    [[AVAudioSession sharedInstance] setActive: NO error: nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}

- (void)deviceChanged:(NSNotification *)sender {
    // Get current audio output
    [self sendEventAboutConnectedDevice];
}

// Gets current devices and sends an event to React Native with information about it
- (void) sendEventAboutConnectedDevice;
{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSString *deviceName;
    NSString *portType;
    NSMutableArray *devices = [NSMutableArray array];
    for (AVAudioSessionPortDescription * output in currentRoute.outputs) {
        deviceName = output.portName;
        portType = output.portType;
        NSDictionary *device = @{ @"deviceName" : deviceName, @"portType" : portType};
        [devices addObject: device];
    }
    if (hasListeners) { // Only send events if anyone is listening
      [self sendEventWithName:@"deviceConnected" body:@{@"devices": devices}];
    }
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"deviceConnected"];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
