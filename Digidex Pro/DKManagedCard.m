//
//  DKManagedCard.m
//  DigidexKit
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DKManagedCard.h"
#import "DKManagedTag.h"

#import "HTMLDocument.h"
#import "AFNetworking.h"



@interface UIImage (resizeImage)

+ (UIImage*)imagewithImage:(UIImage*)image scaledByFactor:(CGFloat)scaleFactor;
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end

@implementation UIImage (resizeImage)

+ (UIImage*)imagewithImage:(UIImage*)image scaledByFactor:(CGFloat)scaleFactor; {
	
	CGSize newSize = CGSizeMake(image.size.width * scaleFactor, image.size.height * scaleFactor);
	return [UIImage imageWithImage:image scaledToSize:newSize];
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize; {
	
	UIGraphicsBeginImageContext( newSize );
	[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

@end



@implementation DKManagedCard

@dynamic localFilename;
@dynamic originalURL;
@dynamic tags;

@synthesize cardDictionary = _cardDictionary;

- (instancetype)initWithContactURL:(NSURL *)URL managedObjectContext:(NSManagedObjectContext *)moc insert:(BOOL)shouldInsertAutomatically;
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Card" inManagedObjectContext:moc];
	
	self = [self initWithEntity:entity insertIntoManagedObjectContext:(shouldInsertAutomatically ? moc : nil)];
	
    if (self) {
		
		_cardUpdated = NO;
		_cardImageSize = CGSizeZero;
		_cachedCardImageSize = CGSizeZero;
		_localImageSize = CGSizeZero;
		self.originalURL = URL;
		[self reloadCard];
		
    }
    return self;
}

- (instancetype)initWithContactURL:(NSURL *)URL insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;
{
	return [self initWithContactURL:URL managedObjectContext:moc insert:YES];
}


- (instancetype)initWithDictionary:(NSDictionary*)dictionary image:(UIImage*)image managedObjectContext:(NSManagedObjectContext *)moc insert:(BOOL)shouldInsertAutomatically;
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Card" inManagedObjectContext:moc];
	
	self = [self initWithEntity:entity insertIntoManagedObjectContext:(shouldInsertAutomatically ? moc : nil)];
	
	if (self) {
		
		_cardUpdated = NO;
		
		_cardDictionary = dictionary;
		
		if (image) {
			_cardImage = image;
			_cardImageSize = image.size;
			[self setCachedCardImage:image];
			[self regenerateThumbnail];
		}
		
		if (shouldInsertAutomatically && moc) {
			[self writeToDisk];
			[self writeImageToDisk];
		}
	}
	return self;
}
- (instancetype)initWithDictionary:(NSDictionary*)dictionary image:(UIImage*)image insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;
{
	return [self initWithDictionary:dictionary image:image managedObjectContext:moc insert:YES];
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
	NSURL *url;
	if (_cardDictionary[@"_cardURL"]) {
		url = [NSURL URLWithString:_cardDictionary[@"_cardURL"]];
	} else {
		url = [NSURL URLWithString:_cardDictionary[@"cardURL"]];
	}
	
	return url;
}


- (NSString *)guessedName;
{
	
	NSArray *guessedNameKeys = [self guessedNameKeys];
	NSString *guessedName = @"";
	
	for (NSString *key in guessedNameKeys) {
		guessedName = [guessedName stringByAppendingFormat:@" %@", _cardDictionary[key]];
	}
	
	guessedName = [guessedName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (guessedName.length > 0)
		return guessedName;
	else
		return nil;
}

- (NSArray *)guessedNameKeys;
{
	if (_cardDictionary[@"name"]) {
		return @[@"name"];
	}
	
	
	
	// Here are some possible alternatives I came up with.
	if (_cardDictionary[@"fullName"]) {
		return @[@"fullName"];
	}
	
	if (_cardDictionary[@"firstName"] && _cardDictionary[@"lastName"]) {
		return @[@"firstName", @"lastName"];
	}
	
	if (_cardDictionary[@"firstName"]) {
		return @[@"firstName"];
	}
	
	if (_cardDictionary[@"lastName"]) {
		return @[@"lastName"];
	}
	
	return @[];
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



- (void)setCachedCardImage:(UIImage *)image;
{
	_cachedCardImage = image;
	_cachedCardImageSize = image.size;
}

- (UIImage *)cardImage;
{
	if (_cardImage) {
		return _cardImage;
	} else if (_cachedCardImage) {
		return _cachedCardImage;
	} else if (self.localImagePath && [[NSFileManager defaultManager] fileExistsAtPath:self.localImagePath isDirectory:nil]) {
		return [UIImage imageWithContentsOfFile:self.localImagePath];
	} else {
		return [UIImage imageNamed:@"placeholderCard.jpg"];
	}
}

- (UIImage *)cardThumbnailImage;
{
	if (_cardThumbnailImage) {
		return _cardThumbnailImage;
	}
	
	// If the thumbnail image isn't ready yet, return the cardImage.
	return self.cardImage;
}

- (void)regenerateThumbnail;
{
	// If the original card image doesn't exist yet, bail immediately.
	if (!_cardImage)
		return;
	
	// Create a thumbnail version of the image root card view.
	CGSize size = _cardImage.size;
	
	
	// The max width of the card is 200 points.
	CGFloat scaleFactor = 1;
	if (size.width > 200) {
		scaleFactor = 200 / size.width;
	}
	CGSize scaledSize = CGSizeMake(round(size.width * scaleFactor), round(size.height * scaleFactor));
	
	
	// Resize the image
	UIGraphicsBeginImageContext(scaledSize);
	[_cardImage drawInRect:CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height)];
	_cardThumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	// Done Resizing
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ThumbnailGenerated" object:self];
}

- (CGSize)cardImageSize;
{
	if (!CGSizeEqualToSize(_cardImageSize, CGSizeZero)) {
		return _cardImageSize;
	} else if (!CGSizeEqualToSize(_cachedCardImageSize, CGSizeZero)) {
		return _cachedCardImageSize;
	} else if (!CGSizeEqualToSize(_localImageSize, CGSizeZero)) {
		return _localImageSize;
	} else if (self.localImagePath && [[NSFileManager defaultManager] fileExistsAtPath:self.localImagePath isDirectory:nil]) {
		// If the local image size hasn't been calculated yet, but the local image file is available, calculate the size now.
		UIImage *localImage = [UIImage imageWithContentsOfFile:self.localImagePath];
		_localImageSize = localImage.size;
		return _localImageSize;
	}
	
	// If there are no other options, then simply return CGSizeZero.
	return CGSizeZero;
}

- (NSURL*)digidexURL;
{
    if (self.originalURL) {
		if (![[self.originalURL scheme] isEqualToString:@"digidex"]) {
			NSString *newURLString = [NSString stringWithFormat:@"digidex:%@", [self.originalURL absoluteString]];
			return [NSURL URLWithString:newURLString];
        }
        
        return self.originalURL;
    }
	
    // If the originalURL is not available, return nil
    return nil;
}


- (NSArray *)filteredKeys;
{
	if (!_filteredKeys || _cardUpdated) {
		
		NSArray *orderedKeys = [DKManagedCard orderedKeysForObject:self.cardDictionary];
		
		// Also make sure this key is not a named key
		_filteredKeys = [orderedKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			return (![[self guessedNameKeys] containsObject:evaluatedObject]);
		}]];
		
		_cardUpdated = NO;
	}
	
	return _filteredKeys;
}

+ (NSArray*)orderedKeysForObject:(NSDictionary*)object;
{
	
	NSArray *orderedKeys = [object allKeys];
	
	// If this object has a "_order" key, then use that instead.
	if (object[@"_order"] && [object[@"_order"] isKindOfClass:[NSArray class]]) {
		orderedKeys = object[@"_order"];
	} else {
		orderedKeys = [orderedKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			return [obj1 compare:obj2];
		}];
	}
	
	
	// cross-check that each item in the _order actually has a corresponding key in the dictionary
	NSArray *filteredKeys = [orderedKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		
		// Make sure this key actually exists in the dictionary, and that it doesn't start with an underscore.
		return (object[evaluatedObject] != nil && ![evaluatedObject hasPrefix:@"_"]);
	}]];
	
	
	return filteredKeys;
}


- (void)loadCardFromCachedData;
{
	if (self.localPath) {
		
        NSLog(@"path: %@", self.localPath);
		// Load the JSON document from the local disk, and read it.
		NSData *cardData = [[NSFileManager defaultManager] contentsAtPath:self.localPath];
        NSLog(@"data: %@", [[NSString alloc] initWithData:cardData encoding:NSUTF8StringEncoding]);
        
		if (cardData) {
			NSError *jsonError;
			id jsonObject = [NSJSONSerialization JSONObjectWithData:cardData options:kNilOptions error:&jsonError];
			
			// Double check that the result file is a dictionary.
			if ([jsonObject isKindOfClass:[NSDictionary class]]) {
				_cardDictionary = jsonObject;
				_cardUpdated = YES;
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
	
	
	if (self.localImagePath) {
		_cachedCardImage = [UIImage imageWithContentsOfFile:self.localImagePath];
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
	
	NSLog(@"loadContact Data. Original URL: %@", self.originalURL);
	
	
	// Make sure that we actually have a card URL here
	if (!self.originalURL) {
		NSError *error = [NSError errorWithDomain:@"URL"
											 code:100
										 userInfo:@{NSLocalizedDescriptionKey:@"cardImageURL is missing."}];
        
        NSLog(@"%@", self.cardDictionary);
		completionHandler(error);
		return;
	} else if ([[self.originalURL scheme] isEqualToString:@"digidex"]) {
		
		// If this is a digidex URL, chop off the scheme to get the http(s)
		NSString *originalURLString = [self.originalURL absoluteString];
		NSString *newURLString = [originalURLString substringFromIndex:@"digidex:".length];

		self.originalURL = [NSURL URLWithString:newURLString];
		
		NSError *error;
		[self.managedObjectContext save:&error];
		if (error) {
			NSLog(@"Error occurred saving card: %@", error);
		}
	}
	
	
	// We have to download this data now.
	NSURLRequest *jsonRequest = [NSURLRequest requestWithURL:self.originalURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
	
	
	// Perform the JSON request
	[NSURLConnection sendAsynchronousRequest:jsonRequest
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
							   
                               NSLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
							   
							   if (data) {
								   NSError *jsonError;
								   id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
								   
								   // Double check that the result file is a dictionary.
								   if ([jsonObject isKindOfClass:[NSDictionary class]]) {
									   _cardDictionary = jsonObject;
									   _cardUpdated = YES;
									   completionHandler(nil);
									   
									   if ([self managedObjectContext])
										   [self writeToDisk];
									   
									   [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactLoaded" object:self];
									   
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
		
		
		if (!self.originalURL && self.localImagePath) {
			
			// If this is an offline card, then load the card locally.
			_cardImage = [UIImage imageWithContentsOfFile:self.localImagePath];
			completionHandler(nil);
			
		} else {
			NSError *error = [NSError errorWithDomain:@"URL"
												 code:100
											 userInfo:@{NSLocalizedDescriptionKey:@"cardImageURL is missing, and no local image was found."}];
			completionHandler(error);
		}
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
								   _cardImageSize = _cardImage.size;
								   completionHandler(nil);
								   
								   if ([self managedObjectContext])
									   [self writeImageToDisk];
								   
								   [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoaded" object:self];
								   [self regenerateThumbnail];
								   
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










- (NSString*)localApplicationSupportDirectory;
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *applicationSupportDirectory = [paths firstObject];
	
	NSString *digidexApplicationSupportDirectory = [applicationSupportDirectory stringByAppendingPathComponent:@"Digidex"];
	NSError *createDirectoryError;
	[[NSFileManager defaultManager] createDirectoryAtPath:digidexApplicationSupportDirectory withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
	if (createDirectoryError) {
		NSLog(@"There was an error creating the digidex folder in the sandboxed Application Support folder: %@", createDirectoryError.localizedDescription);
	}
	
	return digidexApplicationSupportDirectory;
}


- (void)writeToDisk;
{
	
	NSLog(@"Writing contact to disk!");
	
	NSString *digidexApplicationSupportDirectory = [self localApplicationSupportDirectory];
	
	NSString *baseFileName = self.guessedName ? self.guessedName : @"Unknown Card";
	
	
	if (!self.localFilename) {
		
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
		
		self.localFilename = [finalFilePath lastPathComponent];
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

- (void)writeImageToDisk;
{
	// If the image is not available, bail out now.
	if (!_cardImage) {
		return;
	}
	
	NSData *imageData = UIImagePNGRepresentation(_cardImage);
	if (imageData) {
		[[NSFileManager defaultManager] createFileAtPath:self.localImagePath contents:imageData attributes:@{}];
	}
}

- (void)deleteCachedFile;
{
	NSError *error;
	[[NSFileManager defaultManager] removeItemAtPath:self.localPath error:&error];
	if (error)
		NSLog(@"Error deleting file: %@", error);
	
	[[NSFileManager defaultManager] removeItemAtPath:self.localImagePath error:&error];
	if (error)
		NSLog(@"Error deleting file: %@", error);
}


- (NSString*)localPath;
{
	if (self.localFilename == nil) {
		return nil;
	}
	
	NSString *digidexApplicationSupportDirectory = [self localApplicationSupportDirectory];
	
	return [digidexApplicationSupportDirectory stringByAppendingPathComponent:self.localFilename];
}

- (NSString*)localImageFilename;
{
	if (self.localFilename == nil)
		return nil;
	
	NSString *baseFilename = [self.localFilename stringByDeletingPathExtension];
	return [baseFilename stringByAppendingPathExtension:@"png"];
}

- (NSString*)localImagePath;
{
	if (self.localImageFilename == nil)
		return nil;
	
	NSString *digidexApplicationSupportDirectory = [self localApplicationSupportDirectory];
	
	return [digidexApplicationSupportDirectory stringByAppendingPathComponent:self.localImageFilename];
}








// UPLOAD Maximum is 1.5 MB ~= 1,500,000 B
#define UPLOAD_TARGET_SIZE 1500000.0

- (void)publishWithProgress:(void (^)(NSString *status, AFHTTPRequestOperation *activeOperation))progressHandler completion:(void (^)(NSError *error))completionHandler;
{
	
	// The results object will represent the new card.
	NSString *baseURLString = @"http://rectangoapp.com/api/";
	
	
	// First, upload the image...
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", nil];
	
	manager.requestSerializer = [AFJSONRequestSerializer serializer];
	NSLog(@"manager request serializer: %@", manager.requestSerializer);
	
	
	
	
	// This will be called either when the image upload completes, or, in the case of a nil image, immediately.
	void (^publishJSONWithImageURL)(NSString*imageURLString) = ^(NSString*imageURLString) {
		NSMutableDictionary *resultsCopy = [_cardDictionary mutableCopy];
		
		if (imageURLString != nil)
			[resultsCopy setObject:imageURLString forKey:@"_cardURL"];
		
		NSDictionary *parameters = [NSDictionary dictionaryWithDictionary:resultsCopy];
		
		
		// Submit the JSON request to create the card.
		AFHTTPRequestOperation *recordCreateOperation = [manager POST:[baseURLString stringByAppendingPathComponent:@"digidex.php"] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
			
			// Card returned. Here is the URL for it.
			NSString *cardURLString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			
			NSURL *cardURL = [NSURL URLWithString:cardURLString];
			self.originalURL = cardURL;
			
			NSError *error;
			[self.managedObjectContext save:&error];
			completionHandler(error); // if there were no errors while saving, then the error object here will be nil
			
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			
			// The card creation failed somehow.
			completionHandler(error);
		}];
		
		
		// Update the alert to indicate that the image upload has finished, and we are now creating the digidex record.
		// pass the operation back to the caller so they may cancel it, if desired.
		progressHandler(@"Creating Record...", recordCreateOperation);
	};
	
	
	if (_cardImage != nil) {
		
		AFHTTPRequestOperation *uploadOperation = [manager POST:[baseURLString stringByAppendingPathComponent:@"uploadImage.php"] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
			
			
			// Add the URL to the card image.
			if (_cardImage != nil) {
				
				// Scale the image down so that it isn't huge.
				// We want to scale the image down enough so that it's manageable
				
				NSData *uploadImageData = nil;
				NSData *originalImageData =	UIImagePNGRepresentation(_cardImage);
				
				if (originalImageData.length < UPLOAD_TARGET_SIZE) {
					
					// If the original image is less than the maximum, then we don't need to do anything.
					uploadImageData = originalImageData;
				} else {
					
					// Compute how much the image size needs to be reduced.
					CGFloat fileReductionFactor = UPLOAD_TARGET_SIZE / originalImageData.length;
					
					
					// If you scale a rectangle down by 50% (1/2) in each coordinate, the resulting area is 25% (1/4) of the original.
					// Therefore: The desired image scale factor is approx. the square root of the target size reduction.
					CGFloat imageScaleFactor = sqrtf(fileReductionFactor);
					imageScaleFactor = imageScaleFactor * 0.9; // Reduce it by another 10% for goot measure...
					
					UIImage *scaledImage = [UIImage imagewithImage:_cardImage scaledByFactor:imageScaleFactor];
					uploadImageData = UIImagePNGRepresentation(scaledImage);
				}
				
				[formData appendPartWithFileData:uploadImageData name:@"image" fileName:@"businessCard.png" mimeType:@"image/png"];
			}
			
		} success:^(AFHTTPRequestOperation *operation, id responseObject) {
			
			
			// The upload was a success. The file's final resting place is at the returned address.
			NSString *imageURLString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			
			publishJSONWithImageURL(imageURLString);
			
			
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			
			// The image upload failed somehow.
			completionHandler(error);
		}];
		
		// pass the operation back to the caller so they may cancel it, if desired.
		progressHandler(@"Uploading Image...", uploadOperation);
		
	} else {
		publishJSONWithImageURL(nil);
	}
}






#pragma mark - class methods

+ (void)determineDigidexURLFromProvidedURL:(NSURL*)providedURL completion:(void (^)(NSURL *determinedURL))completion;
{
	// This method tries to parse the provided URL to come up with the exact correct digidex: URL.
	
	if ([providedURL.scheme isEqualToString:@"digidex"]) {
		
		// If the URL is already using the digidex scheme, then we can assume it's good.
		completion(providedURL);
		return;
		
	} else if ([providedURL.pathExtension isEqualToString:@"json"]) {
		
		// If the URL is assumed to be JSON. There's no more work to be done.
		// prepend the digidex scheme, and we're done.
		NSString *newURLString = [NSString stringWithFormat:@"digidex:%@", [providedURL absoluteString]];
		completion([NSURL URLWithString:newURLString]);
		return;
		
	} else {
		
		// Okay, we can't take any shortcuts. The only other valid form is HTML content.
		// Perform an HTTP request and check the header to make sure the MIMEtype is HTML content.
		NSURLRequest *providedURLRequest = [NSURLRequest requestWithURL:providedURL];
		[NSURLConnection sendAsynchronousRequest:providedURLRequest queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			
			// Test the response
			NSLog(@"Error is %@", connectionError);
			NSLog(@"Response MIME Type is: %@", response.MIMEType);
			if ([response.MIMEType isEqualToString:@"text/html"]) {
				
				// Load the content of the page, and find the meta tag in the <head>
				HTMLDocument *document;
				NSError *error;
				if (response.textEncodingName != nil) {
					// The string encoding has to go through a couple conversions.
					NSStringEncoding stringEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName));
					document = [HTMLDocument documentWithData:data encoding:stringEncoding error:&error];
				} else {
					document = [HTMLDocument documentWithData:data error:&error];
				}
				
				
				NSArray *metaTags = [document.head childrenOfTag:@"meta"];
				
				NSLog(@"%li meta tags in the document.", (unsigned long)metaTags.count);
				
				// Run through the meta tags until we find one with the right name.
				HTMLNode *selectedTag = nil;
				for (HTMLNode *node in metaTags) {
					
					// Check to see that this tag as the attribute "name" with the value "digidex"
					if ([[node attributeForName:@"name"] isEqualToString:@"digidex"]) {
						
						// This is the right tag, so we're done here.
						selectedTag = node;
						break;
					}
				}
				
				
				
				if (selectedTag != nil) {
					
					// get the content of this tag. It should be a URL
					NSString *content = [selectedTag attributeForName:@"content"];
					NSURL *contentURL = [NSURL URLWithString:content];
					
					if (![contentURL.scheme isEqualToString:@"digidex"]) {
						NSString *newURLString = [NSString stringWithFormat:@"digidex:%@", [contentURL absoluteString]];
						contentURL = [NSURL URLWithString:newURLString];
					}
					
					completion(contentURL);
					return;
				}
			}
			
			completion(nil);
			return;
		}];
	}
}

+ (BOOL)digidexURLIsValid:(NSURL*)digidexURL;
{
	// only support digidex schemes.
	if (![digidexURL.scheme isEqualToString:@"digidex"])
		return NO;
	
	NSString *originalURLString = [digidexURL absoluteString];
	NSString *newURLString = [originalURLString substringFromIndex:@"digidex:".length];
	NSURL *newURL = [NSURL URLWithString:newURLString];
	
	// only support http and https
	if (![newURL.scheme isEqualToString:@"http"] && ![newURLString isEqualToString:@"https"])
		return NO;
	
	return YES;
}

@end
