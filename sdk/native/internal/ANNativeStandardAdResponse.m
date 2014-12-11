/*   Copyright 2014 APPNEXUS INC
 
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

#import "ANNativeStandardAdResponse.h"
#import "ANGlobal.h"
#import "ANLogging.h"
#import "ANBrowserViewController.h"
#import "ANNativeAdResponse+PrivateMethods.h"
#import "NSTimer+ANCategory.h"
#import "UIView+ANCategory.h"

@interface ANNativeStandardAdResponse()

@property (nonatomic, readwrite, strong) NSDate *dateCreated;
@property (nonatomic, readwrite, assign) ANNativeAdNetworkCode networkCode;
@property (nonatomic, readwrite, assign, getter=hasExpired) BOOL expired;
@property (nonatomic, readwrite, strong) ANBrowserViewController *inAppBrowser;

@property (nonatomic, readwrite, assign) NSUInteger viewabilityValue;
@property (nonatomic, readwrite, assign) NSUInteger targetViewabilityValue;
@property (nonatomic, readwrite, strong) NSTimer *viewabilityTimer;
@property (nonatomic, readwrite, assign) BOOL impressionHasBeenTracked;

@end

@implementation ANNativeStandardAdResponse

@synthesize title = _title;
@synthesize body = _body;
@synthesize callToAction = _callToAction;
@synthesize rating = _rating;
@synthesize mainImage = _mainImage;
@synthesize mainImageURL = _mainImageURL;
@synthesize iconImage = _iconImage;
@synthesize iconImageURL = _iconImageURL;
@synthesize socialContext = _socialContext;
@synthesize customElements = _customElements;
@synthesize networkCode = _networkCode;
@synthesize expired = _expired;

- (instancetype)init {
    if (self = [super init]) {
        _networkCode = ANNativeAdNetworkCodeAppNexus;
        _dateCreated = [NSDate date];
    }
    return self;
}

#pragma mark - Registration

- (BOOL)registerResponseInstanceWithNativeView:(UIView *)view
                            rootViewController:(UIViewController *)controller
                                clickableViews:(NSArray *)clickableViews
                                         error:(NSError *__autoreleasing *)error {
    [self setupViewabilityTracker];
    [self attachGestureRecognizersToNativeView:view
                            withClickableViews:clickableViews];
    return YES;
}

#pragma mark - Impression Tracking

- (void)setupViewabilityTracker {
    __weak ANNativeStandardAdResponse *weakSelf = self;
    NSInteger requiredAmountOfSimultaneousViewableEvents = lround(kAppNexusNativeAdIABShouldBeViewableForTrackingDuration
                                                                  / kAppNexusNativeAdCheckViewabilityForTrackingFrequency) + 1;
    self.targetViewabilityValue = lround(pow(2, requiredAmountOfSimultaneousViewableEvents) - 1);
    self.viewabilityTimer = [NSTimer scheduledTimerWithTimeInterval:kAppNexusNativeAdCheckViewabilityForTrackingFrequency
                                                              block:^ {
                                                                  ANNativeStandardAdResponse *strongSelf = weakSelf;
                                                                  [strongSelf checkViewability];
                                                              }
                                                            repeats:YES];
}

- (void)checkViewability {
    self.viewabilityValue = (self.viewabilityValue << 1 | [self.viewForTracking an_isViewable]) & self.targetViewabilityValue;
    if (self.viewabilityValue == self.targetViewabilityValue) {
        [self trackImpression];
    }
}

- (void)trackImpression {
    ANLogDebug(@"Tracking impression!");
    if (!self.impressionHasBeenTracked) {
        [self fireImpTrackers];
        [self.viewabilityTimer invalidate];
        self.impressionHasBeenTracked = YES;
    }
}

- (void)fireImpTrackers {
    [self fireTrackersInArray:self.impTrackers];
}

#pragma mark - Unregistration

- (void)unregisterViewFromTracking {
    [super unregisterViewFromTracking];
    [self.viewabilityTimer invalidate];
}

#pragma mark - Click handling

- (void)handleClick {
    [self adWasClicked];
    [self fireClickTrackers];
    [self willLeaveApplication];
    [self openNativeBrowserWithURL:self.clickURL];
    // TODO: Implement in-app browser stuff
}

- (void)openNativeBrowserWithURL:(NSURL *)URL {
    [[UIApplication sharedApplication] openURL:URL];
}

- (void)fireClickTrackers {
    [self fireTrackersInArray:self.clickTrackers];
}

#pragma mark - Helper

- (void)fireTrackersInArray:(NSArray *)trackerArray {
    for (NSString *URLString in trackerArray) {
        ANLogDebug(@"Firing tracker with URL %@", URLString);
        NSURLRequest *request = [[self class] basicRequestForURL:[NSURL URLWithString:URLString]];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:nil];
    }
}

+ (NSURLRequest *)basicRequestForURL:(NSURL *)URL {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:kAppNexusRequestTimeoutInterval];
    [request setValue:ANUserAgent() forHTTPHeaderField:@"User-Agent"];
    return request;
}

- (void)dealloc {
    [self.viewabilityTimer invalidate];
}

@end