//
//  AXOWebServiceAccessor.m
//  AXO
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import "AXOWebServiceAccessor.h"
#import "AFNetworking/AFNetworking.h"
#import "AFNetworking/AFHTTPRequestOperationManager.h"

@interface FileFieldParameter ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *mimetype;

- (void)addToMultipartFormData:(id<AFMultipartFormData>)formdata withName:(NSString*)name;

@end


@implementation FileFieldParameter

- (id)initWithData:(NSData*)data withFileName:(NSString*)filename withMimeType:(NSString*)mimetype {
    if (self = [super init]) {
        self.data = data;
        self.filename = filename;
        self.mimetype = mimetype;
    }
    return self;
}

- (id)initWithData:(NSData*)data {
    return [self initWithData:data withFileName:nil withMimeType:nil];
}

- (void)addToMultipartFormData:(id<AFMultipartFormData>)formdata withName:(NSString*)name {
    if (self.filename != nil) {
        [formdata appendPartWithFileData:self.data name:name fileName:self.filename mimeType:self.mimetype];
    }
    else {
        [formdata appendPartWithFormData:self.data name:name];
    }
}

@end





@interface AXOWebServiceAccessor ()

@property (readwrite, nonatomic, strong) AFHTTPRequestOperationManager *client;
@property NSString* baseUrl;
@property NSString* apiUrl;

- (NSDictionary*)performRequestWaitUntilFinish:(NSString*)path withArgs:(NSDictionary*)requestArgs withMethod:(NSString*)httpMethod;

@end


@implementation AXOWebServiceAccessor

#pragma mark Singleton Methods
static AXOWebServiceAccessor *shared = nil;

+ (AXOWebServiceAccessor*)initSingletonWithUrl:(NSString *)webServiceUrl andApiPoint:(NSString *)apiMount {
    @synchronized(self){
        if (shared == nil){
            shared = [[self alloc]initWithUrl:webServiceUrl andApiPoint:apiMount];
        }
    }
    return shared;
}

+(AXOWebServiceAccessor*)shared{
    @synchronized(self){
        if (shared == nil){
            shared = [[self alloc]init];
        }
    }
    return shared;
}

- (id)initWithUrl:(NSString*) webServiceUrl andApiPoint:(NSString*)apiMount {
    if (self = [super init]) {
        self.baseUrl = webServiceUrl;
        self.apiUrl = [NSString stringWithFormat:@"%@/%@", self.baseUrl,apiMount];
        self.client = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:self.apiUrl]];
        self.onError = nil;
    }
    return self;
}

#pragma mark WaitUntilFinish methods
// HTTP Blocking Request, returns decoded JSON Object or nil
- (NSDictionary*)performRequestWaitUntilFinish:(NSString*)path withArgs:(NSMutableDictionary*)requestArgs withMethod:(NSString*)httpMethod {
    
    if(self.simulateSlowNetwork) {
        NSLog(@"WARNING: Simulate Slow Net: %@", path);
        [NSThread sleepForTimeInterval:1.0f];
    }

    NSMutableDictionary *multiparData = [NSMutableDictionary new];
    
    NSArray *requestArgsNames = [[requestArgs allKeys] copy];
    for (NSString *paramName in requestArgsNames) {
        id paramValue = [requestArgs objectForKey:paramName];
        if ([paramValue isKindOfClass:[FileFieldParameter class]] || [paramValue isKindOfClass:[NSArray class]]) {
            multiparData[paramName] = paramValue;
            [requestArgs removeObjectForKey:paramName];
        }
    }
    
    AFHTTPRequestOperation *operation = nil;
    if([httpMethod isEqualToString:@"GET"]) {
        if (multiparData.count) {
            @throw [NSException exceptionWithName:@"UnsupportedParameter"
                                           reason:@"GET Requests cannot have multipart parameters"
                                         userInfo:nil];
        }
        operation = [self.client GET:path parameters:requestArgs success:nil failure:nil];
    }
    else {
        operation = [self.client POST:path
                           parameters:requestArgs
            constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                                        for (NSString *paramName in multiparData) {
                                            id paramValue = multiparData[paramName];
                                            if ([paramValue isKindOfClass:[NSArray class]]) {
                                                for (FileFieldParameter *field in paramValue)
                                                    [field addToMultipartFormData:formData withName:paramName];
                                            }
                                            else {
                                                FileFieldParameter *field = paramValue;
                                                [field addToMultipartFormData:formData withName:paramName];
                                            }
                                        }
                                     }
                              success:nil
                              failure:nil];
    }

    [operation start];
    [operation waitUntilFinished];

    NSDictionary *response = nil;
    if (operation.error == nil)
        response = (NSDictionary *) operation.responseObject;
    else if (self.onError)
        self.onError(path, operation);
    
    return response;
}

// Internal Implementation of the Request, adds auth token when available
- (NSDictionary*)performAuthenticatedRequestWaitUntilFinish:(NSString*)path withArgs:(NSDictionary*)requestArgs withMethod:(NSString*)httpMethod {
    NSMutableDictionary *mutableRequestArgs = [requestArgs mutableCopy];
    if (self.authToken){
        [mutableRequestArgs setObject:self.authToken forKey:@"token"];
    }else{
        NSLog(@"WARNING: authToken is nil, performing unauthenticated request");
    }
    return [self performRequestWaitUntilFinish:path withArgs:mutableRequestArgs withMethod:httpMethod];
    
}

- (NSDictionary*)performGETWaitUntilFinish:(NSString*)path withArgs:(NSDictionary*)requestArgs {
    return [self performAuthenticatedRequestWaitUntilFinish:path withArgs:requestArgs withMethod:@"GET"];
}

- (NSDictionary*)performPOSTWaitUntilFinish:(NSString*)path withArgs:(NSDictionary*)requestArgs {
    return [self performAuthenticatedRequestWaitUntilFinish:path withArgs:requestArgs withMethod:@"POST"];
}

+ (NSString *)convertDateToJsonString:(NSDate*)date {
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [dateFormatter stringFromDate:date];
}

+ (NSDate *)convertJsonStringToDate:(NSString *)jsonDate {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate * dateObject = [dateFormat dateFromString:jsonDate];
    return dateObject;
}

- (void)dealloc {
    self.baseUrl = nil;
    self.apiUrl = nil;
    self.authToken = nil;
    self.client = nil;
}

@end
