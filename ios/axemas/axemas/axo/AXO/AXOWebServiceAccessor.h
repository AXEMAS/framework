//
//  AXOWebServiceAccessor.h
//  AXO
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AXOWebServiceAccessor : NSObject

@property (atomic) BOOL simulateSlowNetwork;  // Set YES to simulate a 1 second delay in requests.
@property NSString* authToken;  // Set this to a string which is used as authentication token in requests.
@property (copy) void (^onError)(NSString *path, id operation);  // Set this to a block that has to be called when a request fails.


// Configure WebServiceAccessor as Singleton
+ (AXOWebServiceAccessor*)makeSharedWithUrl:(NSString*) webServiceUrl andApiPoint:(NSString*)apiMount;
// Get back the shared instance configured by makeSharedWithUrl.
+ (AXOWebServiceAccessor*)shared;

// In case multiple instances are needed.
- (id)initWithUrl:(NSString*) webServiceUrl andApiPoint:(NSString*)apiMount;

// Wait until finish requests methods
- (NSDictionary*)performGETWaitUntilFinish:(NSString*)path withArgs:(NSDictionary*)requestArgs;
- (NSDictionary*)performPOSTWaitUntilFinish:(NSString*)path withArgs:(NSDictionary*)requestArgs;

// Utilities to handle dates in JSON
+ (NSString *)convertDateToJsonString:(NSDate*)date;
+ (NSDate *)convertJsonStringToDate:(NSString *)jsonDate;

@end


/**
 Represents a parameter that has to be encoded accordingly to a specific mime type
 like Images, binary data and so on...
 */
@interface FileFieldParameter : NSObject

- (id)initWithData:(NSData*)data withFileName:(NSString*)filename withMimeType:(NSString*)mimetype;
- (id)initWithData:(NSData*)data;

@end