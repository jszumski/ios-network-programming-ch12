//
//  GANetworkingManager.m
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import "GANetworkingManager.h"
#import "GAAppDelegate.h"

static GANetworkingManager *_staticInstance;

@interface GANetworkingManager() {
@private
	GKSession *_session;
}

- (void)destroySession;
//- (void)willTerminate:(NSNotification *)notification;
//- (void)willResume:(NSNotification *)notification;

@end


@implementation GANetworkingManager

@synthesize peerList = _peerList;
@synthesize lobbyDelegate;
@synthesize auctionDelegate;


#pragma mark - Static Instance

+ (GANetworkingManager*)sharedManager {
	if (_staticInstance == nil) {
		_staticInstance = [[GANetworkingManager alloc] init];
	}
	
	return _staticInstance;
}

- (id)init {
	self = [super init];
	
	if (self != nil) {
		_peerList = [[NSMutableArray alloc] init];
        
        // listen for app lifecycle events so we can adjust our availability
        /*[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willTerminate:)
													 name:UIApplicationWillTerminateNotification
												   object:nil];
		
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willTerminate:)
													 name:UIApplicationWillResignActiveNotification
												   object:nil];
		
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willResume:)
													 name:UIApplicationDidBecomeActiveNotification
												   object:nil];*/
	}
	
	return self;  
}

- (GAPeer*)devicePeer {
	return [[GAPeer alloc] initWithPeerID:_session.peerID];
}


#pragma mark - GKSession

- (void)setupSession {
	// if we have an existing session, destroy it
	if (_session != nil) {
		[_staticInstance destroySession];
	}
	
	// create a new GameKit session
	_session = [[GKSession alloc] initWithSessionID:kGameKitSessionID displayName:nil sessionMode:GKSessionModePeer];
	
	// tell the session to use this manager as the event and data delegates
	_session.delegate = self;
	[_session setDataReceiveHandler:self withContext:nil];
		
	// update the UI for our new session
    [lobbyDelegate peerListDidChange:self];
}

- (void)stopAcceptingInvitations {
	_session.available = NO;
}

- (void)startAcceptingInvitations {
	_session.available = YES;
}

- (void)connect:(GAPeer*)peer {
	if (peer == nil) {
		return;
	}
	
	// attempt a connection to this peer
	[_session connectToPeer:peer.peerID withTimeout:10.0];
	peer.state = GKPeerStateConnecting;
}

- (void)didAcceptInvitationFromPeer:(GAPeer*)peer {
	if (peer == nil) {
		return;
	}
	
	// accept the connection from this peer
    NSError *error = nil;
    if (![_session acceptConnectionFromPeer:peer.peerID error:&error]) {
        NSLog(@"error in accept = %@",[error localizedDescription]);
    }
}

- (void)didDeclineInvitationFromPeer:(GAPeer*)peer {	
	if (peer == nil) {
		return;
	}
	
	// if this peer isn't already disconnected, close the connection and mark as disconnected
    if (peer.state != GKPeerStateDisconnected) {
        [_session denyConnectionFromPeer:peer.peerID];
        peer.state = GKPeerStateDisconnected;
    }
}

- (NSString*)displayNameForPeer:(GAPeer*)peer {
	return [_session displayNameForPeer:peer.peerID];
}

- (void)sendPacket:(NSData*)data ofType:(GAPacketType)type {
    NSMutableData *newPacket = [NSMutableData dataWithCapacity:([data length]+sizeof(uint32_t))];
	
    // data is prefixed with GAPacketType so the peer knows how to handle it
    uint32_t swappedType = CFSwapInt32HostToBig((uint32_t)type);
    [newPacket appendBytes:&swappedType length:sizeof(uint32_t)];
    [newPacket appendData:data];
	
	// reliably send the packet
    NSError *error;
  	if (![_session sendDataToAllPeers:newPacket withDataMode:GKSendDataReliable error:&error]) {
        NSLog(@"Error sending packet: %@",[error localizedDescription]);
    }
}

- (void)disconnectFromAllPeers {
    [auctionDelegate managerWillDisconnect:self];
	
    for (GAPeer* peer in _peerList) {
		if (peer.state != GKPeerStateDisconnected) {
			
			// stop any pending connections
			if (peer.state == GKPeerStateConnecting) {
				[_session cancelConnectToPeer:peer.peerID];
			}
			
			// mark this peer as disconnected
			peer.state = GKPeerStateDisconnected;
		}
    }
	
	[_session disconnectFromAllPeers];
}

- (void)disconnectFromPeer:(GAPeer*)peer {		
	if (peer == nil) {
		return;
	}
	
	if (peer.state != GKPeerStateDisconnected) {
		// stop any pending connections
		if (peer.state == GKPeerStateConnecting) {
			[_session cancelConnectToPeer:peer.peerID];
		}
		
		// mark this peer as disconnected
		peer.state = GKPeerStateDisconnected;
	}
	
	[_session disconnectPeerFromAllPeers:peer.peerID];
}

- (void)destroySession {
    [self disconnectFromAllPeers];
	
	_session.delegate = nil;
	[_session setDataReceiveHandler:nil withContext:nil];

    [_peerList removeAllObjects];
}


#pragma mark - GKSessionDelegate

- (GAPeer*)peerFromPeerID:(NSString*)peerID {	
	for (GAPeer* p in _peerList) {
		if (p.peerID == peerID) {
			return p;
		}
	}
	
	return nil;
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	GAPeer* peer = [self peerFromPeerID:peerID];
	
	if (peer == nil) {
		return;
	}
	
	// if we're not already conncted to this peer, tell the UI to show an invitation request
	if (peer.state == GKPeerStateDisconnected) {
        peer.state = GKPeerStateConnecting;
		
		[lobbyDelegate didReceiveInvitation:self fromPeer:peer];
		
	// if we are already connected to this peer, don't accept a new connection
    } else {
        [session denyConnectionFromPeer:peerID];
    }
}

- (void)withdrawInvitationToPeer:(GAPeer*)peer {	
	if (peer == nil) {
		return;
	}
	
	// cancel our connection request to this peer
	[_session cancelConnectToPeer:peer.peerID];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    NSLog(@"connectionWithPeerFailed=%@",[error localizedDescription]);
	
	GAPeer* peer = [self peerFromPeerID:peerID];
	if (peer == nil) {
		return;
	}
	
    if (peer.state != GKPeerStateDisconnected) {
		
		// tell the UI that the invitation failed
        [lobbyDelegate invitationDidFail:self fromPeer:peer];
		
		// mark this peer as disconnected
        peer.state = GKPeerStateDisconnected;
    }
}

- (void)session:(GKSession *)session didFailWithError:(NSError*)error {
    NSLog(@"didFailWithError=%@",[error localizedDescription]);
	
	// something is wrong with the session, so disconnect from all peers
    [self disconnectFromAllPeers];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
	GAPeer* peer = [self peerFromPeerID:peerID];
	
	switch (state) { 
		case GKPeerStateAvailable:			
            // this peer became available
			
			//peer.state = GKPeerStateAvailable;
			
			// if this is the first time we've seen this peer, add to our peer list
			if (![_peerList containsObject:peer] || peer == nil) {
				[_peerList addObject:[[GAPeer alloc] initWithPeerID:peerID]];
			}
			
			// tell the UI to update
 			[lobbyDelegate peerListDidChange:self];
			
			break;
			
		case GKPeerStateUnavailable:
            // this peer became unavailable
			
            [_peerList removeObject:peer];
			
			// tell the UI to cancel any pending invitations and update
			[lobbyDelegate cancelInvitationFromPeer:peer];
            [lobbyDelegate peerListDidChange:self];
			
			break;
			
		case GKPeerStateConnected:			
            // this peer accepted our connection
			
            peer.state = GKPeerStateConnected;
			
			// tell the UI we connected
			[lobbyDelegate connectionSuccessful:self withPeer:peer];
			
			break;
			
		case GKPeerStateDisconnected:
			// this peer disconnected from the session
			
			[self disconnectFromPeer:peer];
			[_peerList removeObject:peer];
			
			// tell the UI to update
            [lobbyDelegate peerListDidChange:self];
			
			break;
			
		default:
			break;
	}
}

- (void)receiveData:(NSData*)data fromPeer:(NSString*)peerID inSession:(GKSession*)session context:(void*)context {
	GAPacketType header;
    uint32_t swappedHeader;
	
    if ([data length] >= sizeof(uint32_t)) {    
        [data getBytes:&swappedHeader length:sizeof(uint32_t)];
        header = (GAPacketType)CFSwapInt32BigToHost(swappedHeader);
        NSRange payloadRange = {sizeof(uint32_t), [data length]-sizeof(uint32_t)};
        NSData* payload = [data subdataWithRange:payloadRange];
        
		// tell the auction that we received a packet
		[auctionDelegate manager:self didReceivePacket:payload ofType:header];
    }
}

@end