//
//  GAMasterViewController.m
//  GameKit Auctioneer
//
//  Copyright (c) 2012 John Szumski. All rights reserved.
//

#import "GALobbyViewController.h"
#import "GAAuctionViewController.h"

@interface GALobbyViewController() {
@private
    UIAlertView		*alertView;
	NSMutableArray	*confirmedPeers;
	int				remainingAcks;
	UIBarButtonItem *startButton;
	
	GAPeer			*inviter;
}

- (void)startTapped:(id)sender;
- (void)openAuctionScreenAsParticipant;
- (void)openAuctionScreenAsHostWithItem:(NSString*)itemName;

@end


@implementation GALobbyViewController


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
    if (self) {
		self.title = NSLocalizedString(@"Participants", @"Participants");
		
		startButton = [[UIBarButtonItem alloc] initWithTitle:@"Start" 
													   style:UIBarButtonItemStyleDone
													  target:self 
													  action:@selector(startTapped:)];
		self.navigationItem.rightBarButtonItem = startButton;
    }
	
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// start with the button disabled until we have a confirmed peer
	startButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
	// clear all our state data (in case we came from a finished auction)
	remainingAcks = 0;
	confirmedPeers = [[NSMutableArray alloc] init];
	[[GANetworkingManager sharedManager] setupSession];
	[[GANetworkingManager sharedManager] startAcceptingInvitations];
	startButton.enabled = NO;
		
	// uncheck every cell
	for (NSString *s in [GANetworkingManager sharedManager].peerList) {
		int loc = [[GANetworkingManager sharedManager].peerList indexOfObject:s];
		
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:loc inSection:0]];
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	// update the UI
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[GANetworkingManager sharedManager] stopAcceptingInvitations];
}


#pragma mark - UI response

- (void)startTapped:(id)sender {
	UIAlertView *itemNameAlert = [[UIAlertView alloc] initWithTitle:nil 
															message:@"What item will you be auctioning?" 
														   delegate:self 
												  cancelButtonTitle:nil 
												  otherButtonTitles:@"Start Auction", nil];
	itemNameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	itemNameAlert.tag = 999;
	[itemNameAlert show];
	
	[[GANetworkingManager sharedManager] stopAcceptingInvitations];
}

- (void)openAuctionScreenAsParticipant {
	GAAuctionViewController *auctionVC = [[GAAuctionViewController alloc] init];
	auctionVC.isHost = NO;
	auctionVC.host = inviter;
		
	[GANetworkingManager sharedManager].auctionDelegate = auctionVC;
	
	[self presentModalViewController:[[UINavigationController alloc] initWithRootViewController:auctionVC] animated:YES];
}

- (void)openAuctionScreenAsHostWithItem:(NSString*)itemName {
	/*
	 * create the auction UI
	 */
	GAAuctionViewController *auctionVC = [[GAAuctionViewController alloc] init];
	auctionVC.isHost = YES;	
	auctionVC.host = [[GANetworkingManager sharedManager] devicePeer];
	auctionVC.itemName = itemName;
	auctionVC.peerList = [GANetworkingManager sharedManager].peerList;
	
	// hook it up to the networking manager
	[GANetworkingManager sharedManager].auctionDelegate = auctionVC;
	
	
	/*
	 * tell all participants this auction is starting
	 */
	NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
	GAPeer *devicePeer = [[GANetworkingManager sharedManager] devicePeer];
	
	// auction owner
	[dataDict setObject:devicePeer.peerID forKey:@"ownerPeerID"];
	
	// item name
	[dataDict setObject:itemName forKey:@"itemName"];

	
	// number of participants
	[dataDict setObject:[NSNumber numberWithInt:[confirmedPeers count]] forKey:@"numberOfParticipants"];

		
	// participants
	if ([confirmedPeers count] > 0) {
		GAPeer *peer = [confirmedPeers objectAtIndex:0];
		[dataDict setObject:peer.peerID forKey:@"participant1PeerID"];

	}
	
	if ([confirmedPeers count] > 1) {
		GAPeer *peer = [confirmedPeers objectAtIndex:1];
		[dataDict setObject:peer.peerID forKey:@"participant2PeerID"];
	}
	
	if ([confirmedPeers count] > 2) {
		GAPeer *peer = [confirmedPeers objectAtIndex:2];
		[dataDict setObject:peer.peerID forKey:@"participant3PeerID"];
	}
	
	if ([confirmedPeers count] > 3) {
		GAPeer *peer = [confirmedPeers objectAtIndex:3];
		[dataDict setObject:peer.peerID forKey:@"participant4PeerID"];
	}
	
	if ([confirmedPeers count] > 4) {
		GAPeer *peer = [confirmedPeers objectAtIndex:4];
		[dataDict setObject:peer.peerID forKey:@"participant5PeerID"];
	}
	
	if ([confirmedPeers count] > 5) {
		GAPeer *peer = [confirmedPeers objectAtIndex:5];
		[dataDict setObject:peer.peerID forKey:@"participant6PeerID"];
	}
	

	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:dataDict forKey:@"AuctionStarted"];
	[archiver finishEncoding];
	
		
	// send the message
	[[GANetworkingManager sharedManager] sendPacket:data ofType:GAPacketTypeAuctionStart];
	
	
	/*
	 * display the auction UI
	 */
	[self presentModalViewController:[[UINavigationController alloc] initWithRootViewController:auctionVC] animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[GANetworkingManager sharedManager] peerList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

	GAPeer *peer = [[[GANetworkingManager sharedManager] peerList] objectAtIndex:indexPath.row];
	cell.textLabel.text = [[GANetworkingManager sharedManager] displayNameForPeer:peer];
	
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	GAPeer *peer = [[GANetworkingManager sharedManager].peerList objectAtIndex:[indexPath row]];
	
	// check to make sure we aren't over the max number of participants (taking into account remaining ACKs)
	if ([confirmedPeers count] >= 6) {
		UIAlertView	*msg = [[UIAlertView alloc] 
							initWithTitle:@"Too Many Participants"
							message:@"You can't send any more invitations because you have reached the maximum of 6 participants." 
							delegate:self 
							cancelButtonTitle:@"OK" 
							otherButtonTitles:nil];
		[msg show];
		return;
		
	} else if (([confirmedPeers count] + remainingAcks) >= 6) {
		UIAlertView	*msg = [[UIAlertView alloc] 
							initWithTitle:@"Too Many Invitations"
							message:[NSString stringWithFormat:@"You can't send any more invitations because you have invited the maximum of 6 participants (%i confirmed & %i pending).", [confirmedPeers count], remainingAcks] 
							delegate:self 
							cancelButtonTitle:@"OK" 
							otherButtonTitles:nil];
		[msg show];
		return;
	}
	
	
	if (cell.accessoryView == nil) {
		// start the connection process
		
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[spinner startAnimating];
		
		cell.accessoryView = spinner;
		
		remainingAcks++;
		startButton.enabled = NO;
		
		[[GANetworkingManager sharedManager] connect:peer];
	}
}


#pragma mark - GANetworkingManagerLobbyDelegate

- (void)peerListDidChange:(GANetworkingManager*)manager {
	[self.tableView reloadData];
}

- (void)connectionSuccessful:(GANetworkingManager*)manager withPeer:(GAPeer*)peer {
	if (peer != nil) {
		int loc = [manager.peerList indexOfObject:peer];
				
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:loc inSection:0]];
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		remainingAcks--;
		[confirmedPeers addObject:peer];
		
		if (remainingAcks == 0 && [confirmedPeers count] > 0) {
			startButton.enabled = YES;
		}
	}
}

- (void)didReceiveInvitation:(GANetworkingManager*)manager fromPeer:(GAPeer*)peer {	
	NSString *peerName = [manager displayNameForPeer:peer];
	if (peerName == nil || [peerName length] <= 0) {
		peerName = @"Unknown";
	}
	
	NSString *str = [NSString stringWithFormat:@"Invitation from %@", peerName];
    if (alertView.visible) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
    }
	
	inviter = peer;
	
	alertView = [[UIAlertView alloc] 
				 initWithTitle:str
				 message:[NSString stringWithFormat:@"Do you want to join %@'s auction?", peerName] 
				 delegate:self 
				 cancelButtonTitle:@"Decline" 
				 otherButtonTitles:nil];
	[alertView addButtonWithTitle:@"Join"]; 
	alertView.tag = 200;
	[alertView show];
}

- (void)cancelInvitationFromPeer:(GAPeer*)peer {
	NSString *name = [[GANetworkingManager sharedManager] displayNameForPeer:peer];
	
	if (alertView.title != nil && [alertView.title length] != 0) {
		NSRange notFound = [alertView.title rangeOfString:name];
		
		if (alertView != nil && alertView.visible && notFound.location != NSNotFound) {
			[alertView dismissWithClickedButtonIndex:0 animated:NO];
			
			alertView = [[UIAlertView alloc] 
						 initWithTitle:[NSString stringWithFormat:@"%@ Has Disappeared",name]
						 message:[NSString stringWithFormat:@"The invitation from %@ was automatically canceled because the device can no longer be found.", name] 
						 delegate:self 
						 cancelButtonTitle:@"OK" 
						 otherButtonTitles:nil];
			[alertView show];
		}
	}
}

- (void)invitationDidFail:(GANetworkingManager*)manager fromPeer:(GAPeer*)peer {	
	NSString *peerName = [manager displayNameForPeer:peer];
	if (peerName == nil || [peerName length] <= 0) {
		peerName = @"Unknown";
	}
	
    NSString *str;
    if (alertView.visible) {
        // Peer cancelled invitation before it could be accepted/rejected
        // Close the invitation dialog before opening an error dialog
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        str = [NSString stringWithFormat:@"%@ cancelled your invitation.", peerName]; 
    } else {
        // Peer rejected invitation or exited app.
        str = [NSString stringWithFormat:@"%@ declined your invitation.", peerName]; 
    }
    
    alertView = [[UIAlertView alloc] initWithTitle:str message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
	
	int loc = -1;
	
	// find the correct location in our list
	for (GAPeer *p in manager.peerList) {
		if ([[manager displayNameForPeer:p] isEqualToString:[manager displayNameForPeer:peer]]) {
			loc = [manager.peerList indexOfObject:p];
			break;
		}
	}
	
	if (loc >= 0) {
		// turn off spinner and adjust our data model accordingly
		
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:loc inSection:0]];
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		remainingAcks--;
		//numPlayersLabel.text = [NSString stringWithFormat:@"%i/4 players",remainingAcks+[confirmedPeers count]];
		
		if (remainingAcks == 0 && [confirmedPeers count] > 0) {
			startButton.enabled = YES;
		}
	}
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)theView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (theView.tag == 200) {
		if (buttonIndex == 1) {
			// this is a "do you want to join" alert
			
			startButton.enabled = NO;
			
			[[GANetworkingManager sharedManager] didAcceptInvitationFromPeer:inviter];
			[self openAuctionScreenAsParticipant];
		} else {
			[[GANetworkingManager sharedManager] didDeclineInvitationFromPeer:inviter];
		}
	
	} else if (theView.tag == 999) {
		// this is a "what is your item?" alert
		
		// show the auction detail view
		[self openAuctionScreenAsHostWithItem:[theView textFieldAtIndex:0].text];
	}
}

@end