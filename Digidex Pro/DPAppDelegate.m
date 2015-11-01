//
//  DPAppDelegate.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPAppDelegate.h"

#import "DPDetailTableViewController.h"
#import "DKManagedCard.h"
#import "DKDataStore.h"

@implementation DPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window setTintColor:[UIColor colorWithHue:0.411 saturation:0.9 brightness:0.7 alpha:1.0]];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



- (BOOL)application:(UIApplication*)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	NSLog(@"Opening URL: %@", url);
	
	BOOL success = YES;
	
	// Check to make sure this URL is valid.
	UIViewController *newViewController;
	if (![DKManagedCard digidexURLIsValid:url]) {
		
		NSString *message = [NSString stringWithFormat:@"The URL could not be processed by Rectango.\n\n%@", url];
		UIAlertController *noticeController = [UIAlertController alertControllerWithTitle:@"Malformed URL" message:message preferredStyle:UIAlertControllerStyleAlert];
		[noticeController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
		
		newViewController = noticeController;
		
		success = NO;
	} else {
		
		DKManagedCard *card = [[DKDataStore sharedDataStore] makeTransientContactWithURL:url];
		
		DPDetailTableViewController *detailViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"DetailViewController"];
		detailViewController.selectedCard = card;
		detailViewController.title = @"New Card";
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
		newViewController = navigationController;
	}
	
	
	
	
	// Display this addition view controller on whatever the top most view controller is.
	UIViewController *topViewController = [self topMostController];
	if ([topViewController isKindOfClass:[UIAlertController class]]) {
		
		UIViewController *alertViewController = topViewController;
		topViewController = topViewController.presentingViewController;
		
		// Dismiss the alert controller
		[alertViewController dismissViewControllerAnimated:YES completion:^{
			[topViewController presentViewController:newViewController animated:YES completion:^{}];
		}];
	} else {
		[topViewController presentViewController:newViewController animated:YES completion:^{}];
	}
	
	return YES;
}


- (UIViewController*) topMostController
{
	UIViewController *topController = self.window.rootViewController;
	
	while (topController.presentedViewController) {
		topController = topController.presentedViewController;
	}
	
	return topController;
}

@end
