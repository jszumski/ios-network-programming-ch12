//
//  GAAuctionViewController.m
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import "GAAuctionViewController.h"

@interface GAAuctionViewController() {
@private
	BOOL		biddingHasStarted;

    NSInteger	highestBid;
	NSString	*highestBidOwner;
}

- (void)leaveAuction:(id)sender;

@end

@implementation GAAuctionViewController

@synthesize peerList, isHost, itemName, host;


#pragma mark - View lifecycle

- (id)init {
	self = [super initWithStyle:UITableViewStyleGrouped];
	
	if (self != nil) {
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		
		biddingHasStarted = NO;
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// add a cancel button that returns to the lobby
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																				  target:self 
																				  action:@selector(leaveAuction:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)setHost:(GAPeer *)newHost {
	host = newHost;
	
	NSString *hostName = [[GANetworkingManager sharedManager] displayNameForPeer:host];
	self.title = [NSString stringWithFormat:@"%@'s Auction", hostName];
}

- (void)setIsHost:(BOOL)newIsHost {
	isHost = newIsHost;
	
	if (newIsHost) {
		// since the host is the one who starts the bidding, if we've gotten here the auction is always ready
		biddingHasStarted = YES;
	}
}

#pragma mark - UI Response

- (void)leaveAuction:(id)sender {
	[[GANetworkingManager sharedManager] disconnectFromAllPeers];
	
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - GANetworkingManagerAuctionDelegate

- (void)managerWillDisconnect:(GANetworkingManager*)manager {	
	[self dismissModalViewControllerAnimated:YES];
}

- (void)manager:(GANetworkingManager*)manager didReceivePacket:(NSData*)data ofType:(GAPacketType)packetType {
	
	switch (packetType) {
		case GAPacketTypeAuctionStart: {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			NSDictionary *dataDict = [unarchiver decodeObjectForKey:@"AuctionStarted"];
			[unarchiver finishDecoding];
						
			// item name
			self.itemName = [dataDict objectForKey:@"itemName"];

			// participants
			self.peerList = [[NSMutableArray alloc] init];
			
			int numberOfParticipants = [[dataDict objectForKey:@"numberOfParticipants"] intValue];
			
			//NSString *ownerPeerID = [dataDict objectForKey:@"ownerPeerID"];
			
			NSString *p1PeerID = [dataDict objectForKey:@"participant1PeerID"];
			if (numberOfParticipants > 0) {
				[self.peerList addObject:[[GAPeer alloc] initWithPeerID:p1PeerID]];
			}
			
			NSString *p2PeerID = [dataDict objectForKey:@"participant2PeerID"];
			if (numberOfParticipants > 1) {
				[self.peerList addObject:[[GAPeer alloc] initWithPeerID:p2PeerID]];
			}
			
			NSString *p3PeerID = [dataDict objectForKey:@"participant3PeerID"];
			if (numberOfParticipants > 2) {
				[self.peerList addObject:[[GAPeer alloc] initWithPeerID:p3PeerID]];
			}
			
			NSString *p4PeerID = [dataDict objectForKey:@"participant4PeerID"];
			if (numberOfParticipants > 3) {
				[self.peerList addObject:[[GAPeer alloc] initWithPeerID:p4PeerID]];
			}
			
			NSString *p5PeerID = [dataDict objectForKey:@"participant5PeerID"];
			if (numberOfParticipants > 4) {
				[self.peerList addObject:[[GAPeer alloc] initWithPeerID:p5PeerID]];
			}
			
			NSString *p6PeerID = [dataDict objectForKey:@"participant6PeerID"];
			if (numberOfParticipants > 5) {
				[self.peerList addObject:[[GAPeer alloc] initWithPeerID:p6PeerID]];
			}
						
			// update UI with the info from this packet
			[self.tableView reloadData];
			
			// allow participants to make bids
			biddingHasStarted = YES;
			
			break;
		}
			
		case GAPacketTypeBid: {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			NSDictionary *dataDict = [unarchiver decodeObjectForKey:@"Bid"];
			[unarchiver finishDecoding];
			
			NSInteger bid = [[dataDict objectForKey:@"bidAmount"] intValue];
			
			if (bid > highestBid) {
				highestBid = bid;
				highestBidOwner = [dataDict objectForKey:@"bidderPeerID"];
				
				// update the UI
				[self.tableView reloadData];
				
				
				// let all participants know the new highest bid
				NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
				
				// highest bid
				[dataDict setObject:[NSNumber numberWithInt:highestBid] forKey:@"winningBid"];
				
				// winner peer ID
				[dataDict setObject:highestBidOwner forKey:@"winnerPeerID"];
				
				NSMutableData *data = [[NSMutableData alloc] init];
				NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
				[archiver encodeObject:dataDict forKey:@"Status"];
				[archiver finishEncoding];
				
				// send the message
				[[GANetworkingManager sharedManager] sendPacket:data ofType:GAPacketTypeAuctionStatus];
			}
			
			break;
		}
			
		case GAPacketTypeAuctionStatus: {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			NSDictionary *dataDict = [unarchiver decodeObjectForKey:@"Status"];
			[unarchiver finishDecoding];
			
			// update data model
			highestBid = [[dataDict objectForKey:@"winningBid"] intValue];
			highestBidOwner = [dataDict objectForKey:@"winnerPeerID"];
			
			// update the UI
			[self.tableView reloadData];
			
			break;
		}
			
		case GAPacketTypeAuctionEnd: {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			NSDictionary *dataDict = [unarchiver decodeObjectForKey:@"AuctionFinish"];
			[unarchiver finishDecoding];
			
			// update data model
			NSInteger winningBid = [[dataDict objectForKey:@"winningBid"] intValue];
			NSString *winnerPeerID = [dataDict objectForKey:@"winnerPeerID"];
			
			// tell the user who won
			NSString *message;
			
			if ([winnerPeerID isEqualToString:[GANetworkingManager sharedManager].devicePeer.peerID]) {
				message = [NSString stringWithFormat:@"You won the auction with a bid of $%i!", winningBid];
			} else {
				message = [NSString stringWithFormat:@"%@ won the auction with a bid of $%i!", [[GANetworkingManager sharedManager] displayNameForPeer:[[GAPeer alloc] initWithPeerID:winnerPeerID]], winningBid];
			}
			
			UIAlertView *finishedAlert = [[UIAlertView alloc] initWithTitle:@"Auction Finished"
																	message:message 
																   delegate:self 
														  cancelButtonTitle:nil 
														  otherButtonTitles:@"OK", nil];
			finishedAlert.tag = 700;
			[finishedAlert show];
		}
	}
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return 3;
		
	} else if (section == 1) {
		return [self.peerList count];
	}
	
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 1) {
		return @"Participants";
	}
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSInteger rowCount = [self tableView:tableView numberOfRowsInSection:section];
	
	if (rowCount == 0) {
		return @"Waiting for the auction to start...";
	}
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	// item info section
	if (indexPath.section == 0) {
		
		// handle the info cells
		if (indexPath.row != 2) {
			static NSString *detailCellID = @"detailCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:detailCellID];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:detailCellID];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			
			// item
			if (indexPath.row == 0) {
				cell.textLabel.text = @"Item";
				
				if (self.itemName == nil || [self.itemName isEqualToString:@""]) {
					cell.detailTextLabel.text = @"Waiting for host...";
				} else {
					cell.detailTextLabel.text = self.itemName;
				}
				
			// highest bid
			} else if (indexPath.row == 1) {
				cell.textLabel.text = @"Highest Bid";
				cell.detailTextLabel.text = [NSString stringWithFormat:@"$%i", highestBid];
			}
			
		// make bid
		} else {
			static NSString *buttonCell = @"buttonCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:buttonCell];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonCell];
			}
			
			// different messaging for host vs. others
			if (self.isHost) {
				cell.textLabel.text = @"Accept Bid and End Auction";
			} else {
				cell.textLabel.text = @"Make Bid";
			}
			
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.textLabel.textColor = [UIColor blueColor];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
	
	// peer list section
	} else if (indexPath.section == 1) {
		static NSString *peerCellID = @"peerCell";
		
		cell = [tableView dequeueReusableCellWithIdentifier:peerCellID];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:peerCellID];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		GAPeer *peer = [peerList objectAtIndex:indexPath.row];
		cell.textLabel.text = [[GANetworkingManager sharedManager] displayNameForPeer:peer];
	}
	
	return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (biddingHasStarted == NO) {
		[[[UIAlertView alloc] initWithTitle:@"Bid Error" 
								   message:@"You can't make a bid because the auction has not started yet." 
								  delegate:nil 
						 cancelButtonTitle:@"OK" 
						 otherButtonTitles:nil] show];
		return;
	}
	
	// only one row is selectable
	if (indexPath.section == 0 && indexPath.row == 2) {
		
		if (self.isHost) {
			// end the auction
			
			NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
			
			// winning amount
			[dataDict setObject:[NSNumber numberWithInt:highestBid] forKey:@"winningBid"];
			
			// winner peer ID
			[dataDict setObject:highestBidOwner forKey:@"winnerPeerID"];
			
			NSMutableData *data = [[NSMutableData alloc] init];
			NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[archiver encodeObject:dataDict forKey:@"AuctionFinish"];
			[archiver finishEncoding];
			
			// send the message
			[[GANetworkingManager sharedManager] sendPacket:data ofType:GAPacketTypeAuctionEnd];
			
			// inform the host who won
			NSString *message = [NSString stringWithFormat:@"%@ won the auction with a bid of $%i!", [[GANetworkingManager sharedManager] displayNameForPeer:[[GAPeer alloc] initWithPeerID:highestBidOwner]], highestBid];
			
			UIAlertView *finishedAlert = [[UIAlertView alloc] initWithTitle:@"Auction Finished"
																	message:message 
																   delegate:self 
														  cancelButtonTitle:nil 
														  otherButtonTitles:@"OK", nil];
			finishedAlert.tag = 700;
			[finishedAlert show];
		
		} else {
			// make a bid
			
			UIAlertView *bidAlert = [[UIAlertView alloc] initWithTitle:nil
															   message:@"How much do you want to bid?"
															  delegate:self
													 cancelButtonTitle:nil 
													 otherButtonTitles:@"Bid", nil];
			bidAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
			bidAlert.tag = 600;
			
			UITextField *bidField = [bidAlert textFieldAtIndex:0];
			bidField.keyboardType = UIKeyboardTypeNumberPad;
			
			[bidAlert show];
		}
	}
}


#pragma mark - UITableViewDelegate

- (void)alertView:(UIAlertView *)theView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	// bid alert
	if (theView.tag == 600) {
		UITextField *field = [theView textFieldAtIndex:0];
		NSNumber *bidAmount = [NSNumber numberWithInt:[field.text intValue]];
		
		NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
		
		// bid amount
		[dataDict setObject:bidAmount forKey:@"bidAmount"];
		
		// bidder peer ID
		[dataDict setObject:[[GANetworkingManager sharedManager] devicePeer].peerID forKey:@"bidderPeerID"];

		NSMutableData *data = [[NSMutableData alloc] init];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver encodeObject:dataDict forKey:@"Bid"];
		[archiver finishEncoding];
		
		// send the message
		[[GANetworkingManager sharedManager] sendPacket:data ofType:GAPacketTypeBid];

	// auction over alert
	} else if (theView.tag == 700) {
		[self dismissModalViewControllerAnimated:YES];
	}
}

@end