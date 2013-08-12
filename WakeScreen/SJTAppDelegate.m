//
//  SJTAppDelegate.m
//  WakeScreen
//
//  Created by Jqgsninimo on 13-8-12.
//  Copyright (c) 2013年 SJT. All rights reserved.
//

#import <IOKit/IOMessage.h>
#import "SJTAppDelegate.h"

BOOL kDevicePowerOn = YES;
void displayWranglerNotificationsCallback(void *refcon, io_service_t service, natural_t messageType, void *messageArgument) {
    switch (messageType) {
        case kIOMessageDeviceWillPowerOff:
            // This is called twice - once for display dim event, then once
            // for display power off
            kDevicePowerOn = NO;
            break;
        case kIOMessageDeviceHasPoweredOn:
            // Display powering back on
            kDevicePowerOn = YES;
            break;
    }
}

@interface SJTAppDelegate ()
@property (strong) NSTimer *timer;
@property (strong) NSArray *soundArray;
@property (strong) NSMutableArray *soundPlayArray;
- (void)timerSelector;
- (void)listen;
- (void)wake;
- (void)readNumber:(NSInteger)number;
@end

@implementation SJTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.slider.delegate = self;
    self.window.title = [self slider:self.slider tipForValue:self.slider.doubleValue];
    
    NSMutableArray *soundArray = [NSMutableArray arrayWithCapacity:10];
    for (NSInteger number = 1; number<=10; number++) {
        NSSound *sound = [NSSound soundNamed:[NSString stringWithFormat:@"%ld",number]];
        sound.delegate = self;
        [soundArray addObject:sound];
    }
    self.soundArray = [NSArray arrayWithArray:soundArray];
    self.soundPlayArray = [NSMutableArray arrayWithCapacity:2];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerSelector) userInfo:nil repeats:YES];
    
    [self listen];
}

#pragma mark -
#pragma mark Methods From NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender {
    [NSApp terminate:self];
    return YES;
}

#pragma mark -
#pragma mark Methods From SJTSliderDelegate
- (NSString *)slider:(SJTSlider *)slider tipForValue:(double)value {
    NSString *result = [NSString stringWithFormat:@"%ld秒后唤醒屏幕", (NSInteger)value];
    return result;
}

- (void)valueDidSelectInSlider:(SJTSlider *)slider {
    self.window.title = [self slider:self.slider tipForValue:self.slider.doubleValue];
}

#pragma mark -
#pragma mark Methods From NSSoundDelegate
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying {
    [self.soundPlayArray removeObject:sound];
    if (finishedPlaying&&self.soundPlayArray.count>0) {
        NSSound *sound = self.soundPlayArray[0];
        [sound play];
    } else {
        [self.soundPlayArray removeAllObjects];
    }
}

#pragma mark -
#pragma mark Own Methods
- (void)timerSelector {
    static NSInteger count = 0;
    if (kDevicePowerOn) {
        count = 0;
    } else {
        count = count%100+1;
        [self readNumber:count];
        if (count==(NSInteger)self.slider.doubleValue) {
            [self wake];
        }
    }
}

- (void)listen {
    io_object_t notification;
    io_service_t displayWrangler = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceNameMatching("IODisplayWrangler"));
    IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    IOServiceAddInterestNotification(notificationPort, displayWrangler, kIOGeneralInterest, displayWranglerNotificationsCallback, NULL, &notification);
    CFRunLoopAddSource (CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopDefaultMode);
    IOObjectRelease(displayWrangler);
}

- (void)wake {
    io_registry_entry_t registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (registryEntry) {
        IORegistryEntrySetCFProperty(registryEntry, CFSTR("IORequestIdle"), kCFBooleanFalse);
        IOObjectRelease(registryEntry);
    }
}

- (void)readNumber:(NSInteger)number {
    if (self.soundPlayArray.count==0) {
        number = number%100;
        NSInteger sound1Name = number/10;
        NSInteger sound2Name = number%10;
        if (sound1Name>0) {
            if (sound1Name>1) {
                [self.soundPlayArray addObject:self.soundArray[sound1Name-1]];
            }
            [self.soundPlayArray addObject:self.soundArray[9]];
        }
        if (sound2Name>0) {
            [self.soundPlayArray addObject:self.soundArray[sound2Name-1]];
        }
        if (self.soundPlayArray.count>0) {
            NSSound *sound = self.soundPlayArray[0];
            [sound play];
        }
    }
}

@end