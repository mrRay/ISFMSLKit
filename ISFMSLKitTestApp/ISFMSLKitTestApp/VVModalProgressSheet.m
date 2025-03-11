//
//  VVModalProgressSheet.m
//  VVCore
//
//  Created by testAdmin on 7/29/21.
//  Copyright © 2021 yourcompany. All rights reserved.
//

#import "VVModalProgressSheet.h"




@interface VVModalProgressSheet ()	{
	NSArray			*nibTopLevelObjects;
	
	IBOutlet __weak NSWindow				*sheet;
	
	IBOutlet __weak NSTextField				*titleLabelField;
	IBOutlet __weak NSTextField				*topLabelField;
	IBOutlet __weak NSProgressIndicator		*topProgressBar;
	IBOutlet __weak NSTextField				*bottomLabelField;
	IBOutlet __weak NSProgressIndicator		*bottomProgressBar;
	
	IBOutlet __weak NSButton				*cancelButton;
	
	id				retainedSelf;
}

- (IBAction) cancelClicked:(id)sender;

//@property (nonatomic,copy,nullable) void (^completionHandler)(NSModalResponse);
@property (weak) NSWindow * parentWindow;

@end




@implementation VVModalProgressSheet


#pragma mark - init/dealloc


+ (instancetype) create	{
	return [[VVModalProgressSheet alloc] init];
}


- (instancetype) init	{
	self = [super init];
	if (self != nil)	{
		nibTopLevelObjects = nil;
		
		self.showTitle = NO;
		
		self.showTopBar = YES;
		self.showTopLabel = YES;
		self.topBarIndeterminate = YES;
		
		self.showBottomBar = NO;
		self.showBottomLabel = NO;
		self.bottomBarIndeterminate = NO;
		
		self.showCancelButton = NO;
		
		self.parentWindow = nil;
		
		retainedSelf = nil;
	
		//	make the nib
		NSNib			*tmpNib = [[NSNib alloc] initWithNibNamed:[self className] bundle:[NSBundle bundleForClass:[self class]]];
		NSArray			*tmpObjects = nil;
		[tmpNib instantiateWithOwner:self topLevelObjects:&tmpObjects];
		nibTopLevelObjects = tmpObjects;
	}
	return self;
}
//- (void) dealloc	{
//	NSLog(@"%s",__func__);
//}


#pragma mark - opening/closing the sheet


- (void) beginSheetModalForWindow:(NSWindow *)w completionHandler:(void (^ _Nullable )(NSModalResponse returnCode))h	{
	if (w == nil)	{
		NSLog(@"ERR: win nil, bailing, %s",__func__);
		return;
	}
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self beginSheetModalForWindow:w completionHandler:h];
		});
		return;
	}
	
	self.parentWindow = w;
	
	titleLabelField.hidden = !self.showTitle;
	
	topLabelField.hidden = !self.showTopLabel;
	topProgressBar.hidden = !self.showTopBar;
	topProgressBar.indeterminate = self.topBarIndeterminate;
	if (!self.topBarIndeterminate)
		topProgressBar.doubleValue = 0.0;
	
	bottomLabelField.hidden = !self.showBottomLabel;
	bottomProgressBar.hidden = !self.showBottomBar;
	bottomProgressBar.indeterminate = self.bottomBarIndeterminate;
	if (!self.bottomBarIndeterminate)
		bottomProgressBar.doubleValue = 0.0;
	
	cancelButton.hidden = !self.showCancelButton;
	
	if (self.showTopBar && self.topBarIndeterminate)
		[topProgressBar startAnimation:nil];
	
	if (self.showBottomBar && self.bottomBarIndeterminate)
		[bottomProgressBar startAnimation:nil];
	
	//	open the sheet!
	[w beginSheet:sheet completionHandler:h];
	
	//	retain myself, or i'll be freed as soon as i fall out of scope!
	retainedSelf = self;
}


- (void) closeWithReturnCode:(NSModalResponse)r	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self closeWithReturnCode:r];
		});
		return;
	}
	
	[self.parentWindow endSheet:sheet returnCode:r];
	
	if (self.showTopBar && self.topBarIndeterminate)
		[topProgressBar stopAnimation:nil];
	
	if (self.showBottomBar && self.bottomBarIndeterminate)
		[bottomProgressBar stopAnimation:nil];
	
	//	free myself
	retainedSelf = nil;
}


#pragma mark - setters


- (void) setTitleLabel:(NSString *)n	{
	if (!self.showTitle)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTitleLabel:n];
		});
		return;
	}
	
	[titleLabelField setStringValue:(n==nil) ? @"" : n];
}
- (NSString *) titleLabel	{
	[NSException raise:NSInternalInconsistencyException format:@"This property is write-only %s",__func__];
	return nil;
}


- (void) setTopLabel:(NSString *)n	{
	if (!self.showTopLabel)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTopLabel:n];
		});
		return;
	}
	
	//NSLog(@"%s ... %@",__func__,n);
	[topLabelField setStringValue:(n==nil) ? @"" : n];
}
- (NSString *) topLabel	{
	[NSException raise:NSInternalInconsistencyException format:@"This property is write-only %s",__func__];
	return nil;
}
- (void) setTopBarValue:(double)n	{
	//NSLog(@"%s ... %0.2f",__func__,n);
	if (!self.showTopBar)
		return;
	if (self.topBarIndeterminate)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTopBarValue:n];
		});
		return;
	}
	
	[topProgressBar setDoubleValue:n];
}
- (double) topBarValue	{
	[NSException raise:NSInternalInconsistencyException format:@"This property is write-only %s",__func__];
	return 0.0;
}
- (void) incrementTopBarValueBy:(double)n	{
	if (!self.showTopBar)
		return;
	if (self.topBarIndeterminate)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self incrementTopBarValueBy:n];
		});
		return;
	}
	
	[topProgressBar setDoubleValue:topProgressBar.doubleValue + n];
}


- (void) setBottomLabel:(NSString *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (!self.showBottomLabel)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setBottomLabel:n];
		});
		return;
	}
	
	[bottomLabelField setStringValue:(n==nil) ? @"" : n];
}
- (NSString *) bottomLabel	{
	[NSException raise:NSInternalInconsistencyException format:@"This property is write-only %s",__func__];
	return nil;
}
- (void) setBottomBarValue:(double)n	{
	//NSLog(@"%s ... %0.2f",__func__,n);
	if (!self.showBottomBar)
		return;
	if (self.bottomBarIndeterminate)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setBottomBarValue:n];
		});
		return;
	}
	
	[bottomProgressBar setDoubleValue:n];
}
- (double) bottomBarValue	{
	[NSException raise:NSInternalInconsistencyException format:@"This property is write-only %s",__func__];
	return 0.0;
}
- (void) incrementBottomBarValueBy:(double)n	{
	if (!self.showBottomBar)
		return;
	if (self.bottomBarIndeterminate)
		return;
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self incrementBottomBarValueBy:n];
		});
		return;
	}
	
	[bottomProgressBar setDoubleValue:bottomProgressBar.doubleValue + n];
}


#pragma mark - UI actions


- (IBAction) cancelClicked:(id)sender	{
	[self closeWithReturnCode:NSModalResponseCancel];
}


@end
