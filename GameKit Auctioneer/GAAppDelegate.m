//
//  GAAppDelegate.m
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import "GAAppDelegate.h"
#import "GALobbyViewController.h"
#import "GANetworkingManager.h"

@implementation GAAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// create the lobby
	GALobbyViewController *lobbyVC = [[GALobbyViewController alloc] initWithNibName:@"GALobbyViewController" bundle:nil];
	
	// start the networking manager
    [GANetworkingManager sharedManager].lobbyDelegate = lobbyVC;
    [[GANetworkingManager sharedManager] setupSession];
	
	// create the lobby inside a navigation conroller then display it
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:lobbyVC];
	self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

@end