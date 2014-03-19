//
//  WTALoadingView.m
//  Redef
//
//  Created by Alex Shafran on 2/25/14.
//  Copyright (c) 2014 Redef Group. All rights reserved.
//

#import "WTALoadingView.h"

@implementation WTALoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        self.activityIndicatorView.autoresizingMask = self.autoresizingMask;
        [self.activityIndicatorView startAnimating];
        self.activityIndicatorView.hidesWhenStopped = YES;
        
        [self addSubview:self.activityIndicatorView];
        
    }
    return self;
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    self.activityIndicatorView.hidden = hidden;
}

@end
