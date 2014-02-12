//
//  main.m
//  ShipIt Watcher
//
//  Created by Keith Duncan on 15/01/2014.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "SQRLDirectoryManager.h"
#import "SQRLShipItRequest.h"
#import "SQRLTerminationListener.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		if (argc < 2) {
			NSLog(@"Missing ShipIt request path");
			return EXIT_FAILURE;
		}
		NSString *requestPath = @(argv[1]);

		if (argc < 3) {
			NSLog(@"Missing ShipIt watcher output path");
			return EXIT_FAILURE;
		}
		NSString *responsePath = @(argv[2]);

		[[[[SQRLShipItRequest
			readFromURL:[NSURL fileURLWithPath:requestPath]]
			flattenMap:^(SQRLShipItRequest *request) {
				if (request.bundleIdentifier == nil) return [RACSignal empty];

				SQRLTerminationListener *listener = [[SQRLTerminationListener alloc] initWithURL:request.targetBundleURL bundleIdentifier:request.bundleIdentifier];
				return [listener waitForTermination];
			}]
			concat:[RACSignal defer:^{
				NSError *error;
				BOOL write = [[NSData data] writeToFile:responsePath options:0 error:&error];
				if (!write) return [RACSignal error:error];

				return [RACSignal empty];
			}]]
			subscribeError:^(NSError *error) {
				NSLog(@"Error waiting for termination: %@", error);
				exit(EXIT_FAILURE);
			} completed:^{
				NSLog(@"Application terminated");
				exit(EXIT_SUCCESS);
			}];

		 dispatch_main();
	}

    return EXIT_SUCCESS;
}