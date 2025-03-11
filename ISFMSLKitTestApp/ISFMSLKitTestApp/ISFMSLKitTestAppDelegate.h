//
//  AppDelegate.h
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/3/23.
//

#import <Cocoa/Cocoa.h>

#import <VVMetalKit/VVMetalKit.h>




@interface ISFMSLKitTestAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet VVMTLTextureImageView * preview;
@property (strong) IBOutlet NSPopUpButton * srcISFPUB;
@property (strong) IBOutlet NSPopUpButton * filterISFPUB;

- (IBAction) pubUsed:(NSPopUpButton *)sender;

@end

