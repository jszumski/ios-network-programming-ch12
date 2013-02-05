//
//  GANetworkingPackets.h
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

typedef enum {
	GAPacketTypeAuctionStart = 0,
	GAPacketTypeAuctionEnd,
	GAPacketTypeAuctionStatus,
	GAPacketTypeBid
} GAPacketType;