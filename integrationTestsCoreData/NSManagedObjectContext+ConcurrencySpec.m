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

#import <Kiwi/Kiwi.h>
#import "NSManagedObjectContext+Concurrency.h"
#import "StackMob.h"
#import "SMCoreDataIntegrationTestHelpers.h"
#import "SMIntegrationTestHelpers.h"

SPEC_BEGIN(NSManagedObjectContext_ConcurrencySpec)

describe(@"fetching runs in the background", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    __block NSMutableArray *arrayOfObjects = nil;
    
    beforeAll(^{
        client = [SMIntegrationTestHelpers defaultClient];
        [SMClient setDefaultClient:client];
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds contextForCurrentThread];
        arrayOfObjects = [NSMutableArray array];
        for (int i=0; i < 30; i++) {
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
            [newManagedObject setValue:@"bob" forKey:@"title"];
            [newManagedObject setValue:[newManagedObject assignObjectId] forKey:[newManagedObject primaryKeyField]];
            
            [arrayOfObjects addObject:newManagedObject];
        }
        __block BOOL saveSuccess = NO;
        __block NSError *error = nil;
        
        saveSuccess = [moc saveAndWait:&error];
        [[theValue(saveSuccess) should] beYes];
    });
    afterAll(^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        for (NSManagedObject *obj in arrayOfObjects) {
            [moc deleteObject:obj];
        }
        __block NSError *error = nil;
        BOOL saveSuccess = [moc saveAndWait:&error];
        [[theValue(saveSuccess) should] beYes];
        [arrayOfObjects removeAllObjects];
        
    });
    it(@"fetches, sync method", ^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSError *error = nil;
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Todo"];
        NSArray *results = [moc executeFetchRequestAndWait:fetch error:&error];
        [results shouldNotBeNil];
        [error shouldBeNil];
        
    });
    it(@"fetches, async method", ^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Todo"];
        dispatch_group_enter(group);
        [moc executeFetchRequest:fetch returnManagedObjectIDs:NO successCallbackQueue:queue failureCallbackQueue:queue onSuccess:^(NSArray *results) {
            [results shouldNotBeNil];
            dispatch_group_leave(group);
        } onFailure:^(NSError *error) {
            [error shouldBeNil];
            dispatch_group_leave(group);
        }];
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
    });
    
    
});

describe(@"Returning managed object vs. ids", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    __block NSMutableArray *arrayOfObjects = nil;
    
    beforeAll(^{
        client = [SMIntegrationTestHelpers defaultClient];
        [SMClient setDefaultClient:client];
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds contextForCurrentThread];
        arrayOfObjects = [NSMutableArray array];
        for (int i=0; i < 30; i++) {
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
            [newManagedObject setValue:@"bob" forKey:@"title"];
            [newManagedObject setValue:[newManagedObject assignObjectId] forKey:[newManagedObject primaryKeyField]];
            
            [arrayOfObjects addObject:newManagedObject];
        }
        __block BOOL saveSuccess = NO;
        __block NSError *error = nil;
        
        saveSuccess = [moc saveAndWait:&error];
        [[theValue(saveSuccess) should] beYes];
    });
    afterAll(^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        for (NSManagedObject *obj in arrayOfObjects) {
            [moc deleteObject:obj];
        }
        __block NSError *error = nil;
        BOOL saveSuccess = [moc saveAndWait:&error];
        [[theValue(saveSuccess) should] beYes];
        [arrayOfObjects removeAllObjects];
        
    });
    it(@"Properly returns managed objects, async method", ^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Todo"];
        dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_enter(group);
        [moc executeFetchRequest:fetch returnManagedObjectIDs:NO successCallbackQueue:queue failureCallbackQueue:queue onSuccess:^(NSArray *results) {
            [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[theValue([obj class] == [NSManagedObject class]) should] beYes];
            }];
            dispatch_group_leave(group);
        } onFailure:^(NSError *error) {
            [error shouldBeNil];
            dispatch_group_leave(group);
        }];
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
        dispatch_release(group);
        dispatch_release(queue);
        
    });
    it(@"Properly returns managed objects ids, async method", ^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Todo"];
        dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_enter(group);
        [moc executeFetchRequest:fetch returnManagedObjectIDs:YES successCallbackQueue:queue failureCallbackQueue:queue onSuccess:^(NSArray *results) {
            [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[theValue([obj isTemporaryID]) should] beNo];
                [[theValue([obj isKindOfClass:[NSManagedObjectID class]]) should] beYes];
            }];
            dispatch_group_leave(group);
        } onFailure:^(NSError *error) {
            [error shouldBeNil];
            dispatch_group_leave(group);
        }];
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
        dispatch_release(group);
        dispatch_release(queue);
        
    });
    it(@"Properly returns managed objects, sync method", ^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Todo"];

        NSError *error = nil;
        NSArray *results = [moc executeFetchRequestAndWait:fetch returnManagedObjectIDs:NO error:&error];
        [error shouldBeNil];
        [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [[theValue([obj class] == [NSManagedObject class]) should] beYes];
        }];
        
    });
    it(@"Properly returns managed objects ids, sync method", ^{
        [[client.session.networkMonitor stubAndReturn:theValue(1)] currentNetworkStatus];
        NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Todo"];
        
        NSError *error = nil;
        NSArray *results = [moc executeFetchRequestAndWait:fetch returnManagedObjectIDs:YES error:&error];
        [error shouldBeNil];
        [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [[theValue([obj isTemporaryID]) should] beNo];
            [[theValue([obj isKindOfClass:[NSManagedObjectID class]]) should] beYes];
        }];
        
    });
});

/*
 describe(@"async save method tests", ^{
 __block SMClient *client = nil;
 __block SMCoreDataStore *cds = nil;
 __block NSManagedObjectContext *moc = nil;
 __block NSMutableArray *arrayOfObjects = nil;
 
 beforeAll(^{
 client = [SMIntegrationTestHelpers defaultClient];
 NSBundle *bundle = [NSBundle bundleForClass:[self class]];
 NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
 cds = [client coreDataStoreWithManagedObjectModel:mom];
 moc = [cds contextForCurrentThread];
 arrayOfObjects = [NSMutableArray array];
 for (int i=0; i < 30; i++) {
 NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
 [newManagedObject setValue:@"bob" forKey:@"title"];
 [newManagedObject setValue:[newManagedObject assignObjectId] forKey:[newManagedObject primaryKeyField]];
 
 [arrayOfObjects addObject:newManagedObject];
 }
 });
 
 afterAll(^{
 __block BOOL saveSucess = NO;
 NSMutableArray *objectIDS = [NSMutableArray array];
 for (NSManagedObject *obj in arrayOfObjects) {
 [objectIDS addObject:[obj valueForKey:@"todoId"]];
 }
 
 for (NSString *objID in objectIDS) {
 syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
 [client.dataStore deleteObjectId:objID inSchema:@"todo" onSuccess:^(NSString *theObjectId, NSString *schema) {
 saveSucess = YES;
 syncReturn(semaphore);
 } onFailure:^(NSError *theError, NSString *theObjectId, NSString *schema) {
 saveSucess = NO;
 syncReturn(semaphore);
 }];
 });
 [[theValue(saveSucess) should] beYes];
 }
 
 
 for (NSManagedObject *obj in arrayOfObjects) {
 [moc deleteObject:obj];
 }
 __block BOOL saveSuccess = NO;
 dispatch_group_enter(group);
 [moc saveWithSuccessCallbackQueue:queue failureCallbackQueue:queue onSuccess:^{
 saveSuccess = YES;
 dispatch_group_leave(group);
 } onFailure:^(NSError *error) {
 dispatch_group_leave(group);
 }];
 
 dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
 
 [[theValue(saveSuccess) should] beYes];
 [arrayOfObjects removeAllObjects];
 
 
 });
 it(@"inserts without error", ^{
 __block BOOL saveSuccess = NO;
 dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
 dispatch_group_t group = dispatch_group_create();
 
 dispatch_group_enter(group);
 [moc saveWithSuccessCallbackQueue:queue failureCallbackQueue:queue onSuccess:^{
 saveSuccess = YES;
 dispatch_group_leave(group);
 } onFailure:^(NSError *error) {
 dispatch_group_leave(group);
 }];
 
 
 dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
 
 
 syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
 [moc saveWithSuccessCallbackQueue:queue failureCallbackQueue:queue onSuccess:^{
 saveSuccess = YES;
 syncReturn(semaphore);
 } onFailure:^(NSError *error) {
 syncReturn(semaphore);
 }];
 });
 
 
 [[theValue(saveSuccess) should] beYes];
 });
 
 });
 */


SPEC_END