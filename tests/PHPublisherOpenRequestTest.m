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

 PHPublisherOpenRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <SenTestingKit/SenTestingKit.h>
#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"

#define EXPECTED_HASH @"3L0xlrDOt02UrTDwMSnye05Awwk"
//#define EXPECTED_HASH @"sbiA9ROvCFEPANNFLbq3BK6m_dU-"

@interface PHPublisherOpenRequestTest : SenTestCase
@end

@implementation PHPublisherOpenRequestTest

- (void)testInstance
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";
    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:(NSString *)token secret:(NSString *)secret];
    NSString *requestURLString = [request.URL absoluteString];

    STAssertNotNil(requestURLString, @"Parameter string is nil?");
    STAssertFalse([requestURLString rangeOfString:@"token="].location == NSNotFound,
                  @"Token parameter not present!");
    STAssertFalse([requestURLString rangeOfString:@"nonce="].location == NSNotFound,
                  @"Nonce parameter not present!");
    STAssertFalse([requestURLString rangeOfString:@"sig4="].location == NSNotFound,
                  @"Secret parameter not present!");

    STAssertTrue([request respondsToSelector:@selector(send)], @"Send method not implemented!");
}

- (void)testRequestParameters
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:token secret:secret];

    NSDictionary *signedParameters  = [request signedParameters];
    NSString     *requestURLString  = [request.URL absoluteString];

//#define PH_USE_MAC_ADDRESS 1
#if PH_USE_MAC_ADDRESS == 1
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        NSString *mac   = [signedParameters valueForKey:@"mac"];
        STAssertNotNil(mac, @"MAC param is missing!");
        STAssertFalse([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param is missing: %@", requestURLString);
    }
#else
    NSString *mac   = [signedParameters valueForKey:@"mac"];
    STAssertNil(mac, @"MAC param is present!");
    STAssertTrue([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param exists when it shouldn't: %@", requestURLString);
#endif
}

- (void)testCustomUDID
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:token secret:secret];
    NSString *requestURLString = [request.URL absoluteString];

    STAssertNotNil(requestURLString, @"Parameter string is nil?");
    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none is set.");

    PHPublisherOpenRequest *request2 = [PHPublisherOpenRequest requestForApp:token secret:secret];
    request2.customUDID = @"CUSTOM_UDID";
    requestURLString = [request2.URL absoluteString];
    STAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                 @"Custom parameter missing when one is set.");
}

- (void)testTimeZoneParameter
{
    NSString *theTestToken  = @"PUBLISHER_TOKEN";
    NSString *theTestSecret = @"PUBLISHER_SECRET";
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:theTestToken secret:
                theTestSecret];

    STAssertNotNil([theRequest.additionalParameters objectForKey:@"tz"], @"Missed time zone!");
    STAssertTrue(0 < [[theRequest.URL absoluteString] rangeOfString:@"tz="].length, @"Missed time "
                "zone!");

    NSScanner *theTimeZoneScanner = [NSScanner scannerWithString:[theRequest.URL absoluteString]];

    STAssertTrue([theTimeZoneScanner scanUpToString:@"tz=" intoString:NULL], @"Missed time zone!");
    STAssertTrue([theTimeZoneScanner scanString:@"tz=" intoString:NULL], @"Missed time zone!");
    
    float theTimeOffset = 0;
    STAssertTrue([theTimeZoneScanner scanFloat:&theTimeOffset], @"Missed time zone!");
    
    STAssertTrue(- 11 <= theTimeOffset && theTimeOffset <= 14, @"Incorrect time zone offset");
}

@end
