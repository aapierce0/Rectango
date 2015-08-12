//
//  DKManagedCard.m
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DKManagedCard.h"
#import "DKManagedTag.h"


@implementation DKManagedCard

@dynamic localPath;
@dynamic originalURL;
@dynamic tags;

@synthesize cardDictionary = _cardDictionary;

- (instancetype)initWithContactURL:(NSURL *)URL insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Card" inManagedObjectContext:moc];
	self = [self initWithEntity:entity insertIntoManagedObjectContext:moc];
	
    if (self) {
		
		self.originalURL = URL;
		[self reloadCard];
		
    }
    return self;
}

- (void)awakeFromFetch;
{
	[super awakeFromFetch];
	
	// Load this card's contents from either the the local cache if we know what is is, otherwise go over the network.
	[self loadCardFromCachedData];
	
	[self loadImageCompletion:^(NSError *error) {
		if (error) {
			NSLog(@"Error loading contact image: %@", error);
			return;
		}
	}];
	
}

- (NSURL *)cardImageURL;
{
	return [NSURL URLWithString:_cardDictionary[@"cardURL"]];
}


- (NSString *)guessedName;
{
	
	// If the name is explicitly defined, use it.
	if (_cardDictionary[@"name"]) {
		return _cardDictionary[@"name"];
	}
	
	
	
	// Here are some possible alternatives I came up with.
	if (_cardDictionary[@"fullName"]) {
		return _cardDictionary[@"fullName"];
	}
	
	if (_cardDictionary[@"firstName"] && _cardDictionary[@"lastName"]) {
		return [NSString stringWithFormat:@"%@ %@", _cardDictionary[@"firstName"], _cardDictionary[@"lastName"]];
	}
	
	if (_cardDictionary[@"firstName"]) {
		return _cardDictionary[@"firstName"];
	}
	
	if (_cardDictionary[@"lastName"]) {
		return _cardDictionary[@"lastName"];
	}
	
	
	// If we didn't find anything at all, return nil.
	return nil;
}

- (NSString *)guessedOrganization;
{
	if (_cardDictionary[@"organization"]) {
		return _cardDictionary[@"organization"];
	}
	
	if (_cardDictionary[@"company"]) {
		return _cardDictionary[@"company"];
	}
	
	return nil;
}

- (NSString *)guessedOccupation;
{
	if (_cardDictionary[@"occupation"]) {
		return _cardDictionary[@"occupation"];
	}
	
	if (_cardDictionary[@"job"]) {
		return _cardDictionary[@"job"];
	}
	
	return nil;
}



- (UIImage *)cardImage;
{
	if (_cardImage) {
		return _cardImage;
	} else {
		return [UIImage imageNamed:@"placeholderCard.jpg"];
	}
}





- (void)loadCardFromCachedData;
{
	if (self.localPath) {
		
		// Load the JSON document from the local disk, and read it.
		NSData *cardData = [[NSFileManager defaultManager] contentsAtPath:self.localPath];
		
		if (cardData) {
			NSError *jsonError;
			id jsonObject = [NSJSONSerialization JSONObjectWithData:cardData options:kNilOptions error:&jsonError];
			
			// Double check that the result file is a dictionary.
			if ([jsonObject isKindOfClass:[NSDictionary class]]) {
				_cardDictionary = jsonObject;
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ContactLoaded" object:self];
				
			} else if (jsonError) {
				
				// If there was an error parsing the json, say so.
				NSLog(@"Error loading JSON data: %@", jsonError);
				
			}
			
		} else {
			
			// If the result was valid JSON, but NOT a dictionary, this is an error.
			NSError *error = [NSError errorWithDomain:@"JSON"
												 code:100
											 userInfo:@{NSLocalizedDescriptionKey:@"The returned JSON object is not in the proper digidex format"}];
			
			NSLog(@"Error loading JSON data: %@", error);
		}
	}
}




- (void)reloadCard;
{
	// Immediately begin loading the contact data
	[self loadContactDataCompletion:^(NSError *error) {
		
		if (error) {
			NSLog(@"Error loading contact: %@", error);
			return;
		}
		
		[self loadImageCompletion:^(NSError *error) {
			if (error) {
				NSLog(@"Error loading contact image: %@", error);
				return;
			}
		}];
	}];
}




- (void)loadContactDataCompletion:(void (^)(NSError *error))completionHandler;
{
	
	// If completion handler is nil, give it a sensible default value
	if (!completionHandler) {
		completionHandler = ^(NSError* error) {
			// Do nothing...
		};
	}
	
	
	// Make sure that we actually have a card URL here
	if (!self.originalURL) {
		NSError *error = [NSError errorWithDomain:@"URL"
											 code:100
										 userInfo:@{NSLocalizedDescriptionKey:@"cardImageURL is missing."}];
		completionHandler(error);
		return;
	}
	
	
	// We have to download this data now.
	NSURLRequest *jsonRequest = [NSURLRequest requestWithURL:self.originalURL];
	
	// Perform the JSON request
	[NSURLConnection sendAsynchronousRequest:jsonRequest
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
							   
							   
							   if (data) {
								   NSError *jsonError;
								   id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
								   
								   // Double check that the result file is a dictionary.
								   if ([jsonObject isKindOfClass:[NSDictionary class]]) {
									   _cardDictionary = jsonObject;
									   completionHandler(nil);
									   [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactLoaded" object:self];
									   [self writeToDisk];
									   
								   } else if (jsonError) {
									   
									   // If there was an error parsing the json, say so.
									   completionHandler(jsonError);
									   
								   }
							   } else if (connectionError) {
								   
								   // If there was some kind of connection error, report it.
								   completionHandler(connectionError);
								   
							   } else {
								   
								   // If the result was valid JSON, but NOT a dictionary, this is an error.
								   NSError *error = [NSError errorWithDomain:@"JSON"
																		code:100
																	userInfo:@{NSLocalizedDescriptionKey:@"The returned JSON object is not in the proper digidex format"}];
								   completionHandler(error);
							   }
						   }];
}



- (void)loadImageCompletion:(void (^)(NSError *error))completionHandler;
{
	
	// If completion handler is nil, give it a sensible default value
	if (!completionHandler) {
		completionHandler = ^(NSError* error) {
			// Do nothing...
		};
	}
	
	
	
	// Make sure that the card image URL exists
	if (!self.cardImageURL) {
		NSError *error = [NSError errorWithDomain:@"URL"
											 code:100
										 userInfo:@{NSLocalizedDescriptionKey:@"cardImageURL is missing."}];
		completionHandler(error);
		return;
	}
	
	
	// Do an HTTP call to fetch the image
	NSURLRequest *jsonRequest = [NSURLRequest requestWithURL:self.cardImageURL];
	
	// Perform the JSON request
	[NSURLConnection sendAsynchronousRequest:jsonRequest
									   queue:[NSOperationQueue currentQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
							   
							   if (data && !connectionError) {
								   
								   // The image load was successful.
								   _cardImage = [[UIImage alloc] initWithData:data];
								   completionHandler(nil);
								   [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoaded" object:self];
								   
							   } else if (connectionError) {
								   
								   // If there was some kind of connection error, report it.
								   completionHandler(connectionError);
							   } else {
								   
								   // For some reason the data was missing.
								   NSError *error = [NSError errorWithDomain:@"ImageData"
																		code:100
																	userInfo:@{NSLocalizedDescriptionKey:@"Card Image data is invalid"}];
								   completionHandler(error);
							   }
							   
						   }];
	
}

- (void)writeToDisk;
{
	
	NSLog(@"Writing contact to disk!");
	// Get the path to the Application Support folder
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *applicationSupportDirectory = [paths firstObject];
	
	NSString *digidexApplicationSupportDirectory = [applicationSupportDirectory stringByAppendingPathComponent:@"Digidex"];
	NSError *createDirectoryError;
	[[NSFileManager defaultManager] createDirectoryAtPath:digidexApplicationSupportDirectory withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
	if (createDirectoryError) {
		NSLog(@"There was an error creating the digidex folder in the sandboxed Application Support folder: %@", createDirectoryError.localizedDescription);
	}
	
	NSString *baseFileName = self.guessedName ? self.guessedName : @"Unknown Card";
	
	
	if (!self.localPath) {
		
		// First, check to see if this file exists already. We don't want to overwrite a different contact with the same name!
		NSString *finalFilePath = nil;
		NSUInteger testFileNumber = 0;
		while (finalFilePath == nil) {
			
			testFileNumber++;
			
			// Same-named contacts have a number after it (like Example.json, Example 2.json, Example 3.json, etc)
			NSString *testFileName;
			if (testFileNumber == 1) {
				testFileName = [baseFileName stringByAppendingPathExtension:@"json"];
			} else {
				testFileName = [baseFileName stringByAppendingFormat:@" %li.json", (unsigned long)testFileNumber];
			}
			
			
			NSString *testFilePath = [digidexApplicationSupportDirectory stringByAppendingPathComponent:testFileName];
			if (![[NSFileManager defaultManager] fileExistsAtPath:testFilePath]) {
				finalFilePath = testFilePath;
			}
		}
		
		NSLog(@"Final File path is %@", finalFilePath);
		
		self.localPath = finalFilePath;
	}
	
	// Write this JSON data to the URL specified.
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.cardDictionary options:NSJSONWritingPrettyPrinted error:&error];
	if (error) {
		NSLog(@"Error occurred while writing JSON card file: %@", error.localizedDescription);
		return;
	}
	
	if (jsonData) {
		NSLog(@"Writing file to %@", self.localPath);
		[[NSFileManager defaultManager] createFileAtPath:self.localPath contents:jsonData attributes:@{}];
		
		// Now that the file has been written, make sure to save the updates.
		NSError *saveError;
		[self.managedObjectContext save:&saveError];
		if (saveError) {
			NSLog(@"Error saving managed object context %@", error);
		}
	}
}

@end
