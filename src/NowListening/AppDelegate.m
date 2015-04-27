//
//  AppDelegate.m
//  NowListening
//
//  Created by K. Murakami on 2/28/15.
//  Copyright (c) 2015 Himajinworks. All rights reserved.
//

#import "AppDelegate.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

/**
 *  With : sdef /Applications/iTunes.app | sdp -fh --basename iTunes
 */
#import "iTunes.h"

static const NSString *kiTunesPlayerInfoNotification = @"com.apple.iTunes.playerInfo";
static const NSString *kiTunesApplicationIdentifier  = @"com.apple.iTunes";
static const NSString *kPlaybackNotFoundString       = @"No playback found";

static const NSString *kTwitterPostURL = @"https://api.twitter.com/1.1/statuses/update.json";

static const NSString *kTwitterHashTag = @"#0w0_listening";

@interface AppDelegate ()
{
    NSStatusItem        *statusItem;
    NSDictionary        *currentSongInformation;
    NSMutableDictionary *twitterAccountDictionary;
}

@property (weak) IBOutlet NSWindow   *window;
@property (weak) IBOutlet NSMenu     *statusMenu;
@property (weak) IBOutlet NSMenuItem *currentSongItem;

/**
 *  This method initializes application
 */
- (void)setupApplication;

/**
 *  This method registers observer for iTunes update
 */
- (void)registeriTunesPlaybackNotification;

/**
 *  This method sets up application on status bar
 */
- (void)setupStatusBarItem;

/**
 *  This method will fetch iTunes update information
 *
 *  @param notification Update notification
 */
- (void)updateTrackInfo:(NSNotification *)notification;

/**
 *  This method updates current song information UI
 */
- (void)updateDisplayedCurrentSong;

/**
 *  This method returns iTunes application object
 *
 *  @return iTunes application object
 */
+ (iTunesApplication *)iTunesApplicationObject;

/**
 *  This method returns current song information as dictionary
 *
 *  @return Current song information
 */
+ (NSDictionary *)currentSongInfo;

/**
 *  This method creates song information dictionary with given parameters
 *
 *  @param aSongName  Song name / title
 *  @param aAlbumName Album name
 *
 *  @return created song information dictionary
 */
+ (NSDictionary *)songInfoDictionaryWithSongName:(NSString *)aSongName
                                       AlbumName:(NSString *)aAlbumName;

/**
 *  This method renders song information as string
 *
 *  @return Rendered string
 */
- (NSString *)prettySongString;

/**
 *  This method returns twitter account list in OSX
 *
 *  @param aCompletion A completion, invoked after fetching twitter accounts
 */
- (void)twitterAccountListWithCompletion:(void (^)(NSArray *aAccounts))aCompletion;

/**
 *  This method posting current song information to twitter
 *
 *  @param sender Sender object (Must be NSMenuItem)
 */
- (void)postTwitterWithSender:(id)sender;

@end

@implementation AppDelegate

#pragma mark - Application lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // Setup
    [self setupApplication];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Initializer

- (void)setupApplication
{
    // Initialize class fields
    currentSongInformation   = nil;
    twitterAccountDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    // Setup UI
    [self setupStatusBarItem];
    [self updateDisplayedCurrentSong];
    
    // Setup iTunes notification
    [self registeriTunesPlaybackNotification];
    
    // Prepare twitter account information
    [self twitterAccountListWithCompletion:^(NSArray *aAccounts) {
        for (ACAccount *account in aAccounts) {
            twitterAccountDictionary[account.username] = account;
            
            // Set twitter inforamtion to UI
            [self.currentSongItem.submenu addItemWithTitle:account.username
                                                    action:@selector(postTwitterWithSender:)
                                             keyEquivalent:@""];
        }
    }];
}

- (void)registeriTunesPlaybackNotification
{
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    
    [dnc addObserver:self
            selector:@selector(updateTrackInfo:)
                name:(NSString *)kiTunesPlayerInfoNotification
              object:nil];
}

- (void)setupStatusBarItem
{
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    
    statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    
    [statusItem setHighlightMode:YES];
    [statusItem setTitle:@"♮"];
    [statusItem setMenu:self.statusMenu];
}

#pragma mark - iTunes track information handler

- (void)updateTrackInfo:(NSNotification *)notification
{
    NSDictionary *information = [notification userInfo];
    
    if ([information[@"Player State"] isEqualToString:@"Stopped"]) {
        // If player is stopped, then return stopped stateus string
        currentSongInformation = nil;
        [self updateDisplayedCurrentSong];
        
    } else {
        // Else, store curent song information
        currentSongInformation = [AppDelegate songInfoDictionaryWithSongName:information[@"Name"]
                                                                   AlbumName:information[@"Album"]];

        // And update information on UI
        [self updateDisplayedCurrentSong];
    }
}

- (void)updateDisplayedCurrentSong
{
    NSString *songString     = [self prettySongString];
    BOOL      toHideSongItem = [songString isEqualToString:(NSString *)kPlaybackNotFoundString];
    
    [self.currentSongItem setHidden:toHideSongItem];
    [self.currentSongItem setTitle:songString];
}

+ (iTunesApplication *)iTunesApplicationObject
{
    iTunesApplication *app = [SBApplication applicationWithBundleIdentifier:(NSString *)kiTunesApplicationIdentifier];
    
    return app;
}

+ (NSDictionary *)currentSongInfo
{
    iTunesApplication *app = [AppDelegate iTunesApplicationObject];
    
    if (!app) {
        return nil;
    }
    
    // If under playing state, return current playing information dictionary
    if (app.playerState == iTunesEPlSPlaying) {
        return [AppDelegate songInfoDictionaryWithSongName:app.currentTrack.name
                                                 AlbumName:app.currentTrack.album];
    }
    return nil;
}

+ (NSDictionary *)songInfoDictionaryWithSongName:(NSString *)aSongName
                                       AlbumName:(NSString *)aAlbumName
{
    return @{@"title" : aSongName, @"album" : aAlbumName};
}

- (NSString *)prettySongString
{
    // Initial state
    if (!currentSongInformation) {
        currentSongInformation = [AppDelegate currentSongInfo];
    }
    
    // #currentSongInfo may return nil for no playback
    if (currentSongInformation) {
        return [NSString stringWithFormat:@"Listening : %@ from %@", currentSongInformation[@"title"], currentSongInformation[@"album"]];
    }
    
    return (NSString *)kPlaybackNotFoundString;
}

#pragma mark - Twitter action handler

- (void)twitterAccountListWithCompletion:(void (^)(NSArray *aAccounts))aCompletion
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType  *accountType  = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:nil
                                       completion:^(BOOL granted, NSError *error) {
                                           if (error) {
                                               NSLog(@"%@", error);
                                               return;
                                           }
                                           
                                           NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                                           if (aCompletion) {
                                               aCompletion(accounts);
                                           }
                                       }];
    
}

- (void)postTwitterWithSender:(id)sender
{
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    NSString   *userName = menuItem.title;
    ACAccount  *account  = twitterAccountDictionary[userName];
    
    if (!account) {
        return;
    }
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType  *accountType  = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    void (^twitterRequestGrantCompletion)(BOOL, NSError *) = ^(BOOL granted, NSError *error) {
        if (error) {
            return;
        }
        
        if (granted) {
            NSURL        *url    = [NSURL URLWithString:(NSString *)kTwitterPostURL];
            NSDictionary *params = @{@"status" : [NSString stringWithFormat:@"%@ %@", [self prettySongString], (NSString *)kTwitterHashTag]};
            
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url
                                                       parameters:params];
            
            [request setAccount:account];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (error) {
                    return;
                }
        }];
        }
    };
    
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:nil
                                       completion:twitterRequestGrantCompletion];
}

@end
