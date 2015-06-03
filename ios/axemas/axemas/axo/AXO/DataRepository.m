//
//  DataRepository.m
//  PikaBlink
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "DataRepository.h"
#import <Foundation/Foundation.h>

static DataRepository *instance_;

@interface DataRepository ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong,nonatomic) NSDictionary *options;

@end


@implementation DataRepository

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (void) setSharedOptions: (NSDictionary*)options {
    DataRepository *shared = [DataRepository shared];
    if (shared->_managedObjectContext != nil){
        [NSException raise:@"ManagedObjectContext error!" format:@"ManagedObjectContext has been already created!"];
    }
    shared.options = options;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.options = @{@"dataRepository":@"DataRepository",@"repositoryDBUrl":@"DataRepository"};
    }
    return self;
}

+ (void)initialize {
    static BOOL initialized = NO;

    if(!initialized) {
        initialized = YES;
        instance_ = [[DataRepository alloc] init];
    }
}

+ (NSString*)newId {
    NSUUID *msg_uuid = [NSUUID UUID];
    return [msg_uuid UUIDString];
}

+ (void)setNSManagedObjectAttribute:(NSManagedObject*)object value:(id)value forKey:(NSString*)name {
    NSEntityDescription *entity = object.entity;
    NSDictionary *properties = entity.propertiesByName;
    
    @try {
        NSAttributeDescription *attribute = properties[name];
        id coercedValue = value;
        
        if ([value isKindOfClass:[NSNull class]])
            coercedValue = nil;
        else if ([attribute respondsToSelector:@selector(attributeType)] && (attribute.attributeType == NSDateAttributeType) && ([value isKindOfClass:[NSString class]])) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            coercedValue = [formatter dateFromString:value];
        }
        
        [object setValue:coercedValue forKey:name];
    }
    @catch (NSException *e) {
        if ([e.name isEqualToString:@"NSUnknownKeyException"])
            NSLog(@"DataRepository - Ignoring unknown attribute %@ for model %@", name, entity.name);
        else
            @throw(e);
    }
}

+ (DataRepository*)shared {
    return instance_;
}

- (NSManagedObject*)get:(NSString*)entityName byId:(NSString*)entityId {
    __block NSManagedObject *updatedObject = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@" argumentArray:@[entityId]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && fetchedObjects.count)
            updatedObject = fetchedObjects[0];
    }];
    
    return updatedObject;
}

- (void)deleteEntity:(NSString*)entityName byId:(NSString*)entityId {
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@" argumentArray:@[entityId]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && fetchedObjects.count) {
            [self.managedObjectContext deleteObject:[fetchedObjects objectAtIndex:0]];
            [self save];
        }
    }];
}

- (NSManagedObject*)updateEntity:(NSString*)entityName byId:(NSString*)entityId withData:(NSDictionary*)data {
    __block NSManagedObject *updatedObject = nil;

    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@" argumentArray:@[entityId]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && fetchedObjects.count)
            updatedObject = fetchedObjects[0];
        
        if (updatedObject) {
            [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [DataRepository setNSManagedObjectAttribute:updatedObject value:obj forKey:key];
            }];
            
            [self save];
        }
    }];
    
    return updatedObject;
}

- (NSArray*)fetchEntities:(NSString*)entityName withQuery:(NSString*)query withArguments:(NSArray*)args
                sortingBy:(NSArray*)sorting {
    __block NSArray *fetchedObjects = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:20];
        
        if (sorting) {
            //Sorting is in the form @[@[@field, @YES]]
            NSMutableArray *sortDescriptors = [NSMutableArray new];
            for (NSArray *sort in sorting) {
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sort[0]
                                                                               ascending:[sort[1] boolValue]];
                [sortDescriptors addObject:sortDescriptor];
            }
            
            if (sortDescriptors.count)
                [fetchRequest setSortDescriptors:sortDescriptors];
        }
        
        if (query) {
            NSArray *query_args = args;
            if (!query_args)
                query_args = @[];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:query argumentArray:query_args];
            [fetchRequest setPredicate:predicate];
        }
        
        NSError *error = nil;
        fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error)
            fetchedObjects = nil;
    }];
    
    return fetchedObjects;
}

- (NSArray*)fetchAndModifyEntities:(NSString*)entityName withQuery:(NSString*)query withArguments:(NSArray*)args
                         sortingBy:(NSArray*)sorting setData:(NSDictionary*)data {
    __block NSArray *fetchedObjects = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:20];
        
        if (sorting) {
            //Sorting is in the form @[@[@field, @YES]]
            NSMutableArray *sortDescriptors = [NSMutableArray new];
            for (NSArray *sort in sorting) {
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sort[0]
                                                                               ascending:[sort[1] boolValue]];
                [sortDescriptors addObject:sortDescriptor];
            }
            
            if (sortDescriptors.count)
                [fetchRequest setSortDescriptors:sortDescriptors];
        }
        
        if (query) {
            NSArray *query_args = args;
            if (!query_args)
                query_args = @[];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:query argumentArray:query_args];
            [fetchRequest setPredicate:predicate];
        }
        
        NSError *error = nil;
        fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (!error && fetchedObjects.count) {
            for(NSManagedObject *updatedObject in fetchedObjects) {
                [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [DataRepository setNSManagedObjectAttribute:updatedObject value:obj forKey:key];
                }];
            }
            
            [self save];
        }
    }];
    
    return fetchedObjects;
}

- (NSManagedObject*)insertEntity:(NSString*)entityName withData:(NSDictionary*)data {
    __block NSManagedObject *newManagedObject = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                         inManagedObjectContext:self.managedObjectContext];
        
        [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [DataRepository setNSManagedObjectAttribute:newManagedObject value:obj forKey:key];
        }];
        
        if ([data objectForKey:@"uid"] == nil)
            [newManagedObject setValue:[DataRepository newId] forKey:@"uid"];
        
        [self save];
    }];
    
    return newManagedObject;
}

- (void)insertEntities:(NSString*)entityName withData:(NSArray*)entities {
    [self.managedObjectContext performBlockAndWait:^{
        for (NSDictionary *data in entities) {
            NSManagedObject * newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                               inManagedObjectContext:self.managedObjectContext];
            
            [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [DataRepository setNSManagedObjectAttribute:newManagedObject value:obj forKey:key];
            }];
            
            if ([data objectForKey:@"uid"] == nil)
                [newManagedObject setValue:[DataRepository newId] forKey:@"uid"];
        }
        
        [self save];
    }];
}



- (void)save {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"DataRepository - Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        //[_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self.options valueForKey:@"dataRepository"] withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[self.options valueForKey:@"repositoryDBUrl"]];
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"DataRepository - Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
