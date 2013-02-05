//
//  GAAppDelegate.h
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GANetworkingManager.h"

#define kGameKitSessionID @"auctioneer1.0"

@interface GAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow					*window;
@property (strong, nonatomic) UINavigationController	*navigationController;

@end