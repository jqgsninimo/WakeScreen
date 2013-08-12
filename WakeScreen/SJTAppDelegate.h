//
//  SJTAppDelegate.h
//  WakeScreen
//
//  Created by Jqgsninimo on 13-8-12.
//  Copyright (c) 2013年 SJT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SJTSlider.h"

@interface SJTAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, SJTSliderDelegate, NSSoundDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet SJTSlider *slider;

@end
