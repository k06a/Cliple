//
//  ABAppDelegate.m
//  Clipshare
//
//  Created by Антон Буков on 12.10.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

#import "ABAppDelegate.h"

static const NSInteger MaxVisibleItems = 9;
static const NSInteger MaxVisibleChars = 32;

#ifndef DEBUG
#undef NSLog
#define NSLog(args, ...)
#endif

@interface ABAppDelegate ()

@property (weak, nonatomic) IBOutlet NSMenu *menu;

@property (strong, nonatomic) NSStatusItem *statusBar;
@property (strong, nonatomic) NSMutableArray * texts;
@property (strong, nonatomic) NSMutableArray * times;
@property (assign, nonatomic) NSInteger selectedIndex;

@end

@implementation ABAppDelegate

- (void)menuItemSelect:(id)sender
{
    NSInteger index = [self.menu.itemArray indexOfObject:sender];
    
    NSPasteboard * pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    NSPasteboardItem * pboardItem = [[NSPasteboardItem alloc] init];
    [pboardItem setString:self.texts[index] forType:NSPasteboardTypeString];
    [pboard writeObjects:@[pboardItem]];
}

- (void)updateItemTitlesAndStates
{
    for (int i = 0; i < self.menu.itemArray.count-2; i++)
    {
        NSDate * time = self.times[i];
        NSString * text = self.texts[i];
        NSMenuItem * menuItem = self.menu.itemArray[i];
        
        NSString * timeStr = nil;
        NSTimeInterval secs = MAX(0,[[NSDate date] timeIntervalSinceDate:time]);
        if (secs < 60)
            timeStr = [NSString stringWithFormat:@"%ds",(int)(secs)];
        else if (secs < 60*60)
            timeStr = [NSString stringWithFormat:@"%dm",(int)(secs/60)];
        else if (secs < 60*60*24)
            timeStr = [NSString stringWithFormat:@"%dh",(int)(secs/60/60)];
        else if (secs < 60*60*24*7)
            timeStr = [NSString stringWithFormat:@"%dd",(int)(secs/60/60/24)];
        else if (secs < 60*60*24*365.75)
            timeStr = [NSString stringWithFormat:@"%dw",(int)(secs/60/60/24/7)];
        else if (secs < 60*60*24*365.75*3)
            timeStr = [NSString stringWithFormat:@"%dM",(int)(secs/60/60/24/30.5)];
        else if (secs < 60*60*24*365.75*100)
            timeStr = [NSString stringWithFormat:@"%dy",(int)(secs/60/60/24/365.75)];
        else
            timeStr = @"..";
        
        menuItem.title = [NSString stringWithFormat:@"(%@) \"%@%@\"", timeStr,
                          [text substringToIndex:MIN(MaxVisibleChars,text.length)],
                          (text.length <= MaxVisibleChars) ? @"" : @"..."];
        menuItem.state = (i == self.selectedIndex) ? NSOnState : NSOffState;
        menuItem.keyEquivalent = [@(i+1) description];
    }
}

- (void)timerFire:(id)sender
{
    NSPasteboard * pboard = [NSPasteboard generalPasteboard];
    NSPasteboardItem * pboardItem = [[pboard pasteboardItems] lastObject];
    NSString * text = [pboardItem stringForType:NSPasteboardTypeString];
    NSInteger index = [self.texts indexOfObject:text];
    
    // Not text in clipboard or data were copied before
    if (!text || index != NSNotFound)
    {
        self.selectedIndex = MAX(0,index);
        [self updateItemTitlesAndStates];
        return;
    }
    
    // Remove last item until MaxVisibleItems left
    while (self.menu.itemArray.count >= MaxVisibleItems+2)
    {
        [self.menu removeItemAtIndex:self.menu.itemArray.count-3];
        [self.texts removeLastObject];
        [self.times removeLastObject];
    }
    
    // Adding new item
    NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemSelect:) keyEquivalent:@""];
    [self.menu insertItem:menuItem atIndex:0];
    [self.texts insertObject:text atIndex:0];
    [self.times insertObject:[NSDate date] atIndex:0];
    
    self.selectedIndex = 0;
    [self updateItemTitlesAndStates];
    NSLog(@"Added text: %@", text);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Configure GUI
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.title = @"CS";
    self.statusBar.menu = self.menu;
    self.statusBar.highlightMode = YES;
    
    // Load saved defaults
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    self.texts = [defs objectForKey:@"texts"] ?: [NSMutableArray array];
    self.times = [defs objectForKey:@"times"] ?: [NSMutableArray array];
    self.selectedIndex = -1;
    for (int i = 0; i < MIN(MaxVisibleItems,self.texts.count); i++)
    {
        NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemSelect:) keyEquivalent:@""];
        [self.menu insertItem:menuItem atIndex:self.menu.itemArray.count-2];
    }
    [self timerFire:nil];
    
    // Configure timer
    NSTimer * timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer fire];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    // Save items to defaults
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:self.texts forKey:@"texts"];
    [defs setObject:self.times forKey:@"times"];
    [defs synchronize];
}

@end
