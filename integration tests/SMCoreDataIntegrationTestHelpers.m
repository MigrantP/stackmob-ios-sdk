/**
 * Copyright 2012 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SMCoreDataIntegrationTestHelpers.h"
#import "SMIncrementalStore.h"
#import "SMIntegrationTestHelpers.h"

static SMCoreDataIntegrationTestHelpers *_singletonInstance;

@interface SMCoreDataIntegrationTestHelpers ()

+ (SMCoreDataIntegrationTestHelpers *)singleton;

@end

@implementation SMCoreDataIntegrationTestHelpers

@synthesize stackMobMOM = _stackMobMOM;
@synthesize stackMobPSC = _stackMobPSC;
@synthesize stackMobMOC = _stackMobMOC;
@synthesize client = _client;

+ (SMCoreDataIntegrationTestHelpers *)singleton {
    if (_singletonInstance == nil) {
        _singletonInstance = [[SMCoreDataIntegrationTestHelpers alloc] init];
    }
    return _singletonInstance;
}

+ (void)removeSQLiteDatabase
{
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSString *applicationStorageDirectory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:applicationName];
    NSString *defaultName = @"CoreDataStore.sqlite";
    NSURL *sqliteDBURL = [NSURL fileURLWithPath:[applicationStorageDirectory stringByAppendingPathComponent:defaultName]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:[sqliteDBURL path]]) {
        NSError *sqliteDeleteError = nil;
        BOOL sqliteDelete = [fileManager removeItemAtURL:sqliteDBURL error:&sqliteDeleteError];
        if (!sqliteDelete) {
            [NSException raise:@"SMCouldNotDeleteSQLiteDatabase" format:@""];
        }
    }
}

+ (NSManagedObjectContext *)moc {
    return [[SMCoreDataIntegrationTestHelpers singleton] stackMobMOC];
}

+ (NSEntityDescription *)entityForName:(NSString *)entityName {
    NSManagedObjectContext *moc = [SMCoreDataIntegrationTestHelpers moc];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
    NSAssert(entity != nil, @"Entity names are case-sensitive, also, check the .xcdatamodeld");
    return entity;
}

+ (NSFetchRequest *)makePersonFetchRequest:(NSPredicate *)predicate {
    NSEntityDescription *entity = [SMCoreDataIntegrationTestHelpers entityForName:@"Person"];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES]]];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)makeFavoriteFetchRequest:(NSPredicate *)predicate {
    NSEntityDescription *entity = [SMCoreDataIntegrationTestHelpers entityForName:@"Favorite"];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"genre" ascending:YES]]];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)makeInterestFetchRequest:(NSPredicate *)predicate {
    NSEntityDescription *entity = [SMCoreDataIntegrationTestHelpers entityForName:@"Interest"];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    return fetchRequest;
}

+ (NSFetchRequest *)makeSuperpowerFetchRequest:(NSPredicate *)predicate {
    NSEntityDescription *entity = [SMCoreDataIntegrationTestHelpers entityForName:@"Superpower"];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    [fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"person"]];
    return fetchRequest;
}

+ (void)executeSynchronousFetch:(NSManagedObjectContext *)moc withRequest:(NSFetchRequest *)fetchRequest andBlock:(SynchronousFetchBlock)block {
    DLog();
    [moc performBlockAndWait:^{
        NSError *error = nil;
        NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
        block(results, error);
    }];
}

+ (void)executeSynchronousSave:(NSManagedObjectContext *)moc withBlock:(SynchronousErrorBlock)block {
    DLog();
    [moc performBlockAndWait:^{
        NSError *anError = nil;
        BOOL saveSuccess = [moc save:&anError];
        
        if (!saveSuccess) {
            DLog(@"save error is %@", [anError description]);
        }
        block(anError);
    }];
}

+ (void)executeSynchronousUpdate:(NSManagedObjectContext *)moc withObject:(NSManagedObjectID *)objectID andBlock:(SynchronousErrorBlock)block {
    DLog();
    [moc performBlockAndWait:^{
        NSError *__autoreleasing anError = nil;
        NSManagedObject *toUpdate = [moc objectWithID:objectID];
        [toUpdate setValue:[NSNumber numberWithInt:20] forKey:@"armor_class"];      
        BOOL success = [moc save:&anError];
        if (!success) {
            DLog(@"save error is %@", [anError description]);
        }
        block(anError);
    }];
}

+ (void)executeSynchronousDelete:(NSManagedObjectContext *)moc withObject:(NSManagedObjectID *)objectID andBlock:(SynchronousErrorBlock)block {
    DLog();
    [moc performBlockAndWait:^{
        NSError *__autoreleasing anError = nil;
        NSManagedObject *toDelete = [moc objectWithID:objectID];
        [moc deleteObject:toDelete];
        BOOL success = [moc save:&anError];
        if (!success) {
            DLog(@"save error is %@", [anError description]);
        }
        block(anError);
    }];
}




+ (void)registerForMOCNotificationsWithContext:(NSManagedObjectContext *)context
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MOCDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MOCWillSave:) name:NSManagedObjectContextWillSaveNotification object:context];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MOCDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
}

+ (void)removeObserversrForMOCNotificationsWithContext:(NSManagedObjectContext *)context
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:context];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
}

+ (void)MOCDidChange:(NSNotification *)notification
{
    //DLog(@"MOCDidChange user info is %@", [notification userInfo]);
}

+ (void)MOCWillSave:(NSNotification *)notification
{
    //DLog(@"MOCWillSave user info is %@", [notification userInfo]);
}

+ (void)MOCDidSave:(NSNotification *)notification
{
    //DLog(@"MOCDidSave user info is %@", [notification userInfo]);
}

- (NSManagedObjectModel *)stackMobMOM {
    if (_stackMobMOM == nil) {
        _stackMobMOM = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    }
    return _stackMobMOM;
}

- (NSPersistentStoreCoordinator *)stackMobPSC {
    if (_stackMobPSC == nil) {
        self.client = [SMIntegrationTestHelpers defaultClient];
        [NSPersistentStoreCoordinator registerStoreClass:[SMIncrementalStore class] forStoreType:SMIncrementalStoreType];
        _stackMobPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.stackMobMOM];
        NSError *error;
        
        [_stackMobPSC addPersistentStoreWithType:SMIncrementalStoreType
                                   configuration:nil 
                                             URL:nil
                                         options:[NSDictionary dictionaryWithObject:self.client.dataStore forKey:SM_DataStoreKey]
                                           error:&error];
        if (error != nil) {
            DLog(@"Error: %@", error);
            abort();
        }
    }
    return _stackMobPSC;
}

- (NSManagedObjectContext *)stackMobMOC {
    if (_stackMobMOC == nil) {
        _stackMobMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_stackMobMOC setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [_stackMobMOC setPersistentStoreCoordinator:self.stackMobPSC];
    }
    return _stackMobMOC;
}

+ (BOOL)synchronousSaveInBackgroundWithContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing*)error
{
    NSManagedObjectContext *mainContext = context;
    NSManagedObjectContext *privateContext = mainContext.parentContext;
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = mainContext;
    __block BOOL success = NO;
    __block NSError *saveError = nil;
    [temporaryContext performBlockAndWait:^{
        // do something that takes some time asynchronously using the temp context
        
        // Save Temporary Context
        if (![temporaryContext save:&saveError]) {
            
            
        } else {
            // Save Main Context
            [mainContext performBlockAndWait:^{
                
                if (![mainContext save:&saveError]) {
                    
                    
                } else {
                    // Main Context should always have a private queue parent
                    if (privateContext) {
                        
                        // Save Private Context to disk
                        [privateContext performBlockAndWait:^{
                            
                            if (![privateContext save:&saveError]) {
                                
                                
                                
                            } else {
                                
                                success = YES;
                                
                            }
                            
                        }];
                        
                    }
                }
                
            }];
            
        }
        
    }];
    
    if (saveError != nil) {
        *error = saveError;
    }
    
    return success;
}

@end
