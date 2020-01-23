/*   Copyright 2019 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "ANAdFetcherBase+PrivateMethods.h"
#import "ANNativeAdResponse.h"
#import "ANAdFetcherResponse.h"
#import "ANAdProtocol.h"
#import "ANGlobal.h"



@interface ANNativeAdFetcher : ANAdFetcherBase

-(nonnull instancetype) initWithDelegate:(nonnull id)delegate;
-(nonnull instancetype) initWithDelegate:(nonnull id)delegate andAdunitMultiAdRequestManager:(nonnull ANMultiAdRequest *)adunitMARManager;

@end




#pragma mark - ANUniversalAdFetcherDelegate partitions.

@protocol ANNativeAdFetcherDelegate <ANAdProtocolFoundation>

@property (nonatomic, readwrite, strong, nullable)  NSMutableDictionary<NSString *, NSArray<NSString *> *>  *customKeywords;

- (void)didFinishRequestWithResponse: (nonnull ANAdFetcherResponse *)response;

- (nonnull NSString *)internalGetUTRequestUUIDString;
- (void)internalUTRequestUUIDStringReset;

@end
