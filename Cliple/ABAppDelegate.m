//
//  ABAppDelegate.m
//  Cliple
//
//  Created by Антон Буков on 12.10.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

#import "JKBigInteger/JKBigInteger.h"
#import "ABAppDelegate.h"

static const NSInteger MaxVisibleItems = 30;
static const NSInteger MaxVisibleChars = 32;

@interface ABAppDelegate ()

@property (weak, nonatomic) IBOutlet NSMenu *menu;

@property (strong, nonatomic) NSStatusItem *statusBar;
@property (strong, nonatomic) NSMutableArray * texts;
@property (strong, nonatomic) NSMutableArray * times;
@property (assign, nonatomic) NSInteger selectedIndex;

@end

@implementation ABAppDelegate

- (void)menuItemSelect:(id)sender {
    NSInteger index = [self.menu.itemArray indexOfObject:sender];
    
    NSPasteboard * pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    NSPasteboardItem * pboardItem = [[NSPasteboardItem alloc] init];
    [pboardItem setString:self.texts[index] forType:NSPasteboardTypeString];
    [pboard writeObjects:@[pboardItem]];
    
    [self bringItemUp:index];
}

- (void)bringItemUp:(NSInteger)index {
    NSMenuItem *item = [self.menu itemAtIndex:index];
    [self.menu removeItemAtIndex:index];
    [self.menu insertItem:item atIndex:0];
    
    NSString *text = self.texts[index];
    [self.texts removeObjectAtIndex:index];
    [self.texts insertObject:text atIndex:0];

    [self.times removeObjectAtIndex:index];
    [self.times insertObject:[NSDate date] atIndex:0];
}

- (void)updateItemTitlesAndStates {
    for (int i = 0; i < self.menu.itemArray.count-2; i++) {
        NSDate * time = self.times[i];
        NSString * text = self.texts[i];
        NSMenuItem * menuItem = self.menu.itemArray[i];
        
        NSDateComponents * components = [[NSCalendar autoupdatingCurrentCalendar] components:NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:time toDate:[NSDate date] options:0];
        
        NSString * timeStr = nil;
        if (components.year)
            timeStr = [NSString stringWithFormat:@"%dy",(int)components.year];
        else if (components.month)
            timeStr = [NSString stringWithFormat:@"%dM",(int)components.month];
        else if (components.day)
            timeStr = [NSString stringWithFormat:@"%dd",(int)components.day];
        else if (components.hour)
            timeStr = [NSString stringWithFormat:@"%dH",(int)components.hour];
        else if (components.minute)
            timeStr = [NSString stringWithFormat:@"%dm",(int)components.minute];
        else
            timeStr = [NSString stringWithFormat:@"%ds",(int)components.second];
        
        menuItem.title = [NSString stringWithFormat:@"(%@) \"%@%@\"", timeStr,
                          [text substringToIndex:MIN(MaxVisibleChars,text.length)],
                          (text.length <= MaxVisibleChars) ? @"" : @"..."];
        menuItem.state = (i == self.selectedIndex) ? NSOnState : NSOffState;
        //menuItem.keyEquivalent = [@(i+1) description];
    }
}

- (void)timerFire:(id)sender {
    NSPasteboard * pboard = [NSPasteboard generalPasteboard];
    NSPasteboardItem * pboardItem = [[pboard pasteboardItems] lastObject];
    NSString * text = [pboardItem stringForType:NSPasteboardTypeString];
    NSInteger index = [self.texts indexOfObject:text];
    
    // Not text in clipboard or data were copied before
    if (!text || index != NSNotFound) {
        self.selectedIndex = MAX(0,index);
        [self updateItemTitlesAndStates];
        [self bringItemUp:index];
        if ([text hasPrefix:@"!"] && text.length > 1 && text.length < 100) {
            NSLog(@"Checking command");
            NSString *replace = [self replaceForCommand:[text substringFromIndex:1]];
            if (replace.length > 0) {
                NSLog(@"Command found");
                [pboard clearContents];
                [pboard setString:replace forType:NSPasteboardTypeString];
            }
        }
        return;
    }
    
    // Remove last item until MaxVisibleItems left
    while (self.menu.itemArray.count >= MaxVisibleItems + 2) {
        [self.menu removeItemAtIndex:self.menu.itemArray.count - 3];
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
    NSLog(@"Added text");
    
    if ([text hasPrefix:@"!"] && text.length > 1 && text.length < 100) {
        NSLog(@"Checking command");
        NSString *replace = [self replaceForCommand:[text substringFromIndex:1]];
        if (replace.length > 0) {
            NSLog(@"Command found");
            [pboard clearContents];
            [pboard setString:replace forType:NSPasteboardTypeString];
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Configure GUI
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.title = @"📇";
    self.statusBar.menu = self.menu;
    self.statusBar.highlightMode = YES;
    
    // Load saved defaults
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    self.texts = [[defs objectForKey:@"texts"] mutableCopy] ?: [NSMutableArray array];
    self.times = [[defs objectForKey:@"times"] mutableCopy] ?: [NSMutableArray array];
    self.selectedIndex = -1;
    for (int i = 0; i < MIN(MaxVisibleItems,self.texts.count); i++) {
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

- (NSString *)replaceForCommand:(NSString *)input {
    NSData *jsonData = [NSData dataWithContentsOfFile:[@"~/.cliple.json" stringByExpandingTildeInPath]];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    if (dict[input.lowercaseString]) {
        return dict[input.lowercaseString];
    }

    static NSRegularExpression *hexRegex;
    if (hexRegex == nil) {
        hexRegex = [NSRegularExpression regularExpressionWithPattern:@"0x[0-9a-fA-F]+" options:0 error:nil];
    }
    static NSRegularExpression *decRegex;
    if (decRegex == nil) {
        decRegex = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options:0 error:nil];
    }
    
    if ([input hasPrefix:@"0x"] && [hexRegex rangeOfFirstMatchInString:input options:0 range:NSMakeRange(0, input.length)].length == input.length) {
        return [[[JKBigInteger alloc] initWithString:[input substringFromIndex:2] andRadix:16] stringValueWithRadix:10];
    }
    
    if ([decRegex rangeOfFirstMatchInString:input options:0 range:NSMakeRange(0, input.length)].length == input.length) {
        return [@"0x" stringByAppendingString:[[[JKBigInteger alloc] initWithString:input andRadix:10] stringValueWithRadix:16]];
    }
    
    return nil;
}

@end
