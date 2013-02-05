//
//  GAPeer.h
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface GAPeer : NSObject {
	NSString				*peerID;
	GKPeerConnectionState	state;
	NSInteger				tag;
}

@property (nonatomic, strong)	NSString				*peerID;
@property (nonatomic, assign)	GKPeerConnectionState	state;
@property (nonatomic, assign)	NSInteger				tag;

- (id)initWithPeerID:(NSString *)peerID;

@end