//
//  WTAFailedView.m
//  Redef
//
//  Created by Alex Shafran on 2/25/14.
//  Copyright (c) 2014 Redef Group. All rights reserved.
//

#import "WTAFailedView.h"

@implementation WTAFailedView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.messageLabel.autoresizingMask = self.autoresizingMask;
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.textColor = [UIColor darkGrayColor];
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.messageLabel];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.messageLabel.frame = CGRectInset(self.bounds, 20, 0);
}

@end
