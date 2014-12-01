//
//  BehaviourBridgeReceptor.m
//
//  Created by Felix Schwarz on 04.06.06.
//  Copyright 2006 IOSPIRIT GmbH. All rights reserved.
//

/*
	LICENSE

	Copyright (c) 2006, IOSPIRIT GmbH ( info@iospirit.com, http://www.iospirit.com/ )
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, 
	are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of 
	  conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice, this list
	  of conditions and the following disclaimer in the documentation and/or other materials 
	  provided with the distribution.
	
	* Neither the name of the IOSPIRIT GmbH nor the names of its contributors may be used
	  to endorse or promote products derived from this software without specific prior written
	  permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
	THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
	TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BehaviourBridgeConstants.h"
#import "BehaviourBridgeReceptor.h"
#import "ButtonCodes.h"

@implementation BehaviourBridgeReceptor

#pragma mark -- Initialization and clean up --
- (id)init
{
	[self release];
	return (nil);
}

- (id)initWithDelegate:(id)aDelegate
{
	NSString *bundleIdentifier = nil;
	NSObject<BehaviourBridgeReceptorDelegate> *theDelegate = aDelegate;

	if (!theDelegate)
	{
		[self release];
		return (nil);
	}

	self = [super init];
	
	// Set the delegate for this object
	[self setDelegate:theDelegate];
	
	// Cache the default NSDistributedNotificationCenter
	notificationCenter = [[NSDistributedNotificationCenter defaultCenter] retain];
	
	// Get the bundle identifier
	if ([theDelegate respondsToSelector:@selector(bundleIdentifier)])
	{
		bundleIdentifier = [theDelegate bundleIdentifier];
	}
	else
	{
		bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	}

	// Set up the name to observe
	observeName = [[NSString stringWithFormat:@"RemoteBuddy.Bridge.%@", bundleIdentifier] retain];

	// Add the observer
	if (observeName)
	{
		[notificationCenter addObserver:self
				       selector:@selector(handleIncomingNotifications:)
					   name:observeName
					 object:nil
			     suspensionBehavior:NSNotificationSuspensionBehaviorHold];
		
		[notificationCenter setSuspended:NO];
	}
	
	return (self);
}

- (void)dealloc
{
	// Remove the observer
	if (observeName)
	{
		[notificationCenter removeObserver:self
					      name:observeName
					    object:nil];
	}

	// Release the cached default NSDistributedNotificationCenter
	[notificationCenter release];
	notificationCenter = nil;

	[observeName release];
	observeName = nil;

	[super dealloc];
}

#pragma mark -- Accessors --
- (id)delegate
{
	return (delegate);
}

- (void)setDelegate:(id)newDelegate
{
	[newDelegate retain];
	[delegate release];
	delegate = newDelegate;
}

#pragma mark -- Handle incoming notifications --
- (void)handleIncomingNotifications:(NSNotification *)notification
{
	NSDictionary *contents;
	
	if ((contents = [notification userInfo]))
	{
		NSObject<BehaviourBridgeReceptorDelegate> *theDelegate = [self delegate];
	
		if ([[contents objectForKey:kBehaviourBridgeNotificationContentsKey] isEqualToString:kBehaviourBridgeNotificationContentsPerformValue])
		{
			// Perform
			if ([theDelegate respondsToSelector:@selector(performForButtonCode:actionCode:isAutoRepeat:moreInfo:)])
			{
				[theDelegate performForButtonCode:(RemoteButtonCode)[[contents objectForKey:kBehaviourBridgePerformButtonCodeKey] intValue]
						       actionCode:(RemoteActionCode)[[contents objectForKey:kBehaviourBridgePerformActionCodeKey] intValue]
						     isAutoRepeat:[[contents objectForKey:kBehaviourBridgePerformIsAutoRepeatKey] boolValue]			// TRUE if the action is generated by a auto repeat function
							 moreInfo:[contents objectForKey:kBehaviourBridgePerformMoreInfoKey]];
			}
		}

		if ([[contents objectForKey:kBehaviourBridgeNotificationContentsKey] isEqualToString:kBehaviourBridgeNotificationContentsEventValue])
		{
			// Events
			if ([theDelegate respondsToSelector:@selector(eventNotification:)])
			{
				[theDelegate eventNotification:(RemoteEventCode)[[contents objectForKey:kBehaviourBridgeEventEventCodeKey] intValue]];
			}
		}
	}
}

@end
