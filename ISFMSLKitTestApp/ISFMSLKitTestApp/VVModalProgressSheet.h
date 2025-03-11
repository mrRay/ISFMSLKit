//
//  VVModalProgressSheet.h
//  VVCore
//
//  Created by testAdmin on 7/29/21.
//  Copyright © 2021 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN




@interface VVModalProgressSheet : NSObject

//	a text field at the top of the window that looks like a "title".  NOT visible by default.
@property (readwrite) BOOL showTitle;

//	the top bar (and label) are visible by default.  bar/label can be shown/hidden independently of one another.
@property (readwrite) BOOL showTopBar;
@property (readwrite) BOOL showTopLabel;
//	the top bar is INDETERMINATE (and visible) by default
@property (readwrite) BOOL topBarIndeterminate;

//	the bottom bar (and label) are NOT visible by default.  bar/label can be shown/hidden independently of one another.
@property (readwrite) BOOL showBottomBar;
@property (readwrite) BOOL showBottomLabel;
//	the bottom bar is DETERMINATE by default (if you need to show it, you probably need it to display a value)
@property (readwrite) BOOL bottomBarIndeterminate;

//	the cancel button is NOT visible by default- clicking it automatically closes the progress sheet (with the cancel return code)
@property (readwrite) BOOL showCancelButton;

+ (instancetype) create;

- (instancetype) init;

- (void) beginSheetModalForWindow:(NSWindow *)w completionHandler:(void (^ _Nullable )(NSModalResponse returnCode))h;

@property (strong) NSString * titleLabel;
- (NSString *) titleLabel UNAVAILABLE_ATTRIBUTE;

@property (strong) NSString * topLabel;
- (NSString *) topLabel UNAVAILABLE_ATTRIBUTE;

@property double topBarValue;
- (double) topBarValue UNAVAILABLE_ATTRIBUTE;
- (void) incrementTopBarValueBy:(double)n;

@property (strong) NSString * bottomLabel;
- (NSString *) bottomLabel UNAVAILABLE_ATTRIBUTE;

@property double bottomBarValue;
- (double) bottomBarValue UNAVAILABLE_ATTRIBUTE;
- (void) incrementBottomBarValueBy:(double)n;

- (void) closeWithReturnCode:(NSModalResponse)r;

@end




NS_ASSUME_NONNULL_END
