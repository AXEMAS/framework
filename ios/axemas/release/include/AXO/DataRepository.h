//
//  DataRepository.h
//  PikaBlink
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface DataRepository : NSObject

+ (DataRepository*)shared;
+ (void) setSharedOptions: (NSDictionary*)options;

- (void)deleteEntity:(NSString*)entityName byId:(NSString*)entityId;
- (NSManagedObject*)get:(NSString*)entityName byId:(NSString*)entityId;
- (NSManagedObject*)insertEntity:(NSString*)entityName withData:(NSDictionary*)data;
- (void)insertEntities:(NSString*)entityName withData:(NSArray*)entities;
- (NSManagedObject*)updateEntity:(NSString*)entityName byId:(NSString*)entityId withData:(NSDictionary*)data;
- (NSArray*)fetchEntities:(NSString*)entityName withQuery:(NSString*)query withArguments:(NSArray*)args
                sortingBy:(NSArray*)sorting;
- (NSArray*)fetchAndModifyEntities:(NSString*)entityName withQuery:(NSString*)query withArguments:(NSArray*)args
                         sortingBy:(NSArray*)sorting setData:(NSDictionary*)data;

@end
