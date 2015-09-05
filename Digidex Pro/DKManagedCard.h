//
//  DKManagedCard.h
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class DKManagedTag;

@interface DKManagedCard : NSManagedObject {
	NSDictionary *_cardDictionary;
	
	UIImage *_cardImage;
	UIImage *_cachedCardImage;
	
	CGSize _cardImageSize;
	CGSize _cachedCardImageSize;
	
	NSArray *_filteredKeys;
}

@property (nonatomic, retain) NSString * localFilename;
@property (readonly) NSString *localPath;
@property (nonatomic, retain) id originalURL;
@property (readonly) NSURL *digidexURL; // This is a URL with the digidex:// scheme.
@property (nonatomic, retain) NSSet *tags;

@property (readonly) NSDictionary *cardDictionary;
@property (readonly) NSArray *filteredKeys;

@property (readonly) NSURL *cardImageURL;
@property (readonly) UIImage *cardImage;
@property (readonly) CGSize cardImageSize;

- (instancetype)initWithContactURL:(NSURL *)URL managedObjectContext:(NSManagedObjectContext *)moc insert:(BOOL)shouldInsertAutomatically;
- (instancetype)initWithContactURL:(NSURL *)URL insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;

- (NSString*)guessedName;
- (NSString*)guessedOrganization;
- (NSString*)guessedOccupation;

- (void)setCachedCardImage:(UIImage *)image;

+ (void)determineDigidexURLFromProvidedURL:(NSURL*)providedURL completion:(void (^)(NSURL *determinedURL))completion;

@end

@interface DKManagedCard (CoreDataGeneratedAccessors)

- (void)addTagsObject:(DKManagedTag *)value;
- (void)removeTagsObject:(DKManagedTag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
