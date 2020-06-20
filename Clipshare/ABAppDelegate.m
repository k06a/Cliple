//
//  ABAppDelegate.m
//  Clipshare
//
//  Created by Антон Буков on 12.10.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Configure GUI
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.title = @"CS";
    self.statusBar.menu = self.menu;
    self.statusBar.highlightMode = YES;
    
    // Load saved defaults
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    self.texts = [[defs objectForKey:@"texts"] mutableCopy] ?: [NSMutableArray array];
    self.times = [[defs objectForKey:@"times"] mutableCopy] ?: [NSMutableArray array];
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

- (NSString *)replaceForCommand:(NSString *)symbol {
    return @{
        @"eth": @"0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        @"gst2": @"0x0000000000b3F879cb30FE243b4Dfee438691c04",
        @"chai": @"0x06af07097c9eeb7fd685c692751d5c66db49c215",
        @"cbat": @"0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e",
        @"csai": @"0xf5dce57282a584d2746faf1593d3121fcac444dc",
        @"cdai": @"0x5d3a536e4d6dbd6114cc1ead35777bab948e3643",
        @"ceth": @"0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5",
        @"cusdc": @"0x39AA39c021dfbaE8faC545936693aC917d5E7563",
        @"crep": @"0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1",
        @"cwbtc": @"0xc11b1268c1a384e55c48c2391d8d480264a3a7f4",
        @"czrx": @"0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407",
        @"fidai": @"0x493c57c4763932315a328269e1adad09653b9081",
        @"fiusdc": @"0xF013406A0B1d544238083DF0B93ad0d2cBE0f65f",
        @"fieth": @"0x77f973FCaF871459aa58cd81881Ce453759281bC",
        @"fiwbtc": @"0xBA9262578EFef8b3aFf7F60Cd629d6CC8859C8b5",
        @"filink": @"0x1D496da96caf6b518b133736beca85D5C4F9cBc5",
        @"fizrx": @"0xA7Eb2bc82df18013ecC2A6C533fc29446442EDEe",
        @"firep": @"0xBd56E9477Fc6997609Cf45F84795eFbDAC642Ff1",
        @"fiknc": @"0x1cC9567EA2eB740824a45F8026cCF8e46973234D",
        @"snx": @"0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f",
        @"iada": @"0x8a8079c7149b8a1611e5c5d978dca3be16545f83",
        @"ibch": @"0xf6e9b246319ea30e8c2fa2d1540aaebf6f9e1b89",
        @"seth": @"0x5e74c9036fb86bd7ecdcb084a0673efc32ea31cb",
        @"leo": @"0x2af5d2ad76741191d15dfe7bf6ac92d4bd912ca3",
        @"ht": @"0x6f259637dcd74c767781e37bc6133cd6a68aa161",
        @"nusd": @"0x0c6144c16af288948c8fdb37fd8fec94bff3d1d9",
        @"matic": @"0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0",
        @"dzar": @"0x9cb2f26a23b8d89973f08c957c4d7cdf75cd341c",
        @"mrr": @"0xf8b0d22608613a10916cc9d00c0de893e2b830e8",
        @"dai": @"0x6b175474e89094c44da98b954eedeac495271d0f",
        @"sai": @"0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359",
        @"susd": @"0x57ab1ec28d129707052df4df418d58a2d46d5f51",
        @"seur": @"0xd71ecff9342a5ced620049e616c5035f1db98620",
        @"ibtc": @"0xd6014ea05bde904448b743833ddf07c3c7837481",
        @"smkr": @"0x4140919de11fce58e654cc6038017af97f810de1",
        @"sbtc": @"0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6",
        @"saud": @"0xf48e200eaf9906362bb1442fca31e0835773b8b4",
        @"scex": @"0xeabacd844a196d7faf3ce596edebf9900341b420",
        @"imkr": @"0x0794d09be5395f69534ff8151d72613077148b29",
        @"ixrp": @"0x27269b3e45a4d3e79a3d6bfee0c8fb13d0d711a6",
        @"icex": @"0x336213e1ddfc69f4701fc3f86f4ef4a160c1159d",
        @"idash": @"0xcb98f42221b2c251a4e74a1609722ee09f0cc08e",
        @"ietc": @"0xd50c1746d835d2770dda3703b69187bffeb14126",
        @"ixmr": @"0x4adf728e2df4945082cdd6053869f51278fae196",
        @"sada": @"0xe36e2d3c7c34281fa3bc737950a68571736880a1",
        @"sbch": @"0x36a2422a863d5b950882190ff5433e513413343a",
        @"sdash": @"0xfe33ae95a9f0da8a845af33516edc240dcd711d6",
        @"seos": @"0x88c8cf3a212c0369698d13fe98fcb76620389841",
        @"setc": @"0x22602469d704bffb0936c7a7cfcd18f7aa269375",
        @"sftse": @"0x23348160d7f5aca21195df2b70f28fce2b0be9fc",
        @"snikkei": @"0x757de3ac6b830a931ef178c6634c5c551773155c",
        @"sxmr": @"0x5299d6f7472dcc137d7f3c4bcfbbb514babf341a",
        @"sxrp": @"0xa2b0fde6d710e201d0d608e924a484d1a5fed57c",
        @"schf": @"0x0f83287ff768d1c1e17a42f44d644d7f22e8ee1d",
        @"sjpy": @"0xf6b1c627e95bfc3c1b4c9b825a032ff0fbf3e07d",
        @"sxag": @"0x6a22e5e94388464181578aa7a6b869e00fe27846",
        @"strx": @"0xf2e08356588ec5cd9e437552da87c0076b4970b0",
        @"sltc": @"0xc14103c2141e842e228fbac594579e798616ce7a",
        @"ieth": @"0xa9859874e1743a32409f75bb11549892138bba1e",
        @"itrx": @"0xc5807183a9661a533cb08cbc297594a0b864dc12",
        @"ilink": @"0x2d7ac061fc3db53c39fe1607fb8cec1b2c162b01",
        @"sdefi": @"0xe1afe1fd76fd88f78cbf599ea1846231b8ba3b6b",
        @"sgbp": @"0x97fe22e7341a0cd8db6f6c021a24dc8f4dad855f",
        @"sxau": @"0x261efcdd24cea98652b9700800a13dfbca4103ff",
        @"sbnb": @"0x617aecb6137b5108d1e7d4918e3725c8cebdb848",
        @"sxtz": @"0x2e59005c5c0f0a4d77cca82653d48b46322ee5cd",
        @"slink": @"0xbbc455cb4f1b9e4bfc4b73970d360c8f032efee6",
        @"ibnb": @"0xafd870f32ce54efdbf677466b612bf8ad164454b",
        @"ixtz": @"0x8deef89058090ac5655a99eeb451a4f9183d1678",
        @"iltc": @"0x79da1431150c9b82d2e5dfc1c68b33216846851e",
        @"ieos": @"0xf4eebdd0704021ef2a6bbe993fdf93030cd784b4",
        @"idefi": @"0x14d10003807ac60d07bb0ba82caeac8d2087c157",
        @"usdx": @"0xeb269732ab75a6fd61ea60b06fe994cd32a83549",
        @"tusd": @"0x0000000000085d4780b73119b644ae5ecd22b376",
        @"busd": @"0x4fabb145d64652a948d72533023f6e7a623c7c53",
        @"met": @"0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e",
        @"zbtc": @"0x88c64a7d2ecc882d558dd16abc1537515a78bb7d",
        @"tln": @"0x679131F591B4f369acB8cd8c51E68596806c3916",
        @"aeth": @"0x3a3a65aab0dd2a17e3f1947ba16138cd37d08c04",
        @"adai": @"0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d",
        @"ausdc": @"0x9bA00D6856a4eDF4665BcA2C2309936572473B7E",
        @"asusd": @"0x625ae63000f46200499120b906716420bd059240",
        @"atusd": @"0x4DA9b813057D04BAef4e5800E36083717b4a0341",
        @"ausdt": @"0x71fc860f7d3a592a4a98740e39db31d25db65ae8",
        @"abat": @"0xe1ba0fb44ccb0d11b80f92f4f8ed94ca3ff51d00",
        @"aknc": @"0x9D91BE44C06d373a8a226E1f3b146956083803eB",
        @"alend": @"0x7D2D3688Df45Ce7C552E19c27e007673da9204B8",
        @"alink": @"0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84",
        @"amana": @"0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f",
        @"amkr": @"0x7deB5e830be29F91E298ba5FF1356BB7f8146998",
        @"arep": @"0x71010A9D003445aC60C4e6A7017c1E89A477B438",
        @"asnx": @"0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE",
        @"awbtc": @"0xFC4B8ED459e00e5400be803A9BB3954234FD50e3",
        @"azrx": @"0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f",
        @"tbc": @"0x627974847450c45b60b3fe3598f4e6e4cf945b9a",
        @"beth": @"0xc0829421c1d260bd3cb3e0f06cfe2d52db2ce315",
        @"lmy": @"0x66fd97a78d8854fec445cd1c80a07896b0b4851f",
        @"4xb": @"0xa3ac41fde5f3a569fa79e81ffe6734ee8097ce9d",
        @"ydaiv2": @"0x16de59092dae5ccf4a1e6439d611fd0653f0bd01",
        @"ydaiv3": @"0xc2cb1040220768554cf699b0d863a3cd4324ce32",
        @"ybusd": @"0x04bc0ab673d88ae9dbc9da2380cb6b79c4bca9ae",
        @"ybtc": @"0x04aa51bbcb46541455ccf1b8bef2ebc5d3787ec9",
        @"ytusd": @"0x73a052500105205d34daf004eab301916da8190f",
        @"yusdtv2": @"0x83f798e925bcd4017eb265844fddabb448f1707d",
        @"yusdtv3": @"0xe6354ed5bc4b393a5aad09f21c46e101e692d447",
        @"yusdcv2": @"0xd6ad7a6750a7593e092a9b218d66c0a814a3436e",
        @"yusdcv3": @"0x26ea744e5b887e5205727f55dfbe8685e3b21951",
        @"ysusd": @"0xf61718057901f84c4eec4339ef8f0d86d2b45600",
        @"ocrv": @"0x4ba8c6ce0e855c051e65dfc37883360efaf7c82b",
        @"cafe": @"0x0f7f08a1b784d2a51357efcfb5f4874cbf5dee28",
        @"etor": @"0x1d8f5b2bd72a7db787e4f42cce6be8474389353d",
        @"bdai": @"0x6a4ffaafa8dd400676df8076ad6c724867b0e2e8",
        @"ocdai": @"0x98cc3bd6af1880fcfda17ac477b2f612980e5e33",
        @"ocusdc": @"0x8ed9f862363ffdfd3a07546e618214b6d59f03d4",
        @"ubt": @"0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e",
        @"bcdt": @"0xacfa209fb73bf3dd5bbfb1101b9bc999c49062a5",
        @"lst": @"0x4de2573e27E648607B50e1Cfff921A33E4A34405",
        @"peak": @"0x633ee3fbe5ffc05bd44ecd8240732ff9ef9dee1d",
        @"pan": @"0xd56dac73a4d6766464b38ec6d91eb45ce7457c44",
        @"idledai": @"0x10ec0d497824e342bcb0edce00959142aaa766dd",
        @"idleusdc": @"0xeb66acc3d011056b00ea521f8203580c2e5d3991",
        @"btc++": @"0x0327112423f3a68efdf1fcf402f6c5cb9f7c33fd",
        @"gusd": @"0x056fd409e1d7a124bd7017459dfea2f387b6d5cd",
        @"abusd": @"0x6ee0f7bb50a54ab5253da0667b0dc2ee526c30a8",
        @"uma": @"0x04fa0d235c4abf4bcf4787af4cf447de572ef828",
        @"xpr": @"0xd7efb00d12c2c13131fd319336fdf952525da2af",
        @"cusdt": @"0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9",
        @"keep": @"0x85eee30c52b0b379b046fb0f85f4f3dc3009afec",
        @"renbtc": @"0xeb4c2781e4eba804ce9a9803c67d0893436bb27d",
        @"renzec": @"0x1c5db575e2ff833e46a2e9864c22f4b22e0b37c2",
        @"renbch": @"0x459086f2376525bdceba5bdda135e4e9d3fef5bf",
        @"tbtc": @"0x1bbe271d15bb64df0bc6cd28df9ff322f2ebd847",
        @"hbtc": @"0x0316eb71485b0ab14103307bf65a021042c6d380",
        @"ebase": @"0x86fadb80d8d2cff3c3680819e4da99c10232ba0f",
        @"shuf": @"0x3a9fff453d50d4ac52a6890647b823379ba36b9e",
        @"xbase": @"0x4d13d624a87baa278733c068a174412afa9ca6c8",
        @"donut": @"0xc0f9bd5fa5698b6505f643900ffa515ea5df54a9",
        @"husd": @"0xdf574c24545e5ffecb9a659c229253d4111d87e1",
        @"ethbtc-aug20":@"0x6d002a834480367fb1a1dc5f47e82fde39ec2c42",
        @"chi": @"0x0000000000004946c0e9f43f4dee607b0ef1fa1c",
        @"fxc": @"0x4a57e687b9126435a9b19e4a802113e266adebde",
        @"esh": @"0xd6a55c63865affd67e2fb9f284f87b7a9e5ff3bd",
        @"uax": @"0x1fc31488f28ac846588ffa201cde0669168471bd",
        @"2key": @"0xe48972fcd82a274411c01834e2f031d4377fa2c0",
        @"abt": @"0xb98d4c97425d9908e66e53a6fdf673acca0be986",
        @"abx": @"0x9a794dc1939f1d78fa48613b89b8f9d0a20da00e",
        @"abyss": @"0x0e8d6b471e332f140e7d9dbb99e5e3822f728da6",
        @"agri": @"0xa704fce7b309ec09df16e2f5ab8caf6fe8a4baa9",
        @"aid": @"0x37e8789bb9996cac9156cd5f5fd32599e6b91289",
        @"aix": @"0x1063ce524265d5a3a624f4914acd573dd89ce988",
        @"amn": @"0x737f98ac8ca59f2c68ad658e3c3d8c8963e40a4c",
        @"ampl": @"0xd46ba6d942050d489dbd938a2c909a5d5039a161",
        @"anj": @"0xcD62b1C403fa761BAadFC74C525ce2B51780b184",
        @"ank": @"0x3c45b24359fb0e107a4eaa56bd0f2ce66c99a0e5",
        @"ant": @"0x960b236a07cf122663c4303350609a66a7b288c0",
        @"appc": @"0x1a7a8bd9106f2b8d977e08582dc7d24c723ab0db",
        @"ast": @"0x27054b13b1b798b345b591a4d22e6562d47ea75a",
        @"ats": @"0x2daee1aa61d60a252dc80564499a69802853583a",
        @"auc": @"0xc12d099be31567add4e4e4d0d45691c3f58f5663",
        @"bam": @"0x22b3faaa8df978f6bafe18aade18dc2e3dfa0e0c",
        @"band": @"0xba11d00c5f74255f56a5e366f4f77f5a186d7f55",
        @"bat": @"0x0d8775f648430679a709e98d2b0cb6250d2887ef",
        @"bcdt": @"0xAcfa209Fb73bF3Dd5bBfb1101B9Bc999C49062a5",
        @"bcs": @"0x98bde3a768401260e7025faf9947ef1b81295519",
        @"betr": @"0x763186eb8d4856d536ed4478302971214febc6a9",
        @"blt": @"0x107c4504cd79C5d2696Ea0030a8dD4e92601B82e",
        @"blz": @"0x5732046a883704404f284ce41ffadd5b007fd668",
        @"bnt": @"0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c",
        @"boxx": @"0x780116d91e5592e58a3b3c76a351571b39abcec6",
        @"bqx": @"0x5af2be193a6abca9c8817001f45744777db30756",
        @"btc++": @"0x0327112423F3A68efdF1fcF402F6c5CB9f7C33fd",
        @"btu": @"0xb683d83a532e2cb7dfa5275eed3698436371cc9f",
        @"buidl": @"0xD6F0Bb2A45110f819e908a915237D652Ac7c5AA8",
        @"busd": @"0x4fabb145d64652a948d72533023f6e7a623c7c53",
        @"c20": @"0x26E75307Fc0C021472fEb8F727839531F112f317",
        @"can": @"0x1d462414fe14cf489c7a21cac78509f4bf8cd7c0",
        @"cat": @"0x1234567461d3f8db7496581774bd869c83d51c93",
        @"cbix7": @"0xCf8f9555D55CE45a3A33a81D6eF99a2a2E71Dee2",
        @"cdt": @"0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af",
        @"ceek": @"0xb056c38f6b7dc4064367403e26424cd2c60655e1",
        @"cel": @"0xaaAEBE6Fe48E54f431b0C390CfaF0b017d09D42d",
        @"chai": @"0x06AF07097C9Eeb7fD685c692751D5C66dB49c215",
        @"cncc": @"0xbe15c4Ebb73A67DDD94b83B237D2bdDe5a5079Ba",
        @"cnsl": @"0xeA0bea4d852687c45fdC57F6B06A8a92302baaBc",
        @"cot": @"0x5c872500c00565505f3624ab435c222e558e9ff8",
        @"cusd": @"0x5c406d99e04b8494dc253fcc52943ef82bca7d75",
        @"cvc": @"0x41e5560054824ea6b0732e656e3ad64e20e94e45",
        @"dai-hrd": @"0x9B869c2eaae08136C43d824EA75A2F376f1aA983",
        @"dat": @"0x81c9151de0c8bafcd325a57e3db5a5df1cebf79c",
        @"data": @"0x0cf0ee63788a0849fe5297f3407f701e122cc023",
        @"dev": @"0x5cAf454Ba92e6F2c929DF14667Ee360eD9fD5b26",
        @"dgd": @"0xe0b7927c4af23765cb51314a0e0521a9645f0e2a",
        @"dgx": @"0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf",
        @"drt": @"0x9af4f26941677c706cfecf6d3379ff01bb85d5ab",
        @"dta": @"0x69b148395ce0015c13e36bffbad63f49ef874e03",
        @"dtrc": @"0xc20464e0c373486d2b3335576e83a218b1618a5e",
        @"dxd": @"0xa1d65E8fB6e87b60FECCBc582F7f97804B725521",
        @"dzar": @"0x9Cb2f26A23b8d89973F08c957C4d7cdf75CD341c",
        @"dap": @"0x78a685E0762096ed0F98107212e98F8C35A9D1D8",
        @"ebase": @"0x86FADb80d8D2cff3C3680819E4da99C10232Ba0F",
        @"edo": @"0xced4e93198734ddaff8492d525bd258d49eb388e",
        @"efood": @"0x47ec6af8e27c98e41d1df7fb8219408541463022",
        @"eh2": @"0xA7d768EbD9915793393F117f8aB10F4A206875d8",
        @"ekg": @"0x6a9b3e36436b7abde8c4e2e2a98ea40455e615cf",
        @"elet": @"0x6c37bf4f042712c978a73e3fd56d1f5738dd7c43",
        @"elf": @"0xbf2179859fc6d5bee9bf9158632dc51678a4100e",
        @"emco": @"0x9a07fd8a116b7e3be9e6185861496af7a2041460",
        @"enj": @"0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c",
        @"equad": @"0xc28e931814725bbeb9e670676fabbcb694fe7df2",
        @"ethbtc-aug20": @"0x6d002a834480367fb1a1dC5F47E82Fde39EC2c42",
        @"eurs": @"0xdb25f211ab05b1c97d595516f45794528a807ad8",
        @"evo": @"0xefbd6d7def37ffae990503ecdb1291b2f7e38788",
        @"flixx": @"0xf04a8ac553fcedb5ba99a64799155826c136b0be",
        @"foam": @"0x4946Fcea7C692606e8908002e55A582af44AC121",
        @"ftx": @"0xd559f20296ff4895da39b5bd9add54b442596a61",
        @"fun": @"0x419D0d8BdD9aF5e606Ae2232ed285Aff190E711b",
        @"fuse": @"0x970B9bB2C0444F5E81e9d0eFb84C8ccdcdcAf84d",
        @"fxc": @"0x4a57e687b9126435a9b19e4a802113e266adebde",
        @"gdc": @"0x301c755ba0fca00b1923768fffb3df7f4e63af31",
        @"gen": @"0x543ff227f64aa17ea132bf9886cab5db55dcaddf",
        @"ges": @"0xfb1e5f5e984c28ad7e228cdaa1f8a0919bb6a09b",
        @"ghost": @"0x4c327471C44B2dacD6E90525f9D629bd2e4f662C",
        @"ght": @"0xbe30f684d62c9f7883a75a29c162c332c0d98f23",
        @"gno": @"0x6810e776880c02933d47db1b9fc05908e5386b96",
        @"grid": @"0x12b19d3e2ccc14da04fae33e63652ce469b3f2fd",
        @"grig": @"0x618acb9601cb54244f5780f09536db07d2c7acf4",
        @"gst2": @"0x0000000000b3F879cb30FE243b4Dfee438691c04",
        @"gto": @"0xc5bbae50781be1669306b9e001eff57a2957b09d",
        @"h3x": @"0x85eBa557C06c348395fD49e35d860F58a4F7c95a",
        @"hedg": @"0xf1290473e210b2108a85237fbcd7b6eb42cc654f",
        @"hex": @"0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39",
        @"hex2t": @"0xEd1199093b1aBd07a368Dd1C0Cdc77D8517BA2A0",
        @"hot": @"0x6c6EE5e31d828De241282B9606C8e98Ea48526E2",
        @"ick": @"0x793e2602A8396468f3CE6E34C1B6C6Fd6D985bAD",
        @"ind": @"0xf8e386eda857484f5a12e4b5daa9984e06e73705",
        @"instar": @"0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d",
        @"iost": @"0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab",
        @"isla": @"0x697eF32B4a3F5a4C39dE1cB7563f24CA7BfC5947",
        @"j8t": @"0x0d262e5dc4a06a0f1c90ce79c7a60c09dfc884e4",
        @"jrt": @"0x8A9C67fee641579dEbA04928c4BC45F66e26343A",
        @"key": @"0x4cc19356f2d37338b9802aa8e8fc58b0373296e7",
        @"kind": @"0x4618519de4c304f3444ffa7f812dddc2971cc688",
        @"knc": @"0xdd974d5c2e2928dea5f71b9825b8b646686bd200",
        @"ldc": @"0x5102791ca02fc3595398400bfe0e33d7b6c82267",
        @"lend": @"0x80fb784b7ed66730e8b1dbd9820afd29931aab03",
        @"link": @"0x514910771af9ca656af840dff83e8264ecf986ca",
        @"loc": @"0x5e3346444010135322268a4630d2ed5f8d09446c",
        @"loci": @"0x9c23d67aea7b95d80942e3836bcdf7e708a747c2",
        @"loom": @"0xa4e8c3ec456107ea67d3075bf9e3df3a75823db0",
        @"lqd": @"0xD29F0b5b3F50b07Fe9a9511F7d86F4f4bAc3f8c4",
        @"lrc": @"0xbbbbca6a901c926f240b89eacb641d8aec7aeafd",
        @"mana": @"0x0f5d2fb29fb7d3cfee444a200298f468908cc942",
        @"math": @"0x08d967bb0134F2d07f7cfb6E246680c53927DD30",
        @"mco": @"0xb63b606ac810a52cca15e44bb630fd42d8d1d83d",
        @"mcx": @"0xd15eCDCF5Ea68e3995b2D0527A0aE0a3258302F8",
        @"mdt": @"0x814e0908b12a99fecf5bc101bb5d0b8b5cdf7d26",
        @"met": @"0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e",
        @"mfg": @"0x6710c63432a2de02954fc0f851db07146a6c0312",
        @"mft": @"0xdf2c7238198ad8b389666574f2d8bc411a4b7428",
        @"mkr": @"0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2",
        @"mln": @"0xec67005c4e498ec7f55e092bd1d35cbc47c91892",
        @"mntp": @"0x83cee9e086a77e492ee0bb93c2b0437ad6fdeccc",
        @"mod": @"0x957c30aB0426e0C93CD8241E2c60392d08c6aC8e",
        @"mps": @"0x96c645D3D3706f793Ef52C19bBACe441900eD47D",
        @"mrg": @"0xcbee6459728019cb1f2bb971dde2ee3271bc7617",
        @"mrph": @"0x7b0c06043468469967dba22d1af33d77d44056c8",
        @"mtl": @"0xf433089366899d83a9f26a773d59ec7ecf30355e",
        @"myb": @"0x5d60d8d7ef6d37e16ebabc324de3be57f135e0bc",
        @"nec": @"0xCc80C051057B774cD75067Dc48f8987C4Eb97A5e",
        @"nexo": @"0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206",
        @"nexxo": @"0x278a83b64c3e3e1139f8e8a52d96360ca3c69a3d",
        @"nmr": @"0x1776e1f26f98b1a5df9cd347953a26dd3cb46671",
        @"npxs": @"0xa15c7ebe1f07caf6bff097d8a589fb8ac49ae5b3",
        @"ocean": @"0x985dd3D42De1e256d09e1c10F112bCCB8015AD41",
        @"ogn": @"0x8207c1ffc5b6804f6024322ccf34f29c3541ae26",
        @"omg": @"0xd26114cd6ee289accf82350c8d8487fedb8a0c07",
        @"ong": @"0xd341d1680eeee3255b8c4c75bcce7eb57f144dae",
        @"ost": @"0x2c4e8f2d746113d0696ce89b35f0d8bf88e0aeca",
        @"oxt": @"0x4575f41308EC1483f3d399aa9a2826d74Da13Deb",
        @"pamp": @"0xCe833222051740Aa5427D089A46fF3918763107f",
        @"pan": @"0xD56daC73A4d6766464b38ec6D91eB45Ce7457c44",
        @"pas": @"0xE25dB4bAA49EA3B8627986ffC22c7bd5E0c88d49",
        @"pax": @"0x8e870d67f660d95d5be530380d0ec0bd388289e1",
        @"paxg": @"0x45804880De22913dAFE09f4980848ECE6EcbAf78",
        @"pay": @"0xb97048628db6b661d4c2aa833e95dbe1a905b280",
        @"pbtc": @"0x5228a22e72ccc52d415ecfd199f99d0665e7733b",
        @"peg": @"0x8ae56a6850a7cbeac3c3ab2cb311e7620167eac8",
        @"pegusd": @"0xa485bd50228440797abb4d4595161d7546811160",
        @"plr": @"0xe3818504c1b32bf1557b16c238b2e01fd3149c17",
        @"pnk": @"0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d",
        @"poa20": @"0x6758b7d441a9739b98552b373703d8d3d14f9e62",
        @"poly": @"0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec",
        @"power": @"0xF2f9A7e93f845b3ce154EfbeB64fB9346FCCE509",
        @"powr": @"0x595832f8fc6bf59c85c527fec3740a1b7a361269",
        @"prtl": @"0xf01d7939441a3b1b108c70a28dcd99c6a98ad4b4",
        @"pt": @"0x094c875704c14783049ddf8136e298b3a099c446",
        @"publx": @"0x1a6658F40e51b372E593B7d2144c1402d5cf33E8",
        @"qdao": @"0x3166c570935a7d8554c8f4ea792ff965d2efe1f2",
        @"qkc": @"0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664",
        @"qnt": @"0x4a220e6096b25eadb88358cb44068a3248254675",
        @"rae": @"0xe5a3229ccb22b6484594973a03a3851dcd948756",
        @"raise": @"0x10bA8C420e912bF07BEdaC03Aa6908720db04e0c",
        @"rblx": @"0xfc2c4d8f95002c14ed0a7aa65102cac9e5953b5e",
        @"rcn": @"0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6",
        @"rdn": @"0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6",
        @"real": @"0x9214ec02cb71cba0ada6896b8da260736a67ab10",
        @"ref": @"0x89303500a7abfb178b274fd89f2469c264951e1f",
        @"rel": @"0xb6c4267C4877BB0D6b1685Cfd85b0FBe82F105ec",
        @"rem": @"0x83984d6142934bb535793a82adb0a46ef0f66b6d",
        @"ren": @"0x408e41876cccdc0f92210600ef50372656052a38",
        @"rep": @"0x1985365e9f78359a9b6ad760e32412f4a445e862",
        @"req": @"0x8f8221afbb33998d8584a2b05749ba73c37a938a",
        @"rkfl": @"0xdbf0fac1499a931ed6e5F6122dbbCD3B80f66c7E",
        @"rlc": @"0x607f4c5bb672230e8672085532f7e901544a7375",
        @"rpl": @"0xb4efd85c19999d84251304bda99e90b92300bd93",
        @"rsr": @"0x8762db106b2c2a0bccb3a80d1ed41273552616e8",
        @"rsv": @"0x1c5857e110cd8411054660f60b5de6a6958cfae2",
        @"rvt": @"0x3d1ba9be9f66b8ee101911bc36d3fb562eac2244",
        @"salt": @"0x4156D3342D5c385a87D264F90653733592000581",
        @"san": @"0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098",
        @"scl": @"0xd7631787b4dcc87b1254cfd1e5ce48e96823dee8",
        @"seeds": @"0x61404D2D3f2100b124D6827D3F2DDf6233cd71C0",
        @"shuf": @"0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E",
        @"skull": @"0xBcc66ed2aB491e9aE7Bf8386541Fb17421Fa9d35",
        @"snt": @"0x744d70fdbe2ba4cf95131626614a1763df805b9e",
        @"snx": @"0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f",
        @"socks": @"0x23B608675a2B2fB1890d3ABBd85c5775c51691d5",
        @"spank": @"0x42d6622deCe394b54999Fbd73D108123806f6a18",
        @"spd": @"0x1dea979ae76f26071870f824088da78979eb91c8",
        @"spike": @"0xa7fc5d2453e3f68af0cc1b78bcfee94a1b293650",
        @"spn": @"0x20f7a3ddf244dc9299975b4da1c39f8d5d75f05a",
        @"srn": @"0x68d57c9a1c35f63e2c83ee8e49a64e9d70528d25",
        @"stac": @"0x9a005c9a89bd72a4bd27721e7a09a3c11d2b03c4",
        @"stake": @"0x0Ae055097C6d159879521C384F1D2123D1f195e6",
        @"storj": @"0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC",
        @"storm": @"0xd0a4b8946cb52f0661273bfbc6fd0e0c75fc6433",
        @"stx": @"0x006bea43baa3f7a6f765f14f10a1a1b08334ef45",
        @"sun": @"0xC91b28c9de2E040be451B9d8e285d2E9e54Cb48d",
        @"svd": @"0xbdeb4b83251fb146687fa19d1c660f99411eefe3",
        @"sxl": @"0x222efe83d8cc48e422419d65cf82d410a276499b",
        @"subs": @"0x61CEAc48136d6782DBD83c09f51E23514D12470a",
        @"tape": @"0x9Bfb088C9f311415E3F9B507DA73081c52a49d8c",
        @"tbx": @"0x3a92bd396aef82af98ebc0aa9030d25a23b11c6b",
        @"tgbp": @"0x00000000441378008EA67F4284A57932B1c000a5",
        @"tkn": @"0xaaaf91d9b90df800df4f55c205fd6989c977e73a",
        @"tkx": @"0x667102bd3413bfeaa3dffb48fa8288819e480a88",
        @"tns": @"0xb0280743b44bf7db4b6be482b2ba7b75e5da096c",
        @"tnt": @"0x08f5a9235B08173b7569F83645d2c7fB55e8cCD8",
        @"trac": @"0xaA7a9CA87d3694B5755f213B5D04094b8d0F0A6F",
        @"trb": @"0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5",
        @"trst": @"0xCb94be6f13A1182E4A4B6140cb7bf2025d28e41B",
        @"tryb": @"0x2c537e5624e4af88a7ae4060c022609376c8d0eb",
        @"tusd": @"0x8dd5fbce2f6a956c3022ba3663759011dd51e73e",
        @"ubt": @"0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e",
        @"ult": @"0x09617F6fD6cF8A71278ec86e23bBab29C04353a7",
        @"uma": @"0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828",
        @"up": @"0x6ba460ab75cd2c56343b3517ffeba60748654d26",
        @"upp": @"0xc86d054809623432210c107af2e3f619dcfbf652",
        @"upt": @"0x67abf1c62d8acd07ada35908d38cd67be7dfeb36",
        @"usdb": @"0x309627af60f0926daa6041b8279484312f2bf060",
        @"usdc": @"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        @"usdq": @"0x4954db6391f4feb5468b6b943d4935353596aec9",
        @"usds": @"0xa4bdb11dc0a2bec88d24a3aa1e6bb17201112ebe",
        @"usdt": @"0xdac17f958d2ee523a2206206994597c13d831ec7",
        @"vee": @"0x340d2bde5eb28c1eed91b2f790723e3b160613b7",
        @"veth": @"0x31Bb711de2e457066c6281f231fb473FC5c2afd3",
        @"vib": @"0x2c974b2d0ba1716e644c1fc59982a89ddd2ff724",
        @"vxv": @"0x7D29A64504629172a429e64183D6673b9dAcbFCe",
        @"wand": @"0x27f610bf36eca0939093343ac28b1534a721dbb4",
        @"wbomb": @"0xbBB38bE7c6D954320c0297c06Ab3265a950CDF89",
        @"wbtc": @"0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        @"weth": @"0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        @"wings": @"0x667088b212ce3d06a1b553a7221e1fd19000d9af",
        @"wlk": @"0xf6b55acbbc49f4524aa48d19281a9a77c54de10f",
        @"x8x": @"0x910dfc18d6ea3d6a7124a6f8b5458f281060fa4c",
        @"xbase": @"0x4D13d624a87baa278733c068A174412AfA9ca6C8",
        @"xbp": @"0x28dee01d53fed0edf5f6e310bf8ef9311513ae40",
        @"xchf": @"0xB4272071eCAdd69d933AdcD19cA99fe80664fc08",
        @"xdce": @"0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2",
        @"xio": @"0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704",
        @"xnk": @"0xbc86727e770de68b1060c91f6bb6945c73e10388",
        @"xor": @"0x40FD72257597aA14C7231A7B1aaa29Fce868F677",
        @"xpat": @"0xbb1fa4fdeb3459733bf67ebc6f893003fa976a82",
        @"xrt": @"0x7dE91B204C1C737bcEe6F000AAA6569Cf7061cb7",
        @"zcc": @"0x6737fE98389Ffb356F64ebB726aA1a92390D94Fb",
        @"zinc": @"0x4aac461c86abfa71e9d00d9a2cde8d74e4e1aeea",
        @"zipt": @"0xedd7c94fd7b4971b916d15067bc454b9e1bad980",
        @"zrx": @"0xe41d2489571d322189246dafa5ebde1f4699f498",
        @"adai": @"0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d",
        @"isai": @"0x14094949152EDDBFcd073717200DA82fEd8dC960",
        @"musd": @"0xe2f2a5C287993345a840Db3B0845fbC70f5935a5",
        @"renbtc": @"0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D",
        @"seth": @"0x42456D7084eacF4083f1140d3229471bbA2949A8",
        @"sxau": @"0x261EfCdD24CeA98652B9700800a13DfBca4103fF",
        @"gst2": @"0x0000000000b3F879cb30FE243b4Dfee438691c04",
        @"tgbp": @"0x00000000441378008EA67F4284A57932B1c000a5",
        @"stx": @"0x006bea43baa3f7a6f765f14f10a1a1b08334ef45",
        @"btc++": @"0x0327112423F3A68efdF1fcF402F6c5CB9f7C33fd",
        @"uma": @"0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828",
        @"chai": @"0x06AF07097C9Eeb7fD685c692751D5C66dB49c215",
        @"math": @"0x08d967bb0134F2d07f7cfb6E246680c53927DD30",
        @"tnt": @"0x08f5a9235B08173b7569F83645d2c7fB55e8cCD8",
        @"pt": @"0x094c875704c14783049ddf8136e298b3a099c446",
        @"ult": @"0x09617F6fD6cF8A71278ec86e23bBab29C04353a7",
        @"stake": @"0x0Ae055097C6d159879521C384F1D2123D1f195e6",
        @"trb": @"0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5",
        @"data": @"0x0cf0ee63788a0849fe5297f3407f701e122cc023",
        @"j8t": @"0x0d262e5dc4a06a0f1c90ce79c7a60c09dfc884e4",
        @"bat": @"0x0d8775f648430679a709e98d2b0cb6250d2887ef",
        @"abyss": @"0x0e8d6b471e332f140e7d9dbb99e5e3822f728da6",
        @"mana": @"0x0f5d2fb29fb7d3cfee444a200298f468908cc942",
        @"xio": @"0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704",
        @"aix": @"0x1063ce524265d5a3a624f4914acd573dd89ce988",
        @"blt": @"0x107c4504cd79C5d2696Ea0030a8dD4e92601B82e",
        @"raise": @"0x10bA8C420e912bF07BEdaC03Aa6908720db04e0c",
        @"cat": @"0x1234567461d3f8db7496581774bd869c83d51c93",
        @"grid": @"0x12b19d3e2ccc14da04fae33e63652ce469b3f2fd",
        @"isai": @"0x14094949152EDDBFcd073717200DA82fEd8dC960",
        @"nmr": @"0x1776e1f26f98b1a5df9cd347953a26dd3cb46671",
        @"cdt": @"0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af",
        @"rep": @"0x1985365e9f78359a9b6ad760e32412f4a445e862",
        @"publx": @"0x1a6658F40e51b372E593B7d2144c1402d5cf33E8",
        @"appc": @"0x1a7a8bd9106f2b8d977e08582dc7d24c723ab0db",
        @"rsv": @"0x1c5857e110cd8411054660f60b5de6a6958cfae2",
        @"can": @"0x1d462414fe14cf489c7a21cac78509f4bf8cd7c0",
        @"spd": @"0x1dea979ae76f26071870f824088da78979eb91c8",
        @"bnt": @"0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c",
        @"spn": @"0x20f7a3ddf244dc9299975b4da1c39f8d5d75f05a",
        @"sxl": @"0x222efe83d8cc48e422419d65cf82d410a276499b",
        @"wbtc": @"0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        @"bam": @"0x22b3faaa8df978f6bafe18aade18dc2e3dfa0e0c",
        @"socks": @"0x23B608675a2B2fB1890d3ABBd85c5775c51691d5",
        @"rdn": @"0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6",
        @"sxau": @"0x261EfCdD24CeA98652B9700800a13DfBca4103fF",
        @"c20": @"0x26E75307Fc0C021472fEb8F727839531F112f317",
        @"ast": @"0x27054b13b1b798b345b591a4d22e6562d47ea75a",
        @"nexxo": @"0x278a83b64c3e3e1139f8e8a52d96360ca3c69a3d",
        @"wand": @"0x27f610bf36eca0939093343ac28b1534a721dbb4",
        @"xbp": @"0x28dee01d53fed0edf5f6e310bf8ef9311513ae40",
        @"hex": @"0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39",
        @"ost": @"0x2c4e8f2d746113d0696ce89b35f0d8bf88e0aeca",
        @"tryb": @"0x2c537e5624e4af88a7ae4060c022609376c8d0eb",
        @"vib": @"0x2c974b2d0ba1716e644c1fc59982a89ddd2ff724",
        @"ats": @"0x2daee1aa61d60a252dc80564499a69802853583a",
        @"gdc": @"0x301c755ba0fca00b1923768fffb3df7f4e63af31",
        @"usdb": @"0x309627af60f0926daa6041b8279484312f2bf060",
        @"qdao": @"0x3166c570935a7d8554c8f4ea792ff965d2efe1f2",
        @"veth": @"0x31Bb711de2e457066c6281f231fb473FC5c2afd3",
        @"vee": @"0x340d2bde5eb28c1eed91b2f790723e3b160613b7",
        @"aid": @"0x37e8789bb9996cac9156cd5f5fd32599e6b91289",
        @"shuf": @"0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E",
        @"tbx": @"0x3a92bd396aef82af98ebc0aa9030d25a23b11c6b",
        @"ank": @"0x3c45b24359fb0e107a4eaa56bd0f2ce66c99a0e5",
        @"rvt": @"0x3d1ba9be9f66b8ee101911bc36d3fb562eac2244",
        @"ren": @"0x408e41876cccdc0f92210600ef50372656052a38",
        @"xor": @"0x40FD72257597aA14C7231A7B1aaa29Fce868F677",
        @"salt": @"0x4156D3342D5c385a87D264F90653733592000581",
        @"fun": @"0x419D0d8BdD9aF5e606Ae2232ed285Aff190E711b",
        @"xdce": @"0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2",
        @"cvc": @"0x41e5560054824ea6b0732e656e3ad64e20e94e45",
        @"seth": @"0x42456D7084eacF4083f1140d3229471bbA2949A8",
        @"spank": @"0x42d6622deCe394b54999Fbd73D108123806f6a18",
        @"oxt": @"0x4575f41308EC1483f3d399aa9a2826d74Da13Deb",
        @"paxg": @"0x45804880De22913dAFE09f4980848ECE6EcbAf78",
        @"kind": @"0x4618519de4c304f3444ffa7f812dddc2971cc688",
        @"efood": @"0x47ec6af8e27c98e41d1df7fb8219408541463022",
        @"foam": @"0x4946Fcea7C692606e8908002e55A582af44AC121",
        @"usdq": @"0x4954db6391f4feb5468b6b943d4935353596aec9",
        @"xbase": @"0x4D13d624a87baa278733c068A174412AfA9ca6C8",
        @"qnt": @"0x4a220e6096b25eadb88358cb44068a3248254675",
        @"fxc": @"0x4a57e687b9126435a9b19e4a802113e266adebde",
        @"zinc": @"0x4aac461c86abfa71e9d00d9a2cde8d74e4e1aeea",
        @"ghost": @"0x4c327471C44B2dacD6E90525f9D629bd2e4f662C",
        @"key": @"0x4cc19356f2d37338b9802aa8e8fc58b0373296e7",
        @"dgx": @"0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf",
        @"busd": @"0x4fabb145d64652a948d72533023f6e7a623c7c53",
        @"ldc": @"0x5102791ca02fc3595398400bfe0e33d7b6c82267",
        @"link": @"0x514910771af9ca656af840dff83e8264ecf986ca",
        @"pbtc": @"0x5228a22e72ccc52d415ecfd199f99d0665e7733b",
        @"gen": @"0x543ff227f64aa17ea132bf9886cab5db55dcaddf",
        @"blz": @"0x5732046a883704404f284ce41ffadd5b007fd668",
        @"powr": @"0x595832f8fc6bf59c85c527fec3740a1b7a361269",
        @"bqx": @"0x5af2be193a6abca9c8817001f45744777db30756",
        @"cusd": @"0x5c406d99e04b8494dc253fcc52943ef82bca7d75",
        @"cot": @"0x5c872500c00565505f3624ab435c222e558e9ff8",
        @"dev": @"0x5cAf454Ba92e6F2c929DF14667Ee360eD9fD5b26",
        @"myb": @"0x5d60d8d7ef6d37e16ebabc324de3be57f135e0bc",
        @"loc": @"0x5e3346444010135322268a4630d2ed5f8d09446c",
        @"rlc": @"0x607f4c5bb672230e8672085532f7e901544a7375",
        @"seeds": @"0x61404D2D3f2100b124D6827D3F2DDf6233cd71C0",
        @"grig": @"0x618acb9601cb54244f5780f09536db07d2c7acf4",
        @"subs": @"0x61CEAc48136d6782DBD83c09f51E23514D12470a",
        @"wings": @"0x667088b212ce3d06a1b553a7221e1fd19000d9af",
        @"tkx": @"0x667102bd3413bfeaa3dffb48fa8288819e480a88",
        @"mfg": @"0x6710c63432a2de02954fc0f851db07146a6c0312",
        @"zcc": @"0x6737fE98389Ffb356F64ebB726aA1a92390D94Fb",
        @"poa20": @"0x6758b7d441a9739b98552b373703d8d3d14f9e62",
        @"upt": @"0x67abf1c62d8acd07ada35908d38cd67be7dfeb36",
        @"gno": @"0x6810e776880c02933d47db1b9fc05908e5386b96",
        @"srn": @"0x68d57c9a1c35f63e2c83ee8e49a64e9d70528d25",
        @"isla": @"0x697eF32B4a3F5a4C39dE1cB7563f24CA7BfC5947",
        @"dta": @"0x69b148395ce0015c13e36bffbad63f49ef874e03",
        @"ekg": @"0x6a9b3e36436b7abde8c4e2e2a98ea40455e615cf",
        @"up": @"0x6ba460ab75cd2c56343b3517ffeba60748654d26",
        @"elet": @"0x6c37bf4f042712c978a73e3fd56d1f5738dd7c43",
        @"hot": @"0x6c6EE5e31d828De241282B9606C8e98Ea48526E2",
        @"ethbtc-aug20": @"0x6d002a834480367fb1a1dC5F47E82Fde39EC2c42",
        @"amn": @"0x737f98ac8ca59f2c68ad658e3c3d8c8963e40a4c",
        @"snt": @"0x744d70fdbe2ba4cf95131626614a1763df805b9e",
        @"betr": @"0x763186eb8d4856d536ed4478302971214febc6a9",
        @"boxx": @"0x780116d91e5592e58a3b3c76a351571b39abcec6",
        @"dap": @"0x78a685E0762096ed0F98107212e98F8C35A9D1D8",
        @"ick": @"0x793e2602A8396468f3CE6E34C1B6C6Fd6D985bAD",
        @"vxv": @"0x7D29A64504629172a429e64183D6673b9dAcbFCe",
        @"mrph": @"0x7b0c06043468469967dba22d1af33d77d44056c8",
        @"san": @"0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098",
        @"xrt": @"0x7dE91B204C1C737bcEe6F000AAA6569Cf7061cb7",
        @"lend": @"0x80fb784b7ed66730e8b1dbd9820afd29931aab03",
        @"mdt": @"0x814e0908b12a99fecf5bc101bb5d0b8b5cdf7d26",
        @"dat": @"0x81c9151de0c8bafcd325a57e3db5a5df1cebf79c",
        @"ogn": @"0x8207c1ffc5b6804f6024322ccf34f29c3541ae26",
        @"rem": @"0x83984d6142934bb535793a82adb0a46ef0f66b6d",
        @"mntp": @"0x83cee9e086a77e492ee0bb93c2b0437ad6fdeccc",
        @"ubt": @"0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e",
        @"h3x": @"0x85eBa557C06c348395fD49e35d860F58a4F7c95a",
        @"ebase": @"0x86FADb80d8D2cff3C3680819E4da99C10232Ba0F",
        @"rsr": @"0x8762db106b2c2a0bccb3a80d1ed41273552616e8",
        @"ref": @"0x89303500a7abfb178b274fd89f2469c264951e1f",
        @"jrt": @"0x8A9C67fee641579dEbA04928c4BC45F66e26343A",
        @"peg": @"0x8ae56a6850a7cbeac3c3ab2cb311e7620167eac8",
        @"tusd": @"0x8dd5fbce2f6a956c3022ba3663759011dd51e73e",
        @"pax": @"0x8e870d67f660d95d5be530380d0ec0bd388289e1",
        @"req": @"0x8f8221afbb33998d8584a2b05749ba73c37a938a",
        @"x8x": @"0x910dfc18d6ea3d6a7124a6f8b5458f281060fa4c",
        @"real": @"0x9214ec02cb71cba0ada6896b8da260736a67ab10",
        @"pnk": @"0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d",
        @"mod": @"0x957c30aB0426e0C93CD8241E2c60392d08c6aC8e",
        @"ant": @"0x960b236a07cf122663c4303350609a66a7b288c0",
        @"mps": @"0x96c645D3D3706f793Ef52C19bBACe441900eD47D",
        @"fuse": @"0x970B9bB2C0444F5E81e9d0eFb84C8ccdcdcAf84d",
        @"ocean": @"0x985dd3D42De1e256d09e1c10F112bCCB8015AD41",
        @"bcs": @"0x98bde3a768401260e7025faf9947ef1b81295519",
        @"poly": @"0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec",
        @"dai-hrd": @"0x9B869c2eaae08136C43d824EA75A2F376f1aA983",
        @"tape": @"0x9Bfb088C9f311415E3F9B507DA73081c52a49d8c",
        @"dzar": @"0x9Cb2f26A23b8d89973F08c957C4d7cdf75CD341c",
        @"stac": @"0x9a005c9a89bd72a4bd27721e7a09a3c11d2b03c4",
        @"emco": @"0x9a07fd8a116b7e3be9e6185861496af7a2041460",
        @"abx": @"0x9a794dc1939f1d78fa48613b89b8f9d0a20da00e",
        @"drt": @"0x9af4f26941677c706cfecf6d3379ff01bb85d5ab",
        @"loci": @"0x9c23d67aea7b95d80942e3836bcdf7e708a747c2",
        @"mkr": @"0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2",
        @"eh2": @"0xA7d768EbD9915793393F117f8aB10F4A206875d8",
        @"bcdt": @"0xAcfa209Fb73bF3Dd5bBfb1101B9Bc999C49062a5",
        @"xchf": @"0xB4272071eCAdd69d933AdcD19cA99fe80664fc08",
        @"nexo": @"0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206",
        @"storj": @"0xB64ef51C888972c908CFacf59B47C1AfBC0Ab8aC",
        @"skull": @"0xBcc66ed2aB491e9aE7Bf8386541Fb17421Fa9d35",
        @"sun": @"0xC91b28c9de2E040be451B9d8e285d2E9e54Cb48d",
        @"trst": @"0xCb94be6f13A1182E4A4B6140cb7bf2025d28e41B",
        @"nec": @"0xCc80C051057B774cD75067Dc48f8987C4Eb97A5e",
        @"pamp": @"0xCe833222051740Aa5427D089A46fF3918763107f",
        @"cbix7": @"0xCf8f9555D55CE45a3A33a81D6eF99a2a2E71Dee2",
        @"lqd": @"0xD29F0b5b3F50b07Fe9a9511F7d86F4f4bAc3f8c4",
        @"pan": @"0xD56daC73A4d6766464b38ec6D91eB45Ce7457c44",
        @"buidl": @"0xD6F0Bb2A45110f819e908a915237D652Ac7c5AA8",
        @"pas": @"0xE25dB4bAA49EA3B8627986ffC22c7bd5E0c88d49",
        @"renbtc": @"0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D",
        @"hex2t": @"0xEd1199093b1aBd07a368Dd1C0Cdc77D8517BA2A0",
        @"power": @"0xF2f9A7e93f845b3ce154EfbeB64fB9346FCCE509",
        @"usdc": @"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        @"npxs": @"0xa15c7ebe1f07caf6bff097d8a589fb8ac49ae5b3",
        @"dxd": @"0xa1d65E8fB6e87b60FECCBc582F7f97804B725521",
        @"met": @"0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e",
        @"pegusd": @"0xa485bd50228440797abb4d4595161d7546811160",
        @"usds": @"0xa4bdb11dc0a2bec88d24a3aa1e6bb17201112ebe",
        @"loom": @"0xa4e8c3ec456107ea67d3075bf9e3df3a75823db0",
        @"agri": @"0xa704fce7b309ec09df16e2f5ab8caf6fe8a4baa9",
        @"spike": @"0xa7fc5d2453e3f68af0cc1b78bcfee94a1b293650",
        @"trac": @"0xaA7a9CA87d3694B5755f213B5D04094b8d0F0A6F",
        @"cel": @"0xaaAEBE6Fe48E54f431b0C390CfaF0b017d09D42d",
        @"tkn": @"0xaaaf91d9b90df800df4f55c205fd6989c977e73a",
        @"tns": @"0xb0280743b44bf7db4b6be482b2ba7b75e5da096c",
        @"ceek": @"0xb056c38f6b7dc4064367403e26424cd2c60655e1",
        @"rpl": @"0xb4efd85c19999d84251304bda99e90b92300bd93",
        @"mco": @"0xb63b606ac810a52cca15e44bb630fd42d8d1d83d",
        @"btu": @"0xb683d83a532e2cb7dfa5275eed3698436371cc9f",
        @"rel": @"0xb6c4267C4877BB0D6b1685Cfd85b0FBe82F105ec",
        @"pay": @"0xb97048628db6b661d4c2aa833e95dbe1a905b280",
        @"abt": @"0xb98d4c97425d9908e66e53a6fdf673acca0be986",
        @"wbomb": @"0xbBB38bE7c6D954320c0297c06Ab3265a950CDF89",
        @"band": @"0xba11d00c5f74255f56a5e366f4f77f5a186d7f55",
        @"xpat": @"0xbb1fa4fdeb3459733bf67ebc6f893003fa976a82",
        @"lrc": @"0xbbbbca6a901c926f240b89eacb641d8aec7aeafd",
        @"xnk": @"0xbc86727e770de68b1060c91f6bb6945c73e10388",
        @"svd": @"0xbdeb4b83251fb146687fa19d1c660f99411eefe3",
        @"cncc": @"0xbe15c4Ebb73A67DDD94b83B237D2bdDe5a5079Ba",
        @"ght": @"0xbe30f684d62c9f7883a75a29c162c332c0d98f23",
        @"elf": @"0xbf2179859fc6d5bee9bf9158632dc51678a4100e",
        @"snx": @"0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f",
        @"weth": @"0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        @"auc": @"0xc12d099be31567add4e4e4d0d45691c3f58f5663",
        @"dtrc": @"0xc20464e0c373486d2b3335576e83a218b1618a5e",
        @"equad": @"0xc28e931814725bbeb9e670676fabbcb694fe7df2",
        @"gto": @"0xc5bbae50781be1669306b9e001eff57a2957b09d",
        @"instar": @"0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d",
        @"upp": @"0xc86d054809623432210c107af2e3f619dcfbf652",
        @"anj": @"0xcD62b1C403fa761BAadFC74C525ce2B51780b184",
        @"mrg": @"0xcbee6459728019cb1f2bb971dde2ee3271bc7617",
        @"edo": @"0xced4e93198734ddaff8492d525bd258d49eb388e",
        @"storm": @"0xd0a4b8946cb52f0661273bfbc6fd0e0c75fc6433",
        @"mcx": @"0xd15eCDCF5Ea68e3995b2D0527A0aE0a3258302F8",
        @"omg": @"0xd26114cd6ee289accf82350c8d8487fedb8a0c07",
        @"ong": @"0xd341d1680eeee3255b8c4c75bcce7eb57f144dae",
        @"ampl": @"0xd46ba6d942050d489dbd938a2c909a5d5039a161",
        @"ftx": @"0xd559f20296ff4895da39b5bd9add54b442596a61",
        @"scl": @"0xd7631787b4dcc87b1254cfd1e5ce48e96823dee8",
        @"usdt": @"0xdac17f958d2ee523a2206206994597c13d831ec7",
        @"eurs": @"0xdb25f211ab05b1c97d595516f45794528a807ad8",
        @"rkfl": @"0xdbf0fac1499a931ed6e5F6122dbbCD3B80f66c7E",
        @"knc": @"0xdd974d5c2e2928dea5f71b9825b8b646686bd200",
        @"mft": @"0xdf2c7238198ad8b389666574f2d8bc411a4b7428",
        @"dgd": @"0xe0b7927c4af23765cb51314a0e0521a9645f0e2a",
        @"musd": @"0xe2f2a5C287993345a840Db3B0845fbC70f5935a5",
        @"plr": @"0xe3818504c1b32bf1557b16c238b2e01fd3149c17",
        @"zrx": @"0xe41d2489571d322189246dafa5ebde1f4699f498",
        @"2key": @"0xe48972fcd82a274411c01834e2f031d4377fa2c0",
        @"rae": @"0xe5a3229ccb22b6484594973a03a3851dcd948756",
        @"cnsl": @"0xeA0bea4d852687c45fdC57F6B06A8a92302baaBc",
        @"qkc": @"0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664",
        @"mln": @"0xec67005c4e498ec7f55e092bd1d35cbc47c91892",
        @"zipt": @"0xedd7c94fd7b4971b916d15067bc454b9e1bad980",
        @"evo": @"0xefbd6d7def37ffae990503ecdb1291b2f7e38788",
        @"prtl": @"0xf01d7939441a3b1b108c70a28dcd99c6a98ad4b4",
        @"flixx": @"0xf04a8ac553fcedb5ba99a64799155826c136b0be",
        @"hedg": @"0xf1290473e210b2108a85237fbcd7b6eb42cc654f",
        @"mtl": @"0xf433089366899d83a9f26a773d59ec7ecf30355e",
        @"enj": @"0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c",
        @"wlk": @"0xf6b55acbbc49f4524aa48d19281a9a77c54de10f",
        @"ind": @"0xf8e386eda857484f5a12e4b5daa9984e06e73705",
        @"rcn": @"0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6",
        @"adai": @"0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d",
        @"iost": @"0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab",
        @"ges": @"0xfb1e5f5e984c28ad7e228cdaa1f8a0919bb6a09b",
        @"rblx": @"0xfc2c4d8f95002c14ed0a7aa65102cac9e5953b5e",
    }[symbol.lowercaseString];
}

@end
