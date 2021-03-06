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

 IDViewController.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 12/17/12.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "IDViewController.h"
#import <AdSupport/AdSupport.h>
#import "PlayHavenSDK.h"
#import "PHNetworkUtil.h"

@interface IDViewController ()
@end

@implementation IDViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.IFALabel.text  = [[[NSClassFromString(@"ASIdentifierManager") sharedManager] advertisingIdentifier] UUIDString];

    CFDataRef macBytes   = [[PHNetworkUtil sharedInstance] newMACBytes];

    if (NULL != macBytes)
    {
        self.MACLabel.text   = [[PHNetworkUtil sharedInstance] stringForMACBytes:macBytes];

        CFRelease(macBytes);
    }

    self.PHIDLabel.text = [PHAPIRequest session];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_IFALabel release];
    [_MACLabel release];
    [_PHIDLabel release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setIFALabel:nil];
    [self setMACLabel:nil];
    [self setPHIDLabel:nil];
    [super viewDidUnload];
}
@end
