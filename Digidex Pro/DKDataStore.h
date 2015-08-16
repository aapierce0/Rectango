//
//  DKDataStore.h
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DKManagedCard;
@class DKManagedTag;

@interface DKDataStore : NSObject {
	NSManagedObjectModel *_mom;
	NSPersistentStoreCoordinator *_psc;
	NSManagedObjectContext *_moc;
}

+ (instancetype)sharedDataStore;

- (NSArray *)allContacts;
- (NSArray*)allTags;

- (DKManagedCard*)addContactWithURL:(NSURL*)contactURL;
- (DKManagedCard*)makeTransientContactWithURL:(NSURL*)contactURL;

- (void)insertCard:(DKManagedCard*)card;
- (void)deleteCard:(DKManagedCard*)card;

- (DKManagedTag*)addTagNamed:(NSString*)tagName;

@end
