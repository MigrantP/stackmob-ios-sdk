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
#import "SMIntegrationTestHelpers.h"

SPEC_BEGIN(QueryTestsWithPermissionsSpec)

__block SMDataStore *sm;
__block SMQuery *query;
__block NSDictionary *fixtures;
__block SMClient *client;

NSArray *fixtureNames = [NSArray arrayWithObjects:
                         @"peoplepermissions",
                         @"blogpostspermissions",
                         @"placespermissions",
                         nil];

describe(@"with a prepopulated database of people", ^{
    beforeAll(^{
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_current_queue(), ^{
                syncReturn(semaphore);
            });
        });
        client = [SMIntegrationTestHelpers defaultClient];
        sm = [client dataStore];
        
        // Log in user
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            [client loginWithUsername:@"dude" password:@"sweet" onSuccess:^(NSDictionary *result) {
                NSLog(@"Logged In, %@", result);
                syncReturn(semaphore);
            } onFailure:^(NSError *error) {
                [error shouldBeNil];
                syncReturn(semaphore);
            }];
        });
        
        [SMIntegrationTestHelpers destroyAllForFixturesNamed:fixtureNames];
    });
    
    afterAll(^{
        // Logout
        
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            [client logoutOnSuccess:^(NSDictionary *result) {
                NSLog(@"Logged out");
                syncReturn(semaphore);
            } onFailure:^(NSError *error) {
                [error shouldBeNil];
                syncReturn(semaphore);
            }];
        });
        
    });
    
    beforeEach(^{
        fixtures = [SMIntegrationTestHelpers loadFixturesNamed:fixtureNames];
        [fixtures shouldNotBeNil];
    });
    
    afterEach(^{
        [SMIntegrationTestHelpers destroyAllForFixturesNamed:fixtureNames];
    });
    
    describe(@"-query with initWithSchema", ^{
        beforeEach(^{
            query = [[SMQuery alloc] initWithSchema:@"peoplepermissions"];
        });
        it(@"works", ^{
            [query where:@"last_name" isEqualTo:@"Vaznaian"];
            synchronousQuery(sm, query, ^(NSArray *results) {
                NSLog(@"Objects: %@", results);
            }, ^(NSError *error) {
                NSLog(@"Error: %@", error);
            });
        });
    });
    
    
    describe(@"where clauses", ^{
        beforeEach(^{
            query = [[SMQuery alloc] initWithSchema:@"peoplepermissions"];
        });
        it(@"-where:isEqualTo", ^{
            [query where:@"last_name" isEqualTo:@"Williams"];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:1];
                [[[[results objectAtIndex:0] objectForKey:@"first_name"] should] equal:@"Jonah"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isNotEqualTo", ^{
            [query where:@"last_name" isNotEqualTo:@"Williams"];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:2];
                NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES]]];
                [[[[sortedResults objectAtIndex:0] objectForKey:@"last_name"] should] equal:@"Cooper"];
                [[[[sortedResults objectAtIndex:1] objectForKey:@"last_name"] should] equal:@"Vaznaian"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isLessThan", ^{
            [query where:@"armor_class" isLessThan:[NSNumber numberWithInt:17]];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:2];
                NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES]]];
                [[[[sortedResults objectAtIndex:0] objectForKey:@"last_name"] should] equal:@"Cooper"];
                [[[[sortedResults objectAtIndex:1] objectForKey:@"last_name"] should] equal:@"Williams"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isLessThanOrEqualTo", ^{
            [query where:@"armor_class" isLessThanOrEqualTo:[NSNumber numberWithInt:17]];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:3];
                NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES]]];
                [[[[sortedResults objectAtIndex:0] objectForKey:@"last_name"] should] equal:@"Cooper"];
                [[[[sortedResults objectAtIndex:1] objectForKey:@"last_name"] should] equal:@"Vaznaian"];
                [[[[sortedResults objectAtIndex:2] objectForKey:@"last_name"] should] equal:@"Williams"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isGreaterThan", ^{
            [query where:@"armor_class" isGreaterThan:[NSNumber numberWithInt:15]];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:1];
                [[[[results objectAtIndex:0] objectForKey:@"last_name"] should] equal:@"Vaznaian"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isGreaterThanOrEqualTo", ^{
            [query where:@"armor_class" isGreaterThanOrEqualTo:[NSNumber numberWithInt:15]];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:2];
                NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES]]];
                [[[[sortedResults objectAtIndex:0] objectForKey:@"last_name"] should] equal:@"Vaznaian"];
                [[[[sortedResults objectAtIndex:1] objectForKey:@"last_name"] should] equal:@"Williams"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isIn", ^{
            [query where:@"first_name" isIn:[NSArray arrayWithObjects:@"Jon", @"Jonah", nil]];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:2];
                NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES]]];
                [[[[sortedResults objectAtIndex:0] objectForKey:@"last_name"] should] equal:@"Cooper"];
                [[[[sortedResults objectAtIndex:1] objectForKey:@"last_name"] should] equal:@"Williams"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
    });
    
    describe(@"multiple where clauses per query", ^{
        beforeEach(^{
            query = [[SMQuery alloc] initWithSchema:@"peoplepermissions"];
        });
        afterEach(^{
            query = nil;
        });
        it(@"works", ^{
            [query where:@"company" isEqualTo:@"Carbon Five"];
            [query where:@"first_name" isEqualTo:@"Jonah"];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:1];
                [[[results objectAtIndex:0] should] haveValue:@"Williams" forKey:@"last_name"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
    });
    
    describe(@"pagination and limit", ^{
        beforeEach(^{
            query = [[SMQuery alloc] initWithSchema:@"blogpostspermissions"];
        });
        it(@"-fromIndex:toIndex", ^{
            __block NSArray *expectedObjects = [NSArray arrayWithObjects:@"D", @"E", @"F", @"G", @"H", nil];
            [query fromIndex:4 toIndex:8];
            [query orderByField:@"title" ascending:YES];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:5];
                NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
                NSLog(@"sorted results: %@", sortedResults);
                for (int i = 4; i <= 8; i++) {
                    [[[[sortedResults objectAtIndex:i-4] objectForKey:@"title"] should] equal:[NSString stringWithFormat:@"Post %@", [expectedObjects objectAtIndex:i-4]]];
                }
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-limit", ^{
            [query limit:3];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:3];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
    });
    
    describe(@"ordering", ^{
        beforeEach(^{
            query = [[SMQuery alloc] initWithSchema:@"peoplepermissions"];
        });
        it(@"defaults to getting all the matches (i.e.  no 'where')", ^{
            query = [[SMQuery alloc] initWithSchema:@"blogpostspermissions"];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:15];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        describe(@"when the intent is to sort by one field", ^{
            it(@"-orderByField", ^{
                [query orderByField:@"last_name" ascending:YES];
                synchronousQuery(sm, query, ^(NSArray *results) {
                    [[[results objectAtIndex:0] should] haveValue:@"Jon" forKey:@"first_name"];
                    [[[results objectAtIndex:1] should] haveValue:@"Matt" forKey:@"first_name"];
                    [[[results objectAtIndex:2] should] haveValue:@"Jonah" forKey:@"first_name"];
                }, ^(NSError *error){
                    [error shouldBeNil];
                });
            });
        });
        describe(@"when the intent is to sort by multiple fields", ^{
            it(@"-orderByField", ^{
                [query orderByField:@"company" ascending:NO];
                [query orderByField:@"armor_class" ascending:NO];
                synchronousQuery(sm, query, ^(NSArray *results) {
                    [[[results objectAtIndex:0] should] haveValue:@"Matt" forKey:@"first_name"];
                    [[[results objectAtIndex:1] should] haveValue:@"Jonah" forKey:@"first_name"];
                    [[[results objectAtIndex:2] should] haveValue:@"Jon" forKey:@"first_name"];
                }, ^(NSError *error){
                    [error shouldBeNil];
                });
            });
        });
    });
    
    describe(@"geo", ^{
        CLLocationCoordinate2D sf = CLLocationCoordinate2DMake(37.7750, -122.4183);
        CLLocationCoordinate2D azerbaijan = CLLocationCoordinate2DMake(40.338170, 48.065186);
        
        beforeEach(^{
            query = [[SMQuery alloc] initWithSchema:@"placespermissions"];
        });
        describe(@"-where:near", ^{
            beforeEach(^{
                [query where:@"location" near:sf];
            });
            it(@"orders the returned objects by server-inserted field 'location.distance'", ^{
                synchronousQuery(sm, query, ^(NSArray *results) {
                    [[results should] haveCountOf:4];
                    [[[results objectAtIndex:0] should] haveValue:@"San Francisco" forKey:@"name"];
                    [[[results objectAtIndex:1] should] haveValue:@"San Rafael" forKey:@"name"];
                    [[[results objectAtIndex:2] should] haveValue:@"Lake Tahoe" forKey:@"name"];
                    [[[results objectAtIndex:3] should] haveValue:@"Turkmenistan" forKey:@"name"];
                    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        [[(NSDictionary *)obj should] haveValueForKeyPath:@"location.distance"];
                    }];
                }, ^(NSError *error){
                    [error shouldBeNil];
                });
            });
        });
        
        it(@"-where:isWithin:milesOf", ^{
            [query where:@"location" isWithin:1000.0 milesOf:azerbaijan];
            [query orderByField:@"name" ascending:YES];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:1];
                [[[results objectAtIndex:0] should] haveValue:@"Turkmenistan" forKey:@"name"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        it(@"-where:isWithin:metersOf", ^{
            [query where:@"location" isWithin:35.0 kilometersOf:sf];
            [query orderByField:@"name" ascending:YES];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:2];
                [[[results objectAtIndex:0] should] haveValue:@"San Francisco" forKey:@"name"];
                [[[results objectAtIndex:1] should] haveValue:@"San Rafael" forKey:@"name"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
        
        it(@"-where:isWithinBoundsWithSWCorner:andNECorner", ^{
            CLLocationCoordinate2D swOfSanRafael = CLLocationCoordinate2DMake(37.933096, -122.575493);
            CLLocationCoordinate2D reno = CLLocationCoordinate2DMake(39.537940, -119.783936);
            [query where:@"location" isWithinBoundsWithSWCorner:swOfSanRafael andNECorner:reno];
            [query orderByField:@"name" ascending:YES];
            synchronousQuery(sm, query, ^(NSArray *results) {
                [[results should] haveCountOf:2];
                [[[results objectAtIndex:0] should] haveValue:@"Lake Tahoe" forKey:@"name"];
                [[[results objectAtIndex:1] should] haveValue:@"San Rafael" forKey:@"name"];
            }, ^(NSError *error){
                [error shouldBeNil];
            });
        });
    });
    
});

SPEC_END
