//
//  FINDataManager.h
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Backendless.h"
#import "FINSignal.h"
#import "FINComment.h"
#import "FINError.h"

#define BCKNDLSS_APP_ID         @"BDCD56B9-351A-E067-FFA4-9EA9CF2F4000"
#define BCKNDLSS_IOS_API_KEY    @"9F8B017B-2890-A887-FFD5-63D6A5302100"
#define BCKNDLSS_REST_API_KEY   @"473D7C4A-3FBC-69F4-FFFF-1635F07E4300"

#define kNotificationSignalID   @"NotificationSignalID"
#define kDefaultMapRegion       4000

@protocol FINSignalsMapDelegate <NSObject>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;

@end

@interface FINDataManager : NSObject

+ (id)sharedManager;

- (void)getSignalsForNewLocation:(CLLocation *)location withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getSignalsForLocation:(CLLocation *)location withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)submitNewSignalWithTitle:(NSString *)title forLocation:(CLLocationCoordinate2D)locationCoordinate withPhoto:(UIImage *)photo completion:(void (^)(FINSignal *savedSignal, FINError *error))completion;
- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal completion:(void (^)(FINError *error))completion;
- (void)getSignalWithID:(NSString *)signalID completion:(void (^)(FINSignal *signal, FINError *error))completion;
- (BOOL)userIsLogged;
- (NSString *)getUserName;
- (NSString *)getUserEmail;
- (void)registerUser:(NSString *)name withEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion;
- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion;
- (void)logoutWithCompletion:(void (^)(FINError *error))completion;
- (void)getCommentsForSignal:(FINSignal *)signal completion:(void (^)(NSArray *comments, FINError *error))completion;
- (void)saveComment:(NSString *)commentText forSigna:(FINSignal *)signal completion:(void (^)(FINComment *comment, FINError *error))completion;

+ (NSInteger)getNewStatusCodeFromStatusChangedComment:(NSString *)commentText;

@property (weak, nonatomic) id<FINSignalsMapDelegate> mapDelegate;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

@end
