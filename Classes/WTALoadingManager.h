//
//  WTALoadingManager.h
//  WillowTree Apps, Inc.
//
//  Created by Alex Shafran on 2/25/14.
//  Copyright (c) 2014 WillowTree Apps, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WTALoadingStatus)
{
    WTALoadingStatusPreLoading,
    WTALoadingStatusLoading,
    WTALoadingStatusForegroundRefreshing,
    WTALoadingStatusBackgroundRefreshing,
    WTALoadingStatusPaging,
    WTALoadingStatusLoaded,
    WTALoadingStatusFailed,
    WTALoadingStatusCancelled,
    WTALoadingStatusEmpty,
};

@class WTALoadingManager;

///------------------------------------------------------------------------
/// @name Make a loading manager object available to all view controllers
///------------------------------------------------------------------------

@interface UIViewController (WTALoadingManager)

/**
 The default loading manager assigned to a view controller. Is lazy-loaded when needed.

 */
@property (nonatomic, strong) WTALoadingManager *loadingManager;

@end

///------------------------------------------------------------------------
/// @name Must implement WTALoadingProtocol for the loading manager to work
///------------------------------------------------------------------------

@protocol WTALoadingProtocol <NSObject>

/**
 The primary method for performing network requests, called by WTALoadingManager -reloadContent.
 
 @param ignoreCache Whether or not to force a reload. Defaults to NO when content is already loaded
 @param completion A block to call once the network request is complete
 */
- (void)loadContentIgnoreCache:(BOOL)ignoreCache
             completionHandler:(void (^)(NSError *error, id results))completion;

/**
 Called by WTALoadingManger when a network request is completed successfully. Perform any post-
    processing before calling completionHandler(BOOL success). The completion handler allows
    dipatching to a background thread for async saves while maintaining the loading indicator
 
 @param response The network response
 @param completionHandler Call with success = YES/NO when processing is complete. Will dismiss the
    loading view and present the failed view if passed success = NO
 */
- (void)loadSuccess:(id)response completionHandler:(void (^)(BOOL success))completionHandler;

@optional

/**
 Called when the loading status changes
 
 @param LoadingStatus
 */
- (void)loadingStatusChanged:(WTALoadingStatus)loadingStatus;

/**
 Called by WTALoadingManager when a network request is cancelled,
    based on error.code == NSURLErrorCancelled
 
 @param error The error provided by -loadContentIgnoreCache:completionHandler:
 */
- (void)loadCancelled:(NSError *)error;

/**
 Called by WTALoadingManager when a network request fails,
    based on -loadContentIgnoreCache:completionHandler:
 
 @param error The error provided by -loadContentIgnoreCache:completionHandler:
 */
- (void)loadFailed:(NSError *)error;

/**
 Called by WTALoadingManager when a paging request fails, 
    based on -loadContentIgnoreCache:withCompletion:
 
 @param error The error provided by -loadContentIgnoreCache:completionHandler:
 */
- (void)pagingFailed:(NSError *)error;

/**
 Called by WTALoadingManager before a new network request is made. Allows the receiver to provide a
    queue of requests to cancel.
 
 @return the operation queue used for network requests
 */
- (NSOperationQueue *)networkOperationQueue;

/**
 Called by WTALoadingManager before a new network request is made. Allows the receiver to cancel
    reload requests. Useful for dynamically turning the loading manager on or off.
 
 @return Whether the loading manager should reload. Default: YES
 */
- (BOOL)shouldReload;

/**
 Called by WTALoadingManager during -reloadContent after the manager has determined that a load
 is not necessary (loading staus == loaded). Allows the receiver to force a reload.
 
 @return Whether or not the loading manager should reload. Default: NO
 */
- (BOOL)shouldForceReload;

/**
 Called by WTALoadingManager before a new network request is made. Allows the receiver to provide
    a preference for loading in the foreground vs. background.
 
 @return Whether or not the loading manager should reload in the background. Recommend returning 
    YES if useful content is already available. Default: NO
 */
- (BOOL)shouldLoadInBackground;

/**
 Called by WTALoadingManager after a failed network request but before the failed view is displayed. 
    Allows the receiver to hide the failed view.
 
 @return Whether or not the loading manager should show the failed view. Recommend returning YES
    if useful content is available after a failed load. Default: YES
 */
- (BOOL)shouldShowFailedView;

/**
 Called by WTALoadingManager after a successful network request but before the failed view is
 dismissed. Allows the receiver to show an empty view if no content is available.

 @return Whether or not the loading manager should show the failed view. Recommend returning NO
 if no content was returned but useful content is still available. Default: YES
 */
- (BOOL)shouldShowEmptyView;

/**
 Called by WTALoadingManager after a failed network request but before the failed view is
 displayed. Allows the receiver to provide a new error message.
 
 @param error The error provided by -loadContentIgnoreCache:completionHandler:
 @return An user-facing error message. Default: A generic error message, or
    "[error localizedDescription]" if available.
 */
- (NSString *)errorMessageForError:(NSError *)error;

@end

///------------------------------------------------------------------------
/// @name The underlying loading manager
///------------------------------------------------------------------------

@interface WTALoadingManager : NSObject

/**
 The Default initializer. Lazy loaded/called automatically when -loadingManager is called 
    for the first time.
 
 @param controller The view controller for receiving WTALoadingProtol messages and displaying 
    status views
 @return An instance of WTALoading manager. Must be retained
 */
+ (instancetype)loadingManagerWithViewController:(UIViewController<WTALoadingProtocol> *)controller;

@property (nonatomic, assign) WTALoadingStatus loadingStatus;
@property (nonatomic, weak) UIViewController<WTALoadingProtocol> *viewController;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *failedView;
@property (nonatomic, strong) UIView *emptyView;

/**
 Convenience method to account for all "loading" states. Includes:
     WTALoadingStatusLoading
     WTALoadingStatusForegroundRefreshing
     WTALoadingStatusBackgroundRefreshing
     WTALoadingStatusPaging
 
 @return Whether or not the loading manager's state is considered "loading".
 */
- (BOOL)isLoading;

/**
 The primary method of reloading content. Call on viewWillAppear/viewDidAppear to have the loading
 manager decide if it should reload or not. 
 Default: reloads if the loading status != WTALoadingStatusLoaded.
 */
- (void)reloadContent;

/**
 To force a reload.
 
 @param forceReload To force a reload, regardless of loading status.
 */
- (void)reloadContent:(BOOL)forceReload;

/**
 To force a reload in the background.
 
 @param forceReload To force a reload, regardless of loading status.
 @param background To reload in the background, regardless of loading status.
 */
- (void)reloadContent:(BOOL)forceReload inBackground:(BOOL)background;

/**
 The primary method of paginating content. Sets the loading status to "paging" and calls 
    --loadContentIgnoreCache:completionHandler: on its view controller. 
    Does not show a loading indicator.
 */
- (void)pageContent;

/**
 Automatically adjust status view offset relative to its scrollView superview.
    Recommend settings to YES if the view controllers root view is a scroll view.
    Default: NO, unless the viewController is a UITableViewController or UICollectionViewController.
 
 @param scrollView The scrollView that will be the superview for all status views managed by the 
    loading manager
 */
- (void)setAutomaticallyAdjustsStatusViewsForScrollView:(UIScrollView *)scrollView;

/**
 Manually update the status view y offsets. Useful if the root view is a scroll view
    (e.g. UITableViewController). Suggest calling from -scrollViewDidScroll: or similar
 
 @param scrollView The scrollView that is the superview for all status views managed by the
 loading manager
 */
- (void)updateStatusViewFrameForScrollView:(UIScrollView *)scrollView;

/**
 Add the default loading, failed, and empty status views. These are lazy loaded automatically, 
    but calling this in -viewDidLoad ensures that views are there before the view appears.
 */
- (void)addDefaultStatusViews;

@end
