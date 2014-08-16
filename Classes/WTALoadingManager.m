//
//  WTALoadingManager.m
//  WillowTree Apps, Inc.
//
//  Created by Alex Shafran on 2/25/14.
//  Copyright (c) 2014 WillowTree Apps, Inc. All rights reserved.
//

#import "WTALoadingManager.h"
#import "WTALoadingView.h"
#import "WTAFailedView.h"
#import <objc/runtime.h>

const char *WTALoadingManagerLazyLoadKey = "WTALoadingManagerLazyLoadKey";

@interface WTALoadingManager ()

@property (nonatomic, weak) UIScrollView *parentScrollView;

@end

@implementation UIViewController (WTALoadingManager)

#pragma mark - Accessors

- (WTALoadingManager *)loadingManager
{
    WTALoadingManager *manager = objc_getAssociatedObject(self, &WTALoadingManagerLazyLoadKey);
    
    if (!manager && [self conformsToProtocol:@protocol(WTALoadingProtocol)])
    {
        UIViewController<WTALoadingProtocol>*loadSelf = (UIViewController<WTALoadingProtocol>*)self;
        manager = [WTALoadingManager loadingManagerWithViewController:loadSelf];
    }

    return manager;
}

- (void)setLoadingManager:(WTALoadingManager *)loadingManager
{
    objc_setAssociatedObject(self,
                             &WTALoadingManagerLazyLoadKey,
                             loadingManager,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation WTALoadingManager

@synthesize loadingView = _loadingView;
@synthesize failedView = _failedView;
@synthesize emptyView = _emptyView;

#pragma mark - Initializers

+ (instancetype)loadingManagerWithViewController:(UIViewController <WTALoadingProtocol> *)controller
{
    [self validateViewController:controller];
    
    WTALoadingManager *manager = [self new];
    
    if (manager && [controller conformsToProtocol:@protocol(WTALoadingProtocol)])
    {
        controller.loadingManager = manager;
        manager.viewController = controller;
        
        if ([controller isKindOfClass:[UITableViewController class]] ||
            [controller isKindOfClass:[UICollectionViewController class]])
        {
            UIScrollView *scrollView = (UIScrollView *)controller.view;
            [manager setAutomaticallyAdjustsStatusViewsForScrollView:scrollView];
        }
    }
    
    return manager;
}

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self)
    {
        self.loadingStatus = WTALoadingStatusPreLoading;    
    }
    
    return self;
}

#pragma mark - Property Overrides

- (void)setLoadingStatus:(WTALoadingStatus)loadingStatus
{
    switch (loadingStatus)
    {
        case WTALoadingStatusLoading:
        case WTALoadingStatusForegroundRefreshing:
        {
            BOOL animated = self.loadingStatus != WTALoadingStatusPreLoading;
            [self animateStatusView:self.loadingView visible:YES animated:animated];
            [self animateStatusView:self.failedView visible:NO];
            [self animateStatusView:self.emptyView visible:NO];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            break;
        }
        case WTALoadingStatusPaging:
        case WTALoadingStatusBackgroundRefreshing:
        {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            
            break;
        }
            
        case WTALoadingStatusLoaded:
        case WTALoadingStatusCancelled:
        {
            [self animateStatusView:self.loadingView visible:NO];
            [self animateStatusView:self.failedView visible:NO];
            [self animateStatusView:self.emptyView visible:NO];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            break;
        }
        case WTALoadingStatusFailed:
        {
            BOOL showFailedView = YES;
            if ([self.viewController respondsToSelector:@selector(shouldShowFailedView)])
            {
                showFailedView = [self.viewController shouldShowFailedView];
            }
            
            [self animateStatusView:self.loadingView visible:NO];
            [self animateStatusView:self.failedView visible:showFailedView];
            [self animateStatusView:self.emptyView visible:NO];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            break;
        }
        case WTALoadingStatusEmpty:
        {
            [self animateStatusView:self.loadingView visible:NO];
            [self animateStatusView:self.failedView visible:NO];
            [self animateStatusView:self.emptyView visible:YES];
            
            break;
        }
            
        default:
            break;
    }
    
    _loadingStatus = loadingStatus;
    
    if ([self.viewController respondsToSelector:@selector(loadingStatusChanged:)])
    {
        [self.viewController loadingStatusChanged:loadingStatus];
    }
}

#pragma mark - Instance methods

- (BOOL)isLoading
{
    return (self.loadingStatus == WTALoadingStatusBackgroundRefreshing) ||
            (self.loadingStatus == WTALoadingStatusForegroundRefreshing) ||
            (self.loadingStatus == WTALoadingStatusLoading) ||
            (self.loadingStatus == WTALoadingStatusPaging);
}

- (void)reloadContent
{
    BOOL force = NO;
    
    if ([self.viewController respondsToSelector:@selector(shouldForceReload)])
    {
        force = [self.viewController shouldForceReload];
    }

    [self reloadContent:force];
}

- (void)reloadContent:(BOOL)forceReload
{
    BOOL background = NO;
    
    if ([self.viewController respondsToSelector:@selector(shouldLoadInBackground)])
    {
        background = [self.viewController shouldLoadInBackground];
    }
    
    [self reloadContent:forceReload inBackground:background];
}

- (void)reloadContent:(BOOL)forceReload inBackground:(BOOL)background
{
    BOOL shouldReload = YES;
    if ([self.viewController respondsToSelector:@selector(shouldReload)])
    {
        shouldReload = [self.viewController shouldReload];
    }
    
    if (shouldReload && (self.loadingStatus != WTALoadingStatusLoaded || forceReload))
    {
        if ([self.viewController respondsToSelector:@selector(networkOperationQueue)])
        {
            NSOperationQueue *operationQueue = [self.viewController networkOperationQueue];
            [operationQueue cancelAllOperations];
        }
        
        else if (background)
        {
            [self setLoadingStatus:WTALoadingStatusBackgroundRefreshing];
        }
        else if (forceReload)
        {
            [self setLoadingStatus:WTALoadingStatusForegroundRefreshing];
        }
        else
        {
            [self setLoadingStatus:WTALoadingStatusLoading];
        }
        
        [self.viewController loadContentIgnoreCache:forceReload
                                  completionHandler:^(NSError *error, id results)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                    if ([error code] == NSURLErrorCancelled)
                    {
                        if ([self.viewController respondsToSelector:@selector(loadCancelled:)])
                        {
                            [self.viewController loadCancelled:error];
                        }
                        
                        self.loadingStatus = WTALoadingStatusCancelled;
                    }
                    else
                    {
                        if ([self.viewController respondsToSelector:@selector(loadFailed:)])
                        {
                            [self.viewController loadFailed:error];
                        }
                        
                        [self updateFailedViewForError:error];
                        self.loadingStatus = WTALoadingStatusFailed;
                    }
                }
                else
                {
                    [self handleSuccess:results];
                }
            });
        }];
    }
}

- (void)pageContent
{
    if (self.loadingStatus != WTALoadingStatusLoading &&
        self.loadingStatus != WTALoadingStatusPaging)
    {
        self.loadingStatus = WTALoadingStatusPaging;
        [self.viewController loadContentIgnoreCache:NO
                                  completionHandler:^(NSError *error, id results)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (error)
                {
                    if ([self.self.viewController respondsToSelector:@selector(pagingFailed:)])
                    {
                        [self.viewController pagingFailed:error];
                    }
                    
                    [self updateFailedViewForError:error];
                    self.loadingStatus = WTALoadingStatusFailed;
                }
                else
                {
                    [self handleSuccess:results];
                }
            });
            
        }];
    }
}

- (void)handleSuccess:(id)results
{
    __weak typeof(self) bself = self;
        
    [self.viewController loadSuccess:results completionHandler:^(BOOL success)
     {
         if (success)
         {
             BOOL empty = NO;
             if ([bself.viewController respondsToSelector:@selector(shouldShowEmptyView)])
             {
                 empty = [bself.viewController shouldShowEmptyView];
             }
             
             bself.loadingStatus = empty ? WTALoadingStatusEmpty : WTALoadingStatusLoaded;
         }
         else
         {
             [bself updateFailedViewForError:nil];
             bself.loadingStatus = WTALoadingStatusFailed;
         }
     }];
}

- (void)updateStatusViewFrameForScrollView:(UIScrollView *)scrollView
{
    CGRect frame = self.viewController.view.bounds;
    CGFloat offset = scrollView.contentOffset.y;
    frame.origin.y = offset;
    
    self.loadingView.frame = frame;
    self.failedView.frame = frame;
    self.emptyView.frame = frame;
}

- (void)setAutomaticallyAdjustsStatusViewsForScrollView:(UIScrollView *)scrollView
{
    self.parentScrollView = scrollView;
}

#pragma mark - Status animations

- (void)animateStatusView:(UIView *)statusView visible:(BOOL)visible
{
    [self animateStatusView:statusView visible:visible animated:YES];
}

- (void)animateStatusView:(UIView *)statusView visible:(BOOL)visible animated:(BOOL)animated
{
    [self.viewController.view bringSubviewToFront:statusView];
    if (self.parentScrollView)
    {
        [self updateStatusViewFrameForScrollView:self.parentScrollView];
    }

//    [statusView.layer removeAllAnimations];
    
    CGFloat alpha = visible ? 1. : 0.;
    
    statusView.hidden = NO;
    
    [UIView animateWithDuration:animated ? .3 : 0.
                     animations:
     ^{
         statusView.alpha = alpha;
         
     }
                     completion:^(BOOL finished)
     {
//         statusView.hidden = !visible;
     }];

}

#pragma mark - Status view properties

- (UIView *)loadingView
{
    if (!_loadingView)
    {
        self.loadingView = [self defaultLoadingView];
    }
    
    return _loadingView;
}

- (UIView *)failedView
{
    if (!_failedView)
    {
        self.failedView = [self defaultFailedView];
    }
    
    return _failedView;
}

- (UIView *)emptyView
{
    if (!_emptyView)
    {
        self.emptyView = [self defaultEmptyView];
    }
    
    return _emptyView;
}

- (void)setLoadingView:(UIView *)loadingView
{
    if (_loadingView)
    {
        [_loadingView removeFromSuperview];
    }
    _loadingView = loadingView;
    _loadingView.frame = self.viewController.view.bounds;
    _loadingView.alpha = 0.;
    
    [self.viewController.view addSubview:loadingView];
}

- (void)setFailedView:(UIView *)failedView
{
    if (_failedView)
    {
        [_failedView removeFromSuperview];
    }
    _failedView = failedView;
    _failedView.frame = self.viewController.view.bounds;
    _failedView.alpha = 0.;
    
    [self.viewController.view addSubview:failedView];
}

- (void)setEmptyView:(UIView *)emptyView
{
    if (_emptyView)
    {
        [_emptyView removeFromSuperview];
    }
    _emptyView = emptyView;
    _emptyView.frame = self.viewController.view.bounds;
    _emptyView.alpha = 0.;
    
    [self.viewController.view addSubview:emptyView];
}

#pragma mark - Default status views

- (void)addDefaultStatusViews
{
    if (!self.loadingView)
    {
        self.loadingView = [self defaultLoadingView];
    }
    
    if (!self.failedView)
    {
        self.failedView = [self defaultFailedView];
    }
    
    if (!self.emptyView)
    {
        self.emptyView = [self defaultEmptyView];
    }
}

- (UIView *)defaultLoadingView
{
    return [[WTALoadingView alloc] init];
}

- (UIView *)defaultFailedView
{
    WTAFailedView *view = [[WTAFailedView alloc] init];
    view.messageLabel.text = [self defaultErrorMessage];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(failedViewTapGesture:)];
    [view addGestureRecognizer:tapGestureRecognizer];
    
    return view;
}

- (UIView *)defaultEmptyView
{
    WTAFailedView *view = [[WTAFailedView alloc] init];
    view.messageLabel.text = [self defaultEmptyMessage];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(emptyViewTapGesture:)];
    [view addGestureRecognizer:tapGestureRecognizer];
    
    return view;
}

- (NSString *)defaultErrorMessage
{
    return NSLocalizedString(@"Could not load content.\nTap to reload.",
                             @"Loading error message");
}


- (NSString *)defaultEmptyMessage
{
    return NSLocalizedString(@"No content posted.\nTap to reload.",
                             @"Loading empty message");
}

- (void)updateFailedViewForError:(NSError *)error
{
    NSString *message;
    
    if ([self.viewController respondsToSelector:@selector(errorMessageForError:)])
    {
        message = [self.viewController errorMessageForError:error];
    }
    else if ([error.localizedDescription length] > 0)
    {
        message = [NSString stringWithFormat:@"%@ %@", error.localizedDescription,
                   NSLocalizedString(@"Please tap to reload.", @"Tap to reload prompt")];
    }
    else
    {
        message = [self defaultErrorMessage];
    }
    
    if ([self.failedView isKindOfClass:[WTAFailedView class]])
    {
        WTAFailedView *failedView = (WTAFailedView *)self.failedView;
        failedView.messageLabel.text = message;
    }
}

#pragma mark - Actions

- (void)failedViewTapGesture:(id)sender
{
    [self reloadContent];
}

- (void)emptyViewTapGesture:(id)sender
{
    [self reloadContent:YES];
}

#pragma mark - Error checking

+ (void)validateViewController:(UIViewController *)controller
{
    NSString *className = NSStringFromClass([controller class]);
    NSString *message = [NSString stringWithFormat:
                         @"WTALoadingManager -loadingManagerWithViewController: Improper usage. "
                         "%@ must have view loaded. Try calling in -viewDidLoad", className];
    NSAssert([controller isViewLoaded], message);
}

@end

