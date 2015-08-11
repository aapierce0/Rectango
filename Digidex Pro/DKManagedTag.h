//
//  DKManagedTag.h
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DKManagedCard;

@interface DKManagedTag : NSManagedObject

@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *cards;

- (instancetype)initWithName:(NSString*)name color:(id)color insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;

@end

@interface DKManagedTag (CoreDataGeneratedAccessors)

- (void)addCardsObject:(DKManagedCard *)value;
- (void)removeCardsObject:(DKManagedCard *)value;
- (void)addCards:(NSSet *)values;
- (void)removeCards:(NSSet *)values;

@end
