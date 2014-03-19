WTALoadingManager
=================

A loading manager to help view controllers track and display loading state.

## Requirements

`WTALoadingManager` requires Xcode 5 and ARC, and supports iOS versions 7.0 and above.

## Architecture

#### WTALoadingManager
A default `WTALoadingManager` is available to any UIViewController as a property in a category. It is lazy loaded and retained, so there is no need to create one manually.

```
@interface UIViewController (WTALoadingManager)

@property (nonatomic, strong) WTALoadingManager *loadingManager;

@end
```

The `loadingManager` configures and presents loading UI based on its loading status. By default, it provides loading, failed, and empty views, but these can be assigned individually as well.

Requests to reload content should be sent from the view controller to the `loadingManager` via `-reloadContent`, or one of its sibling methods.

#### WTALoadingProtocol
A view controller must implement `WTALoadingProtocol` in order to communicate with the `loadingManager`. Two methods are required:
  * `-loadContentIgnoreCache:completionHandler:` This is the primary method for performing network requests, called by WTALoadingManager -reloadContent. Perform a standard network request and call `completion(error, response)` when finished so the loading manager can properly configure state. If `error != nil`, `-loadFailed` will be called, if implemented, and the failed view will be presented.
  * `loadSuccess:completionHandler:` Called upon a successful API response. Call `completion(BOOL)` when post-processing is complete to notify the loading manager of a success or fail. If `NO` is passed in the `completion` call, the failed view will be presented.

## Getting Started
First, conform to the `WTALoadingProtocol`:
```
#import "WTALoadingManager.h"
...
@interface WTAEchoViewController () <WTALoadingProtocol>
```

#### Initial Network Call
To make the first request, reload content when the view controller's view appears.
```
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.loadingManager reloadContent];
}
```
By default, `-reloadContent` will only force a reload when no content has been loaded (e.g. on the first run, or after a failed load). For other behaviors, use `-reloadContent:(BOOL)forceReload` and ``reloadContent:(BOOL)forceReload inBackground:(BOOL)background`.

#### Implement Protocol Methods
Now that the `loadingManager` is fired up, implement the required protocol methods.

```
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
```

```
- (void)loadSuccess:(id)response completionHandler:(void (^)(BOOL))completionHandler
{
    NSError *error;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:response
                                                                 options:0
                                                                   error:&error];
    self.responseLabel.text = [responseDict description];
    
    BOOL success = (error == nil);
    completionHandler(success);
}
```

And that's it! For more, see the [full demo project](https://github.com/willowtreeapps/WTALoadingManager/tree/master/Example).

## Use Cases

## Additional Functionality
