//
//  WTAEchoViewController.m
//  WTALoadingManagerExample
//
//  Created by Alex Shafran on 3/18/14.
//  Copyright (c) 2014 WillowTree Apps, Inc. All rights reserved.
//

#import "WTAEchoViewController.h"
#import "WTALoadingManager.h"

@interface WTAEchoViewController () <WTALoadingProtocol>

@property (nonatomic, strong) UILabel *responseLabel;

@end

@implementation WTAEchoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.numberOfLines = 0;
    [self.view addSubview:label];
    self.responseLabel = label;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.loadingManager reloadContent];
}

#pragma mark - Loading Protocol

- (void)loadContentIgnoreCache:(BOOL)ignoreCache
             completionHandler:(void (^)(NSError *, id))completion
{
    NSURL *url = [NSURL URLWithString:@"http://scooterlabs.com/echo.json"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                  completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {

                                        completion(error, data);
                                  }];
    
    [task resume];
}

- (void)loadSuccess:(id)response completionHandler:(void (^)(BOOL))completionHandler
{
    NSError *error;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:response
                                                                 options:0
                                                                   error:&error];
    self.responseLabel.text = [responseDict description];
    
    BOOL success = error == nil;
    completionHandler(success);
}

@end
