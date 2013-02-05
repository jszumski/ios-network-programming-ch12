//
//  GAAuctionViewController.h
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GANetworkingManager.h"

@interface GAAuctionViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, GANetworkingManagerAuctionDelegate, UIAlertViewDelegate>

@property(nonatomic, strong) NSMutableArray	*peerList;
@property(nonatomic, strong) NSString		*itemName;
@property(nonatomic, strong) GAPeer			*host;
@property(nonatomic, assign) BOOL			isHost;

@end