/*
    DLStarRating
    Copyright (C) 2011 David Linsin <dlinsin@gmail.com> 

    All rights reserved. This program and the accompanying materials
    are made available under the terms of the Eclipse Public License v1.0
    which accompanies this distribution, and is available at
    http://www.eclipse.org/legal/epl-v10.html

 */

#import "DLStarRatingControl.h"
#import "DLStarView.h"
#import "UIView+Subviews.h"

@implementation DLStarRatingControl

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
		_numberOfStars = kDefaultNumberOfStars;
        if (_isFractionalRatingEnabled)
            _numberOfStars *=kNumberOfFractions;
		[self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
    {
		_numberOfStars = kDefaultNumberOfStars;
        if (_isFractionalRatingEnabled)
            _numberOfStars *=kNumberOfFractions;
        [self setupView];
	}
    
	return self;
}

- (id)initWithFrame:(CGRect)frame andStars:(NSUInteger)__numberOfStars isFractional:(BOOL)isFract
{
	self = [super initWithFrame:frame];
	if (self)
    {
        _isFractionalRatingEnabled = isFract;
		__numberOfStars = _numberOfStars;
        if (_isFractionalRatingEnabled)
            _numberOfStars *=kNumberOfFractions;
		[self setupView];
	}
	return self;
}

- (void)setupView
{
	self.clipsToBounds = YES;
	currentIdx = -1;
	_star = [UIImage imageNamed:@"star.png"];
	_highlightedStar = [UIImage imageNamed:@"star_highlighted.png"];
	
    for (int i = 0; i<_numberOfStars; i++)
    {
        CGRect destinationFrame = CGRectMake((self.frame.size.width/_numberOfStars)*i, 0, (self.frame.size.width/_numberOfStars), self.frame.size.height);
		DLStarView *starView = [[DLStarView alloc] initWithDefault:[self resizedImage:self.star withFrame:destinationFrame] highlighted:[self resizedImage:self.highlightedStar withFrame:destinationFrame] position:i allowFractions:_isFractionalRatingEnabled andFrame:destinationFrame];
		[self addSubview:starView];
	}
}

- (void)layoutSubviews
{
	for (int i=0; i < _numberOfStars; i++)
    {
		[(DLStarView *)[self subViewWithTag:i] centerIn:self.frame with:_numberOfStars];
	}
}

-(UIImage *)resizedImage:(UIImage *)image withFrame:(CGRect)destinationFrame
{
    CGFloat aspect = CGRectGetHeight(destinationFrame) <= CGRectGetWidth(destinationFrame) ? CGRectGetHeight(destinationFrame) : CGRectGetWidth(destinationFrame);
    
    UIImage *newImage = nil;
    UIGraphicsBeginImageContextWithOptions(destinationFrame.size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, aspect, aspect)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - Setters

-(void)setNumberOfStars:(NSInteger)numberOfStars
{
    _numberOfStars = numberOfStars;
    [self setupView];
}

#pragma mark -
#pragma mark Customization

- (void)setStar:(UIImage *)defaultStarImage highlightedStar:(UIImage *)highlightedStarImage atIndex:(NSInteger)index
{
    DLStarView *selectedStar = (DLStarView *)[self subViewWithTag:index];
    
    // check if star exists
    if (!selectedStar) return;
    
    // check images for nil else use default stars
    defaultStarImage = (defaultStarImage) ? defaultStarImage : _star;
    highlightedStarImage = (highlightedStarImage) ? highlightedStarImage : _highlightedStar;
    
    [selectedStar setStarImage:defaultStarImage highlightedStarImage:highlightedStarImage];
}

#pragma mark -
#pragma mark Touch Handling

- (UIButton*)starForPoint:(CGPoint)point {
	for (NSInteger i=0; i < _numberOfStars; i++) {
		if (CGRectContainsPoint([self subViewWithTag:i].frame, point)) {
			return (UIButton*)[self subViewWithTag:i];
		}
	}
	return nil;
}

- (void)disableStarsDownToExclusive:(NSInteger)idx {
	for (NSInteger i=_numberOfStars; i > idx; --i) {
		UIButton *b = (UIButton*)[self subViewWithTag:i];
		b.highlighted = NO;
	}
}

- (void)disableStarsDownTo:(NSInteger)idx {
	for (NSInteger i=_numberOfStars; i >= idx; --i) {
		UIButton *b = (UIButton*)[self subViewWithTag:i];
		b.highlighted = NO;
	}
}

- (void)enableStarsUpTo:(NSInteger)idx {
	for (NSInteger i=0; i <= idx; i++) {
		UIButton *b = (UIButton*)[self subViewWithTag:i];
		b.highlighted = YES;
	}
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];	
	UIButton *pressedButton = [self starForPoint:point];
	if (pressedButton) {
		NSInteger idx = pressedButton.tag;
		if (pressedButton.highlighted) {
			[self disableStarsDownToExclusive:idx];
		} else {
			[self enableStarsUpTo:idx];
		}		
		currentIdx = idx;
	} 
	return YES;		
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
	[super cancelTrackingWithEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];
	
	UIButton *pressedButton = [self starForPoint:point];
	if (pressedButton) {
		NSInteger idx = pressedButton.tag;
		UIButton *currentButton = (UIButton*)[self subViewWithTag:currentIdx];
		
		if (idx < currentIdx) {
			currentButton.highlighted = NO;
			currentIdx = idx;
			[self disableStarsDownToExclusive:idx];
		} else if (idx > currentIdx) {
			currentButton.highlighted = YES;
			pressedButton.highlighted = YES;
			currentIdx = idx;
			[self enableStarsUpTo:idx];
		}
	} else if (point.x < [self subViewWithTag:0].frame.origin.x) {
		((UIButton*)[self subViewWithTag:0]).highlighted = NO;
		currentIdx = -1;
		[self disableStarsDownToExclusive:0];
	}
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	[self.delegate newRating:self :self.rating];
	[super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark -
#pragma mark Rating Property

- (void)setRating:(float)_rating {
    if (_isFractionalRatingEnabled) {
        _rating *=kNumberOfFractions;
    }
	[self disableStarsDownTo:0];
	currentIdx = (NSInteger)_rating-1;
	[self enableStarsUpTo:currentIdx];
}

- (float)rating {
    if (_isFractionalRatingEnabled) {
        return (float)(currentIdx+1)/kNumberOfFractions;
    }
	return (NSUInteger)currentIdx+1;
}

@end