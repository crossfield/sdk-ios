/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2013 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHPublisherContentRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <SenTestingKit/SenTestingKit.h>

#import "SBJsonParser.h"
#import "PHContent.h"
#import "PHContentView.h"
#import "PHPublisherContentRequest.h"
#import "PHStringUtil.h"
#import "PHPublisherContentRequest+Private.h"

#define PUBLISHER_TOKEN @"PUBLISHER_TOKEN"
#define PUBLISHER_SECRET @"PUBLISHER_SECRET"

static NSString *kPHApplicationTestToken  = @"TEST_TOKEN";
static NSString *kPHApplicationTestSecret = @"TEST_SECRET";
static NSString *kPHTestPlacement = @"test_placement";
static NSString *kPHTestContentID = @"test_content_id";
static NSString *const kPHTestMessageID = @"87345";

@interface PHPublisherContentRequest (TestMethods)
@property (nonatomic, readonly) PHPublisherContentRequestState state;
- (BOOL)setPublisherContentRequestState:(PHPublisherContentRequestState)state;
- (void)requestRewards:(NSDictionary *)queryParameters callback:(NSString *)callback source:(PHContentView *)source;

- (void)requestPurchases:(NSDictionary *)queryParameters callback:(NSString *)callback source:(PHContentView *)source;
@end

@interface PHContentTest : SenTestCase @end
@interface PHContentViewTest : SenTestCase @end
@interface PHContentViewRedirectTest : SenTestCase {
    PHContent *_content;
    PHContentView *_contentView;
    BOOL _didDismiss, _didLaunch;
}
@end

@interface PHContentViewRedirectRecyclingTest : SenTestCase {
    BOOL _shouldExpectParameter;
}
@end

@interface PHPublisherContentRequestTest : SenTestCase @end
@interface PHPublisherContentRewardsTest : SenTestCase @end
@interface PHPublisherContentPurchasesTest : SenTestCase @end
@interface PHPublisherContentRequestPreservationTest : SenTestCase @end
@interface PHPublisherContentPreloadTest : SenTestCase {
    PHPublisherContentRequest *_request;
    BOOL _didPreload;
}
@end

@interface PHPublisherContentPreloadParameterTest : SenTestCase @end
@interface PHPublisherContentStateTest : SenTestCase @end

@interface PHPublisherContentRequestMock : PHPublisherContentRequest
@end

@implementation PHPublisherContentRequestMock
+ (NSDictionary *)identifiers
{
    return @{@"ifa" : @"345678KLFL8768HJK"};
}
@end

@implementation PHContentTest

- (void)testContent
{
    NSString
        *empty   = @"{}",
        *keyword = @"{\"frame\":\"PH_FULLSCREEN\",\"url\":\"http://google.com\",\"transition\":\"PH_MODAL\",\"context\":{\"awesome\":\"awesome\"}}",
        *rect    = @"{\"frame\":{\"PH_LANDSCAPE\":{\"x\":60,\"y\":40,\"w\":200,\"h\":400},\"PH_PORTRAIT\":{\"x\":40,\"y\":60,\"w\":240,\"h\":340}},\"url\":\"http://google.com\",\"transition\":\"PH_DIALOG\",\"context\":{\"awesome\":\"awesome\"}}";

  PH_SBJSONPARSER_CLASS *parser = [[PH_SBJSONPARSER_CLASS alloc] init];
    NSDictionary
        *emptyDict   = [parser objectWithString:empty],
        *keywordDict = [parser objectWithString:keyword],
        *rectDict    = [parser objectWithString:rect];

    [parser release];

    PHContent *emptyUnit = [PHContent contentWithDictionary:emptyDict];
    STAssertNil(emptyUnit, @"Empty definition should result in nil!");

    PHContent *keywordUnit = [PHContent contentWithDictionary:keywordDict];
    STAssertNotNil(keywordUnit, @"Keyword definition should result in unit!");

    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect theExpectedFrame = CGRectZero;
    theExpectedFrame.size = applicationFrame.size;
    STAssertTrue(CGRectEqualToRect([keywordUnit frameForOrientation:UIInterfaceOrientationPortrait], theExpectedFrame),
                 @"Frame mismatch from keyword. Got %@", NSStringFromCGRect(theExpectedFrame));

    NSURL *adURL = [NSURL URLWithString:@"http://google.com"];
    STAssertTrue([keywordUnit.URL isEqual:adURL],
                 @"URL mismatch. Expected %@ got %@", adURL, keywordUnit.URL);

    STAssertTrue(keywordUnit.transition == PHContentTransitionModal,
                 @"Transition type mismatched. Expected %d got %d", PHContentTransitionModal, keywordUnit.transition);

    STAssertNotNil([keywordUnit.context valueForKey:@"awesome"],
                   @"Expected payload key not found!");

    PHContent *rectUnit = [PHContent contentWithDictionary:rectDict];
    STAssertNotNil(rectUnit, @"Keyword definition should result in unit!");

    CGRect expectedLandscapeFrame = CGRectMake(60,40,200,400);
    STAssertTrue(CGRectEqualToRect([rectUnit frameForOrientation:UIInterfaceOrientationLandscapeLeft], expectedLandscapeFrame),
                 @"Frame mismatch from keyword. Got %@", NSStringFromCGRect([rectUnit frameForOrientation:UIInterfaceOrientationLandscapeLeft]));

}

- (void)testCloseButtonDelayParameter
{
  PHContent *content = [[PHContent alloc] init];
  STAssertTrue(content.closeButtonDelay == 10.0f, @"Default closeButton delay value incorrect!");
  [content release];

  NSString *rect = @"{\"frame\":{\"x\":60,\"y\":40,\"w\":200,\"h\":400},\"url\":\"http://google.com\",\"transition\":\"PH_DIALOG\",\"context\":{\"awesome\":\"awesome\"},\"close_delay\":23}";

  PH_SBJSONPARSER_CLASS *parser = [[PH_SBJSONPARSER_CLASS alloc] init];
  NSDictionary *rectDict = [parser objectWithString:rect];
  [parser release];

  PHContent *rectUnit = [PHContent contentWithDictionary:rectDict];
  STAssertTrue(rectUnit.closeButtonDelay == 23.0f, @"Expected 23 got %f", content.closeButtonDelay);
}

- (void)testCloseButtonUrlParameter
{
  PHContent *content = [[PHContent alloc] init];
  STAssertTrue(content.closeButtonURLPath == nil, @"CloseButtonURLPath property not available");
  [content release];

  NSString *rect = @"{\"frame\":{\"x\":60,\"y\":40,\"w\":200,\"h\":400},\"url\":\"http://google.com\",\"transition\":\"PH_DIALOG\",\"context\":{\"awesome\":\"awesome\"},\"close_ping\":\"http://playhaven.com\"}";

  PH_SBJSONPARSER_CLASS *parser = [[PH_SBJSONPARSER_CLASS alloc] init];
  NSDictionary *rectDict = [parser objectWithString:rect];
  [parser release];

  PHContent *rectUnit = [PHContent contentWithDictionary:rectDict];
  STAssertTrue([rectUnit.closeButtonURLPath isEqualToString:@"http://playhaven.com"], @"Expected 'http://playhaven.com got %@", content.closeButtonURLPath);
}
@end

@implementation PHContentViewTest

- (void)testcontentView
{
    PHContent *content = [[PHContent alloc] init];

    PHContentView *contentView = [[PHContentView alloc] initWithContent:content];
    STAssertTrue([contentView respondsToSelector:@selector(show:)], @"Should respond to show selector");
    STAssertTrue([contentView respondsToSelector:@selector(dismiss:)], @"Should respond to dismiss selector");
    [contentView release];
    [content release];
}
@end

@implementation PHContentViewRedirectTest

- (void)setUp
{
    _content = [[PHContent alloc] init];

    _contentView = [[PHContentView alloc] initWithContent:_content];
    [_contentView redirectRequest:@"ph://dismiss" toTarget:self action:@selector(dismissRequestCallback:)];
    [_contentView redirectRequest:@"ph://launch" toTarget:self action:@selector(launchRequestCallback:)];
}

- (void)testRegularRequest
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
    STAssertTrue(result, @"_contentView should open http://google.com in webview!");
}

- (void)testDismissRequest
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://dismiss"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
    STAssertFalse(result, @"_contentView should not open ph://dismiss in webview!");
}

- (void)dismissRequestCallback:(NSDictionary *)parameters
{
    STAssertNil(parameters, @"request with no parameters returned parameters!");
}

- (void)testLaunchRequest
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://launch?context=%7B%22url%22%3A%22http%3A%2F%2Fadidas.com%22%7D"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
    STAssertFalse(result, @"_contentView should not open ph://dismiss in webview!");
}

- (void)launchRequestCallback:(NSDictionary *)parameters
{
    STAssertNotNil(parameters, @"request with parameters returned no parameters!");
    STAssertTrue([@"http://adidas.com" isEqualToString:[parameters valueForKey:@"url"]],
                 @"Expected 'http://adidas.com' got %@ as %@",
                 [parameters valueForKey:@"url"], [[parameters valueForKey:@"url"] class]);

}

- (void)dealloc
{
    [_content release], _content = nil;
    [_contentView release], _contentView = nil;
    [super dealloc];
}
@end

@implementation PHContentViewRedirectRecyclingTest
- (void)testRedirectRecycling
{
    PHContent     *content     = [[PHContent alloc] init];
    PHContentView *contentView = [[PHContentView alloc] initWithContent:content];
    [content release];

    [contentView redirectRequest:@"ph://test" toTarget:self action:@selector(handleTest:)];

    NSURLRequest *request  =
            [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://test?context=%7B%22url%22%3A%22http%3A%2F%2Fadidas.com%22%7D"]];
    _shouldExpectParameter = YES;
    STAssertFalse([contentView webView:nil
            shouldStartLoadWithRequest:request
                        navigationType:UIWebViewNavigationTypeLinkClicked], @"Didn't redirect to dispatch handler");

    // NOTE: This rest ensures that invocation objects are being properly recycled.
    NSURLRequest *nextRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://test"]];
    _shouldExpectParameter = NO;
    STAssertFalse([contentView webView:nil
            shouldStartLoadWithRequest:nextRequest
                        navigationType:UIWebViewNavigationTypeLinkClicked], @"Didn't redirect next request to dispatch handler");
}

- (void)handleTest:(NSDictionary *)parameters
{
    NSString *url = [parameters valueForKey:@"url"];
    if (_shouldExpectParameter) {
        STAssertNotNil(url, @"Expected parameter was not present");
    } else  {
        STAssertNil(url, @"Expected nil returned a value");
    }
}
@end

@implementation PHPublisherContentRequestTest

- (void)testAnimatedParameter
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:PUBLISHER_TOKEN
                                                                           secret:PUBLISHER_SECRET];
    STAssertTrue(request.animated, @"Default state of animated property should be TRUE");

    request.animated = NO;
    STAssertFalse(request.animated, @"Animated property not set!");
}

- (void)testRequestParametersCase1
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:PUBLISHER_TOKEN
                                                                           secret:PUBLISHER_SECRET];
    request.placement = @"placement_id";

    NSDictionary *dictionary = [request signedParameters];
    STAssertNotNil([dictionary valueForKey:@"placement_id"], @"Expected 'placement_id' parameter.");

    NSString *parameterString = [request signedParameterString];
    NSString *placementParam  = @"placement_id=placement_id";
    STAssertFalse([parameterString rangeOfString:placementParam].location == NSNotFound,
                  @"Placment_id parameter not present!");

    NSDictionary *signedParameters  = [request signedParameters];
    NSString     *requestURLString  = [request.URL absoluteString];

#if PH_USE_MAC_ADDRESS == 1
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        NSString *mac   = [signedParameters valueForKey:@"mac"];
        STAssertNotNil(mac, @"MAC param is missing!");
        STAssertFalse([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param is missing!");
    }
#else
    NSString *mac   = [signedParameters valueForKey:@"mac"];
    STAssertNil(mac, @"MAC param is present!");
    STAssertTrue([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param exists when it shouldn't.");
#endif
}

- (void)testRequestParametersCase2
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                                   placement:kPHTestPlacement
                                                    delegate:nil];

    STAssertEqualObjects(theTestRequest.placement, kPHTestPlacement, @"The request's placement "
            "doesn't mach the one passed in the initializer");
    STAssertNil(theTestRequest.delegate, @"");

    NSNumber *theSessionDuration = [theTestRequest.additionalParameters objectForKey:@"stime"];
    STAssertNotNil(theSessionDuration, @"Missed mandatory parameter!");
    STAssertTrue(0 <= [theSessionDuration intValue], @"Incorrect session duration value");

    NSNumber *theRequestPreloaded = [theTestRequest.additionalParameters objectForKey:@"preload"];
    STAssertNotNil(theRequestPreloaded, @"Missed mandatory parameter!");
    STAssertFalse([theSessionDuration boolValue], @"Request is not preloaded");

    NSNumber *theIsaParameter = [theTestRequest.additionalParameters objectForKey:@"isa"];
    STAssertNotNil(theIsaParameter, @"Missed mandatory parameter!");

    NSString *thePlacementParameter =
                     [theTestRequest.additionalParameters objectForKey:@"placement_id"];

    STAssertEqualObjects(thePlacementParameter, kPHTestPlacement, @"Missed mandatory parameter!");

    NSString *theContentIDParameter =
                     [theTestRequest.additionalParameters objectForKey:@"content_id"];

    STAssertEqualObjects(theContentIDParameter, @"", @"Missed mandatory parameter!");

    NSString *theRequestQuery = [theTestRequest.URL query];

    STAssertTrue((0 < [theRequestQuery rangeOfString:
                              [NSString stringWithFormat:@"stime=%@", theSessionDuration]].length), @"");

    STAssertTrue((0 < [theRequestQuery rangeOfString:@"preload=0"].length), @"");

    STAssertTrue((0 < [theRequestQuery rangeOfString:@"isa="].length), @"");

    STAssertTrue((0 < [theRequestQuery rangeOfString:@"placement_id=test_placement"].length), @"");

    STAssertTrue((0 < [theRequestQuery rangeOfString:@"placement_id=test_placement"].length), @"");

    STAssertTrue((0 < [theRequestQuery rangeOfString:@"content_id="].length), @"");
}

- (void)testRequestParametersCase3
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                               contentUnitID:kPHTestContentID
                                                   messageID:kPHTestMessageID];

    NSString *thePlacementParameter =
                     [theTestRequest.additionalParameters objectForKey:@"placement_id"];

    STAssertEqualObjects(thePlacementParameter, @"", @"Missed mandatory parameter!");

    NSString *theRequestQuery = [theTestRequest.URL query];

    STAssertTrue((0 < [theRequestQuery rangeOfString:@"placement_id="].length), @"");

    STAssertTrue((0 < [theRequestQuery rangeOfString:
                            [NSString stringWithFormat:@"content_id=%@", kPHTestContentID]].length), @"");
}

- (void)testMessageIDPropertyCase1
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                               contentUnitID:kPHTestContentID
                                                   messageID:kPHTestMessageID];

    STAssertNotNil(theTestRequest, @"Cannot created test request");
    
    NSString *theMessageIDParameter = [theTestRequest.additionalParameters objectForKey:
                @"message_id"];

    STAssertEqualObjects(theMessageIDParameter, kPHTestMessageID, @"Missed message_id parameter!");

    NSString *theRequestQuery = [theTestRequest.URL query];

    STAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"message_id=%@",
                kPHTestMessageID]].length), @"");
    
    // Cancel the request to remove it from the cache
    [theTestRequest cancel];
}

- (void)testMessageIDPropertyCase2
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                                   placement:kPHTestPlacement
                                                    delegate:nil];

    STAssertNotNil(theTestRequest, @"Cannot created test request");
    
    NSString *theMessageIDParameter = [theTestRequest.additionalParameters objectForKey:
                @"message_id"];

    STAssertNil(theMessageIDParameter, @"message_id parameter should not be specified for content"
                " requests which are created with placement");

    NSString *theRequestQuery = [theTestRequest.URL query];

    STAssertTrue(0 == [theRequestQuery rangeOfString:@"message_id="].length, @"");
    
    // Cancel the request to remove it from the cache
    [theTestRequest cancel];
}

@end

@implementation PHPublisherContentRewardsTest

- (void)testValidation
{
    NSString *reward    = @"SLAPPY_COINS";
    NSNumber *quantity  = [NSNumber numberWithInt:1234];
    NSNumber *receipt   = [NSNumber numberWithInt:102930193];

    NSDictionary *theValidReward =
    @{
                @"reward" : reward,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"7UWbhP-nQtfKi1AEFVz7FlwTDHE",
                @"id" : @"ifa"
    };
    
    NSDictionary *theRewardWithBadSignature =
    @{
                @"reward" : reward,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"BAD_SIGNATURE_RARARA",
                @"id" : @"ifa"
    };
    
    NSDictionary *theIncompleteReward =
    @{
                @"reward" : reward,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"BAD_SIGNATURE_RARARA",
    };

    PHPublisherContentRequest *request = [PHPublisherContentRequestMock requestForApp:
                PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    STAssertTrue([request isValidReward:theValidReward], @"PHPublisherContentRequest could not "
                "validate valid reward.");
    STAssertFalse([request isValidReward:theRewardWithBadSignature], @"PHPublisherContentRequest "
                "validated invalid reward.");
    STAssertFalse([request isValidReward:theIncompleteReward], @"PHPublisherContentRequest "
                "validated invalid reward.");
}
@end

@implementation PHPublisherContentPurchasesTest

- (void)testValidation
{
    NSString *product   = @"com.playhaven.example.candy";
    NSString *name      = @"Delicious Candy";
    NSNumber *quantity  = [NSNumber numberWithInt:1234];
    NSNumber *receipt   = [NSNumber numberWithInt:102930193];
    NSNumber *cookie    = [NSNumber numberWithInt:3423413];

    NSDictionary *thePurchase =
    @{
                @"product" : product,
                @"name" : name,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"vBxtaXGoO8TZY-vWj0O7VCxaL70",
                @"cookie" : cookie,
                @"id" : @"ifa"
    };

    NSDictionary *theInvalidPurchase =
    @{
                @"product" : product,
                @"name" : name,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"vBxtaXGoO8TZY-vWj0O7VCxaL70",
                @"cookie" : cookie,
    };

    NSDictionary *thePurchasesDictionary = @{@"purchases" : @[thePurchase]};

    PHPublisherContentRequest *request = [PHPublisherContentRequestMock requestForApp:
                PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    STAssertTrue([request isValidPurchase:thePurchase], @"PHPublisherContentRequest could not "
                "validate valid purchase");
    STAssertFalse([request isValidPurchase:theInvalidPurchase], @"PHPublisherContentRequest "
                "validated invalid purchase with missed id field");
    STAssertNoThrow([request requestPurchases:thePurchasesDictionary callback:nil source:nil],
                @"Problem processing valid purchases array");
}

- (void)testAlternateValidation
{
    NSString *product   = @"com.playhaven.example.candy";
    NSString *name      = @"Delicious Candy";
    NSNumber *quantity  = [NSNumber numberWithInt:1234];
    NSString *receipt   = @"102930193";
    NSString *cookie    = @"3423413";

    NSDictionary *thePurchase =
    @{
                @"product" : product,
                @"name" : name,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"vBxtaXGoO8TZY-vWj0O7VCxaL70",
                @"cookie" : cookie,
                @"id" : @"ifa"
    };

    NSDictionary *thePurchasesDictionary = @{@"purchases" : @[thePurchase]};

    PHPublisherContentRequest *request = [PHPublisherContentRequestMock requestForApp:
                PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    STAssertTrue([request isValidPurchase:thePurchase], @"PHPublisherContentRequest could not "
                "validate valid purchase");
    STAssertNoThrow([request requestPurchases:thePurchasesDictionary callback:nil source:nil],
                @"Problem processing valid purchases array");
}

@end

@implementation PHPublisherContentRequestPreservationTest

- (void)testPreservation
{
    PHPublisherContentRequest *request                   =
          [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement1" delegate:nil];
    PHPublisherContentRequest *requestIdentical          =
          [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement1" delegate:nil];
    PHPublisherContentRequest *requestDifferentToken     =
          [PHPublisherContentRequest requestForApp:@"token2" secret:@"secret2" placement:@"placement1" delegate:nil];
    PHPublisherContentRequest *requestDifferentPlacement =
          [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement2" delegate:nil];


    STAssertTrue(request == requestIdentical, @"These requests should be the same instance!");
    STAssertTrue(request != requestDifferentPlacement, @"These requests should be different!");
    STAssertTrue(request != requestDifferentToken, @"These requests should be different!");

    NSString *newDelegate = @"DELEGATE";
    PHPublisherContentRequest *requestNewDelegate = [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement1" delegate:newDelegate];

    STAssertTrue((id)requestNewDelegate.delegate == (id)newDelegate, @"This request should have had its delegate reassigned!");
}
@end

@implementation PHPublisherContentPreloadTest

- (void)setUp
{
    _request = [[PHPublisherContentRequest requestForApp:@"zombie1"
                                                  secret:@"haven1"
                                               placement:@"more_games"
                                                delegate:self] retain];
    _didPreload = NO;
}

- (void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    _didPreload = YES;
}

- (void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content
{
    STAssertTrue(FALSE, @"This isn't supposed to happen!");
}

- (void)tearDown
{
    STAssertTrue(_didPreload, @"Preloading didn't happen!");
    STAssertTrue([_request state] == PHPublisherContentRequestPreloaded,@"Request wasn't preloaded!");

    [_request release], _request = nil;
}
@end

@implementation PHPublisherContentPreloadParameterTest

- (void)testPreloadParameterWhenPreloading
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                        placement:@"more_games"
                                                                         delegate:nil];
    [request preload];

    NSString *parameters = [request.URL absoluteString];
    STAssertFalse([parameters rangeOfString:@"preload=1"].location == NSNotFound, @"Expected 'preload=1' in parameter string, did not find it!");
    [request cancel];
}

- (void)testPreloadParameterWhenSending
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                        placement:@"more_games"
                                                                         delegate:nil];
    [request send];

    NSString *parameters = [request.URL absoluteString];
    STAssertFalse([parameters rangeOfString:@"preload=0"].location == NSNotFound, @"Expected 'preload=0' in parameter string, did not find it!");
    [request cancel];
}
@end

@implementation PHPublisherContentStateTest

- (void)testStateChanges
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                        placement:@"more_games"
                                                                         delegate:nil];

    STAssertTrue(request.state == PHPublisherContentRequestInitialized, @"Expected initialized state, got %d", request.state);
    STAssertTrue([request setPublisherContentRequestState:PHPublisherContentRequestPreloaded], @"Expected to be able to advance state!");
    STAssertFalse([request setPublisherContentRequestState:PHPublisherContentRequestPreloading], @"Expected not to be able to regress state!");

    [request cancel];
}
@end
