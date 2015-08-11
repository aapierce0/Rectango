//
//  DKManagedTag.m
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DKManagedTag.h"
#import "DKManagedCard.h"


@implementation DKManagedTag

@dynamic color;
@dynamic name;
@dynamic cards;

- (instancetype)initWithName:(NSString*)name color:(id)color insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:moc];
	self = [self initWithEntity:entity insertIntoManagedObjectContext:moc];
	
    if (self) {
		
		self.name = name;
		self.color = color;
		
    }
    return self;
}

@end
