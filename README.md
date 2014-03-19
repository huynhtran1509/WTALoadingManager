WTALoadingManager
=================

A loading manager to help view controllers track and display loading state. `WTALoadingManager` formalizes all network operations in order to intelligently make network calls and present loading, failed, and empty views when necessary. 

`WTALoadingManager` evolved from `MTLoadingViewController`'s need to decouple the loading logic from a `UIViewController` subclass. Now, all the logic is contained in a separate object, meaning the loading manager can now be used in a `UITableViewController` or `UICollectionViewController` subclass.

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
A view controller must implement `WTALoadingProtocol` in order to communicate with the `loadingManager`. Of the many methods available, two methods are required:
  * `-loadContentIgnoreCache:completionHandler:` This is the primary method for performing network requests, called by `WTALoadingManager -reloadContent`. Perform a standard network request and call `completion(error, response)` when finished so the `loadingManager` can properly configure state. If `error != nil`, `-loadFailed` will be called on the view controller, and the failed view will be presented.
  * `loadSuccess:completionHandler:` Called upon a successful API response. Call `completion(BOOL)` when post-processing is complete to notify the loading manager of a success or fail. If `NO` is passed in the `completion` call, the failed view will be presented.

See the [self documenting header](https://github.com/willowtreeapps/WTALoadingManager/blob/master/Classes/WTALoadingManager.h) for full details.

## Getting Started
#### Conform to Protocol
First, conform to the `WTALoadingProtocol` in your UIViewController subclass:
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
By default, `-reloadContent` will only force a reload when no content has been loaded (e.g. on the first run, or after a failed load). For other behaviors, use `-reloadContent:(BOOL)forceReload` and `reloadContent:(BOOL)forceReload inBackground:(BOOL)background`.

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

#### Base View Controller
In larger projects, it can be useful to use a base `UIViewController` subclass to avoid duplicating logic. If this is the case, it is a good idea to put the loading logic there. 

```
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self conformsToProtocol:@protocol(WTALoadingProtocol)])
    {
        [self.loadingManager reloadContent];   
    }
}
```

This way, any sublcass of your base view controller that conforms to `WTALoadingProtocol` will automatically reload when needed.

#### Manual Reloads
If your view controller needs to make one-off requests that differ from your `loadContentIgnoreCache:completionHandler` implementation, you can manually configure the loading/failed view by changing the `loadingStatus` on the `loadingManager`. For example, this will change the `loadingStatus` to "loading" and show the loading view:
```
[self.loadingManager setLoadingStatus:WTALoadingStatusLoading];
```
Since this is decoupled from the `loadingManager`'s`-reloadContent` logic, you will also need to dismiss the loading view.

This manual method can also be used to cancel a request, which is useful when valid content has been obtained elsewhere and loading new content is no longer necessary (e.g. an async fetch request completes before the network request).

## Additional Functionality

#### Async Operations and Core Data
All asynchronous post-processing tasks should be done inside the `loadSuccess:completionHandler:` protocol method. Since this method accepts a completion block as a parameter (rather than returning a BOOL), it allows the view controller to dispatch to background threads and call `completion(BOOL)` only when the background task(s) have completed. If you the completion block before any async response processing, the loading manager will dismiss immediately and there will likely be a delay before your content is actually loaded. For example:
```

- (void)loadSuccess:(id)response completionHandler:(void (^)(BOOL))completionHandler
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

        [WTAArticle MR_importFromArray:response inContext:localContext];
        
    } completion:^(BOOL success, NSError *error) {
        
        // call completion here
        completionHandler(success);
    }];
    
    // do NOT call completion here
    completionHandler(YES);
}
```
