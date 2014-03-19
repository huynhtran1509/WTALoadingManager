WTALoadingManager
=================

A loading manager to handle the boilerplate logic for showing and hiding loading views and handling network operations.

## Requirements

`WTALoadingManager` requires Xcode 5, targeting iOS 7.0 and above.

## Architecture

### WTALoadingManager
A default `loadingManager` is available to any UIViewController as a property in a category. It is lazy loaded and retained, so there is no need to create one manually.

```
@interface UIViewController (WTALoadingManager)

@property (nonatomic, strong) WTALoadingManager *loadingManager;

@end
```

The `loadingManager` configures and presents loading UI based on its loading status. By default, it provides loading, failed, and empty views, but these can be assigned individually as well.

Requests to reload content should be sent from the view controller to the `loadingManager` via `-reloadContent`, or one of its sibling methods.

### WTALoadingProtocol
A view controller must implement `WTALoadingProtocol` in order to communicate with the `loadingManager`. Two methods are required:
  * `-loadContentIgnoreCache:completionHandler:` This is the primary method for performing network requests, called by WTALoadingManager -reloadContent. Perform a standard network request and call `completion(error, response)` when finished so the loading manager can properly configure state. If `error != nil`, `-loadFailed` will be called, if implemented, and the failed view will be presented.
  * `loadSuccess:completionHandler:` Called upon a successful API response. Call `completion(BOOL)` when post-processing is complete to notify the loading manager of a success or fail. If `NO` is passed in the `completion` call, the failed view will be presented.

## Getting Started

## Use Cases

## Additional Functionality
