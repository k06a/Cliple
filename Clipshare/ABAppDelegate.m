//
//  ABAppDelegate.m
//  Clipshare
//
//  Created by Антон Буков on 12.10.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

#import "ABAppDelegate.h"

static const NSInteger MaxVisibleItems = 10;
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
        NSMenuItem * menuItem = self.menu.itemArray[i];
        NSTimeInterval time = MAX(0,[[NSDate date] timeIntervalSinceDate:self.times[i]]);
        NSString * timeStr = nil;
        if (time < 60)
            timeStr = [NSString stringWithFormat:@"%ds",(int)(time)];
        else if (time < 60*60)
            timeStr = [NSString stringWithFormat:@"%dm",(int)(time/60)];
        else if (time < 60*60*24)
            timeStr = [NSString stringWithFormat:@"%dh",(int)(time/60/60)];
        else if (time < 60*60*24*7)
            timeStr = [NSString stringWithFormat:@"%dd",(int)(time/60/60/24)];
        else if (time < 60*60*24*365.75)
            timeStr = [NSString stringWithFormat:@"%dw",(int)(time/60/60/24/7)];
        else if (time < 60*60*24*365.75*3)
            timeStr = [NSString stringWithFormat:@"%dM",(int)(time/60/60/24/30.5)];
        else if (time < 60*60*24*365.75*100)
            timeStr = [NSString stringWithFormat:@"%dy",(int)(time/60/60/24/365.75)];
        else
            timeStr = @"";
        
        menuItem.title = [NSString stringWithFormat:@"(%@) \"%@%@\"",timeStr,[self.texts[i] substringToIndex:MIN(MaxVisibleChars,[self.texts[i] length])],([self.texts[i] length] <= MaxVisibleChars)?@"":@"..."];
        
        [self.menu.itemArray[i] setState:(i == self.selectedIndex) ? NSOnState : NSOffState];
    }
}

- (void)timerFire:(id)sender
{
    NSPasteboard * pboard = [NSPasteboard generalPasteboard];
    NSPasteboardItem * pboardItem = [[pboard pasteboardItems] lastObject];
    NSString * text = [pboardItem stringForType:NSPasteboardTypeString];
    NSInteger index = [self.texts indexOfObject:text];
    if (!text || index != NSNotFound)
    {
        self.selectedIndex = MAX(0,index);
        [self updateItemTitlesAndStates];
        return;
    }
    [self.texts insertObject:text atIndex:0];
    [self.times insertObject:[NSDate date] atIndex:0];
    
    if (self.menu.itemArray.count > MaxVisibleItems+2)
        [self.menu removeItemAtIndex:self.menu.itemArray.count-3];
    NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemSelect:) keyEquivalent:@""];
    [self.menu insertItem:menuItem atIndex:0];
    
    self.selectedIndex = 0;
    [self updateItemTitlesAndStates];
    
    NSLog(@"Fire! %@", text);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.title = @"CS";
    self.statusBar.menu = self.menu;
    self.statusBar.highlightMode = YES;
    
    NSTimer * timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer fire];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:self.texts forKey:@"texts"];
    [defs setObject:self.times forKey:@"times"];
    [defs synchronize];
}

@end
