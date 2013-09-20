//
//  MJAppDelegate.m
//  ImPro
//
//  Created by Martin Johannesson on 2013-09-14.
//  Copyright (c) 2013 Martin Johannesson. All rights reserved.
//

#import "MJAppDelegate.h"

@implementation MJAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self.window makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
