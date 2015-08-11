//
//  DKDataStore.m
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DKDataStore.h"

#import "DKManagedCard.h"
#import "DKManagedTag.h"

@implementation DKDataStore

- (instancetype)init
{
    self = [super init];
    if (self) {
		
		NSURL *managedObjectModelURL = [[NSBundle mainBundle] URLForResource:@"CardDataModel" withExtension:@"momd"];
		_mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:managedObjectModelURL];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *applicationSupportDirectory = [paths firstObject];
		NSURL *storeURL = [[NSURL fileURLWithPath:applicationSupportDirectory]
						   URLByAppendingPathComponent:@"CardDataModel.sqlite"];
		
//		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		
		NSLog(@"Store URL: %@", storeURL);
		
		NSError *error = nil;
		_psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_mom];
		if (![_psc addPersistentStoreWithType:NSSQLiteStoreType
								configuration:nil
										  URL:storeURL
									  options:@{NSMigratePersistentStoresAutomaticallyOption:@(YES),
												NSInferMappingModelAutomaticallyOption:@(YES)}
										error:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			 
			 Typical reasons for an error here include:
			 * The persistent store is not accessible;
			 * The schema for the persistent store is incompatible with current managed object model.
			 Check the error message to determine what the actual problem was.
			 
			 
			 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
			 
			 If you encounter schema incompatibility errors during development, you can reduce their frequency by:
			 * Simply deleting the existing store:
			 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
			 
			 * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
			 @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
			 
			 Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
			 
			 */
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
		
		_moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[_moc setPersistentStoreCoordinator:_psc];
    }
    return self;
}

+ (instancetype)sharedDataStore;
{
	static DKDataStore *sharedDataStore = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDataStore = [[self alloc] init];
	});
	return sharedDataStore;
}




#pragma mark - Cards

- (NSArray *)allContacts;
{
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Card"];
	request.predicate = [NSPredicate predicateWithValue:YES];
	
	NSError *error;
	NSArray *array;
	@synchronized(_moc) {
		array = [_moc executeFetchRequest:request error:&error];
	}
	
	NSLog(@"All objects: %@", array);
	for (DKManagedCard *card in array) {
		NSLog(@"  originalURL: %@", card.originalURL);
		NSLog(@"  localPath:   %@", card.localPath);
	}
	
	return array;
}

- (DKManagedCard *)addContactWithURL:(NSURL *)contactURL;
{
	DKManagedCard *card;
	@synchronized(_moc) {
		NSError *saveError;
		card = [[DKManagedCard alloc] initWithContactURL:contactURL insertIntoManagedObjectContext:_moc];
		BOOL savedOK = [_moc save:&saveError];
		if (!savedOK) {
			NSLog(@"Error saving context %@", saveError);
		}
	}
	
	return card;
}








#pragma mark - Tags

- (NSArray*)allTags;
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
	request.predicate = [NSPredicate predicateWithValue:YES];
	
	NSError *error;
	NSArray *array;
	@synchronized(_moc) {
		array = [_moc executeFetchRequest:request error:&error];
	}
	
	NSLog(@"All objects: %@", array);
	
	return array;
}

- (DKManagedTag*)addTagNamed:(NSString*)tagName;
{
	DKManagedTag *tag;
	@synchronized(_moc) {
		NSError *saveError;
		UIColor *tagColor = [UIColor redColor];
		tag = [[DKManagedTag alloc] initWithName:tagName color:tagColor insertIntoManagedObjectContext:_moc];
		BOOL savedOK = [_moc save:&saveError];
		if (!savedOK) {
			NSLog(@"Error saving context %@", saveError);
		}
	}
	
	return tag;
}


@end
