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
#import "StackMob.h"

@interface StackMobSerializationSpecUser : SMUserManagedObject

@end

@implementation StackMobSerializationSpecUser

@end

SPEC_BEGIN(NSManagedObject_StackMobSerializationSpec)

describe(@"NSManagedObject_StackMobSerialization", ^{
    describe(@"-assignObjectId", ^{
        context(@"given an object with an id field matching its entity name", ^{
            __block NSManagedObject *map = nil;
            beforeEach(^{
                NSEntityDescription *mapEntity = [[NSEntityDescription alloc] init];
                [mapEntity setName:@"Map"];
                [mapEntity setManagedObjectClassName:@"Map"];
                
                NSAttributeDescription *objectId = [[NSAttributeDescription alloc] init];
                [objectId setName:@"map_id"];
                [objectId setAttributeType:NSStringAttributeType];
                [objectId setOptional:YES];
                
                [mapEntity setProperties:[NSArray arrayWithObject:objectId]];
                
                map = [[NSManagedObject alloc] initWithEntity:mapEntity insertIntoManagedObjectContext:nil];
            });
            context(@"when the object does not have an id", ^{
                it(@"creates a new object id", ^{
                    [[map assignObjectId] shouldNotBeNil];
                    [[map valueForKey:@"map_id"] shouldNotBeNil];
                });
            });
        });
        context(@"given an object without an identifiable id attribute", ^{
            __block NSManagedObject *model = nil;
            beforeEach(^{
                NSEntityDescription *incompleteEntity = [[NSEntityDescription alloc] init];
                [incompleteEntity setName:@"Incomplete"];
                [incompleteEntity setManagedObjectClassName:@"Incomplete"];
                
                model = [[NSManagedObject alloc] initWithEntity:incompleteEntity insertIntoManagedObjectContext:nil];
            });
            it(@"fails loudly", ^{
                [[theBlock(^{
                    [model assignObjectId];
                }) should] raise];
            });
        });
        context(@"given an object which defines a custom id attribute", ^{
            __block StackMobSerializationSpecUser *user = nil;
            __block SMClient *client = nil;
            beforeEach(^{
                client = [[SMClient alloc] initWithAPIVersion:@"0" publicKey:@"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"];
                NSEntityDescription *userEntity = [[NSEntityDescription alloc] init];
                [userEntity setName:@"User"];
                [userEntity setManagedObjectClassName:@"StackMobSerializationSpecUser"];
                
                NSAttributeDescription *username = [[NSAttributeDescription alloc] init];
                [username setName:@"username"];
                [username setAttributeType:NSStringAttributeType];
                [username setOptional:NO];
                
                [userEntity setProperties:[NSArray arrayWithObjects:username, nil]];
                
                user = [[StackMobSerializationSpecUser alloc] initWithEntity:userEntity insertIntoManagedObjectContext:nil];
            });
            context(@"when the object does not have an id", ^{
                it(@"creates a new object id", ^{
                    [[user assignObjectId] shouldNotBeNil];
                });
            });
        });
    });
    
    context(@"given a complex object graph", ^{
        __block NSDate *now = nil;
        __block NSManagedObject *hooman = nil;
        __block NSManagedObject *iMadeYouACookie = nil;
        __block NSManagedObject *kittenPhoto = nil;
        __block NSManagedObject *cookieTag = nil;
        __block NSManagedObject *foodTag = nil;
        beforeEach(^{
            
            //        
            //             ========
            //     --------| User |
            //     |     1 ========
            //     |          |1
            //     |          |
            //     |          |* lolcats
            //     |      ==========
            //     |      | LolCat |
            //     |      ==========
            //     |        |1  |1
            //     |        |   |
            //     |    -----   -----
            //     |    |           |
            //     |    |1 photo    |* tags
            //     | =========    =======
            //     | | Photo |    | Tag |
            //     | =========    =======
            //     |    |1
            //     ------ photographer
            //        
            
            now = [NSDate date];
            
            NSEntityDescription *lolCatEntity = [[NSEntityDescription alloc] init];
            [lolCatEntity setName:@"LolCat"];
            [lolCatEntity setManagedObjectClassName:@"LolCat"];
            
            //users
            NSEntityDescription *userEntity = [[NSEntityDescription alloc] init];
            [userEntity setName:@"User"];
            [userEntity setManagedObjectClassName:@"User"];
            
            NSAttributeDescription *userId = [[NSAttributeDescription alloc] init];
            [userId setName:@"user_id"];
            [userId setAttributeType:NSStringAttributeType];
            [userId setOptional:YES];
            
            NSRelationshipDescription *lolcats = [[NSRelationshipDescription alloc] init];
            [lolcats setName:@"lolcats"];
            [lolcats setDestinationEntity:lolCatEntity];
            
            [userEntity setProperties:[NSArray arrayWithObjects:userId, lolcats, nil]];
            
            //photos
            NSEntityDescription *photoEntity = [[NSEntityDescription alloc] init];
            [photoEntity setName:@"Photo"];
            [photoEntity setManagedObjectClassName:@"Photo"];
            
            NSAttributeDescription *photoId = [[NSAttributeDescription alloc] init];
            [photoId setName:@"photo_id"];
            [photoId setAttributeType:NSStringAttributeType];
            [photoId setOptional:YES];
            
            NSAttributeDescription *photoURL = [[NSAttributeDescription alloc] init];
            [photoURL setName:@"url"];
            [photoURL setAttributeType:NSStringAttributeType];
            [photoURL setOptional:NO];
            
            NSRelationshipDescription *photographer = [[NSRelationshipDescription alloc] init];
            [photographer setName:@"photographer"];
            [photographer setDestinationEntity:userEntity];
            [photographer setMaxCount:1];
            
            [photoEntity setProperties:[NSArray arrayWithObjects:photoId, photoURL, photographer, nil]];
            
            //tags
            NSEntityDescription *tagEntity = [[NSEntityDescription alloc] init];
            [tagEntity setName:@"Tag"];
            [tagEntity setManagedObjectClassName:@"Tag"];
            
            NSAttributeDescription *tagId = [[NSAttributeDescription alloc] init];
            [tagId setName:@"tag_id"];
            [tagId setAttributeType:NSStringAttributeType];
            [tagId setOptional:YES];
            
            [tagEntity setProperties:[NSArray arrayWithObjects:tagId, nil]];
            
            //lolcats
            NSAttributeDescription *objectId = [[NSAttributeDescription alloc] init];
            [objectId setName:@"lolcat_id"];
            [objectId setAttributeType:NSStringAttributeType];
            [objectId setOptional:YES];
            
            NSAttributeDescription *name = [[NSAttributeDescription alloc] init];
            [name setName:@"name"];
            [name setAttributeType:NSStringAttributeType];
            [name setOptional:NO];
            [name setDefaultValue:@"CAT"];
            
            NSAttributeDescription *caption = [[NSAttributeDescription alloc] init];
            [caption setName:@"caption"];
            [caption setAttributeType:NSStringAttributeType];
            [caption setOptional:NO];
            
            NSAttributeDescription *subcaption = [[NSAttributeDescription alloc] init];
            [subcaption setName:@"subcaption"];
            [subcaption setAttributeType:NSStringAttributeType];
            [subcaption setOptional:YES];
            
            NSAttributeDescription *captionedAt = [[NSAttributeDescription alloc] init];
            [captionedAt setName:@"captionedAt"];
            [captionedAt setAttributeType:NSDateAttributeType];
            [captionedAt setOptional:NO];
            
            NSAttributeDescription *transient = [[NSAttributeDescription alloc] init];
            [transient setName:@"transient"];
            [transient setAttributeType:NSUndefinedAttributeType];
            [transient setOptional:YES];
            
            NSRelationshipDescription *photo = [[NSRelationshipDescription alloc] init];
            [photo setName:@"photo"];
            [photo setDestinationEntity:photoEntity];
            [photo setMaxCount:1];
            
            NSRelationshipDescription *owner = [[NSRelationshipDescription alloc] init];
            [owner setName:@"owner"];
            [owner setDestinationEntity:userEntity];
            [owner setMaxCount:1];
            
            NSRelationshipDescription *tags = [[NSRelationshipDescription alloc] init];
            [tags setName:@"tags"];
            [tags setDestinationEntity:tagEntity];
            
            [lolCatEntity setProperties:[NSArray arrayWithObjects:objectId, name, caption, subcaption, captionedAt, transient, photo, owner, tags, nil]];
            
            //construct the managed object model
            NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] init];
            
            [objectModel setEntities:[NSArray arrayWithObjects:photoEntity, lolCatEntity, nil]];
            
            hooman = [[NSManagedObject alloc] initWithEntity:userEntity insertIntoManagedObjectContext:nil];
            [hooman setValue:@"hooman" forKey:@"user_id"];
            iMadeYouACookie = [[NSManagedObject alloc] initWithEntity:lolCatEntity insertIntoManagedObjectContext:nil];
            kittenPhoto = [[NSManagedObject alloc] initWithEntity:photoEntity insertIntoManagedObjectContext:nil];
            cookieTag = [[NSManagedObject alloc] initWithEntity:tagEntity insertIntoManagedObjectContext:nil];
            [cookieTag setValue:[cookieTag assignObjectId] forKey:@"tag_id"];
            foodTag = [[NSManagedObject alloc] initWithEntity:tagEntity insertIntoManagedObjectContext:nil];
            [foodTag setValue:[foodTag assignObjectId] forKey:@"tag_id"];
            
            [kittenPhoto setValue:@"http://cutethings.example/kitten" forKey:@"url"];
            [kittenPhoto setValue:hooman forKey:@"photographer"];
            [kittenPhoto setValue:[kittenPhoto assignObjectId] forKey:@"photo_id"];
            
            [iMadeYouACookie setValue:kittenPhoto forKey:@"photo"];        
            [iMadeYouACookie setValue:@"I MADE YOU A COOKIE, BUT I EATED IT" forKey:@"caption"];
            [iMadeYouACookie setValue:now forKey:@"captionedAt"];
            [iMadeYouACookie setValue:[iMadeYouACookie assignObjectId] forKey:@"lolcat_id"];
            NSMutableSet *tagSet = [iMadeYouACookie mutableSetValueForKey:@"tags"];
            [tagSet addObject:cookieTag];
            [tagSet addObject:foodTag];
            
            NSMutableSet *lolcatsSet = [hooman mutableSetValueForKey:@"lolcats"];
            [lolcatsSet addObject:iMadeYouACookie];
        });
        
        describe(@"-SMDictionarySerialization:", ^{
            describe(@"properties", ^{
                __block NSDictionary *dictionary = nil;
                beforeEach(^{
                    dictionary = [[iMadeYouACookie SMDictionarySerialization] objectForKey:@"SerializedDict"];
                });
                /*
                it(@"includes nil properties", ^{
                    [[dictionary should] haveValue:[NSNull null] forKey:@"subcaption"];
                });
                 */
                it(@"assigns object ids", ^{
                    [[dictionary objectForKey:@"lolcat_id"] shouldNotBeNil];
                });
                it(@"does not include transient properties in the response", ^{
                    [[dictionary objectForKey:@"transient"] shouldBeNil];
                });        
            });
            describe(@"relationships", ^{
                __block NSDictionary *dictionary = nil;
                beforeEach(^{
                    dictionary = [[iMadeYouACookie SMDictionarySerialization] objectForKey:@"SerializedDict"];
                });
                /*
                it(@"includes nil relationships", ^{
                    [[[dictionary valueForKey:@"owner"] should] equal:[NSNull null]];
                });
                 */
                describe(@"circular relationships", ^{
                    it(@"survives circular references", ^{
                        [[[[[[hooman valueForKey:@"lolcats"] anyObject] valueForKey:@"photo"] valueForKey:@"photographer"] should] equal:hooman];
                        [[hooman SMDictionarySerialization] shouldNotBeNil];
                    });
                });
            });
        });
    });
    
});

describe(@"-userPrimaryKeyField", ^{
    __block NSEntityDescription *theEntity = nil;
    __block NSManagedObject *theObject = nil;
    context(@"With an entity that has a StackMob-like userPrimaryKeyField", ^{
        beforeEach(^{
            theEntity = [[NSEntityDescription alloc] init];
            [theEntity setName:@"Entity"];
            [theEntity setManagedObjectClassName:@"Entity"];
            
            NSAttributeDescription *entity_id = [[NSAttributeDescription alloc] init];
            [entity_id setName:@"entity_id"];
            [entity_id setAttributeType:NSStringAttributeType];
            
            NSAttributeDescription *name = [[NSAttributeDescription alloc] init];
            [name setName:@"name"];
            [name setAttributeType:NSStringAttributeType];
            
            [theEntity setProperties:[NSArray arrayWithObjects:entity_id, name, nil]];
            
            //construct the managed object model
            NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] init];
            
            [objectModel setEntities:[NSArray arrayWithObjects:theEntity, nil]];
            
            theObject = [[NSManagedObject alloc] initWithEntity:theEntity insertIntoManagedObjectContext:nil];
        });
        it(@"Should return entity_id for userPrimaryKeyField", ^{
            [[[theObject primaryKeyField] should] equal:@"entity_id"];
        });
    });
    context(@"With an entity that has a CoreData-like userPrimaryKeyField", ^{
        beforeEach(^{
            theEntity = [[NSEntityDescription alloc] init];
            [theEntity setName:@"Entity"];
            [theEntity setManagedObjectClassName:@"Entity"];
            
            NSAttributeDescription *entityId = [[NSAttributeDescription alloc] init];
            [entityId setName:@"entityId"];
            [entityId setAttributeType:NSStringAttributeType];
            
            NSAttributeDescription *name = [[NSAttributeDescription alloc] init];
            [name setName:@"name"];
            [name setAttributeType:NSStringAttributeType];
            
            [theEntity setProperties:[NSArray arrayWithObjects:entityId, name, nil]];
            
            //construct the managed object model
            NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] init];
            
            [objectModel setEntities:[NSArray arrayWithObjects:theEntity, nil]];
            
            theObject = [[NSManagedObject alloc] initWithEntity:theEntity insertIntoManagedObjectContext:nil];

        });
        it(@"Should return entityId for userPrimaryKeyField", ^{
            [[[theObject primaryKeyField] should] equal:@"entityId"];
        });
    });
    context(@"With an entity that adopts the SMModel protocol", ^{
        __block StackMobSerializationSpecUser *user = nil;
        __block SMClient *client = nil;
        beforeEach(^{
            client = [[SMClient alloc] initWithAPIVersion:@"0" publicKey:@"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"];
            NSEntityDescription *userEntity = [[NSEntityDescription alloc] init];
            [userEntity setName:@"User"];
            [userEntity setManagedObjectClassName:@"StackMobSerializationSpecUser"];
            
            NSAttributeDescription *username = [[NSAttributeDescription alloc] init];
            [username setName:@"username"];
            [username setAttributeType:NSStringAttributeType];
            [username setOptional:NO];
            
            [userEntity setProperties:[NSArray arrayWithObjects:username, nil]];
            
            user = [[StackMobSerializationSpecUser alloc] initWithEntity:userEntity insertIntoManagedObjectContext:nil];
        });
        it(@"Should return entityId for userPrimaryKeyField", ^{
            [[[user primaryKeyField] should] equal:@"username"];
        });
    });
    
});


SPEC_END
