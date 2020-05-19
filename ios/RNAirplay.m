#import "RNAirplay.h"
#import "RNAirplayManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>


@implementation RNAirplay
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
    MPVolumeView *airplayView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 0, 0 )];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:airplayView];
    
    for (UIView *subview in airplayView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [(UIButton*)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
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
        if ([portType isEqualToString:AVAudioSessionPortAirPlay]) {
            NSDictionary *device = @{ @"deviceName" : deviceName, @"portType" : portType};
            [devices addObject: device];
        }
    }
    if ([devices count] > 0) {
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
