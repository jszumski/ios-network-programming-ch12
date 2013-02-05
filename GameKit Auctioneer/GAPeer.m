//
//  GAPeer.m
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import "GAPeer.h"

@implementation GAPeer

@synthesize peerID, state, tag;

- (id) initWithPeerID:(NSString *)pID {
	self = [super init];
	
	if (self != nil) {
		self.peerID = pID;
		self.state = GKPeerStateDisconnected;
		self.tag = -1;
	}
	
	return self;
}

@end