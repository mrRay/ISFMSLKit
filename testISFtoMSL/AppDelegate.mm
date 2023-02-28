//
//  AppDelegate.m
//  testISFtoMSL
//
//  Created by testadmin on 2/12/23.
//

#import "AppDelegate.h"
#import <VVMetalKit/VVMetalKit.h>
#import "ISFMTLScene.h"
#import "TestMTLScene.h"
#include <memory>
#include <string>
#include "VVISF.hpp"




using namespace std;




@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet MTLImgBufferView * previewView;
@property (strong) ISFMTLScene * isfScene;
@property (strong) TestMTLScene * testScene;
@end




@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	RenderProperties		*rp = [RenderProperties global];
	if (rp == nil)	{
		NSLog(@"ERR: render properties nil, bailing, %s",__func__);
		return;
	}
	//	make the pool!
	[MTLPool createGlobalPoolWithDevice:rp.device];
	
	//	configure the preview view to use the same device we'll be using for rendering
	[self.previewView setDevice:rp.device];
	
	NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Functionality.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-IMG_PIXEL.fs"];
	self.isfScene = [[ISFMTLScene alloc] initWithDevice:rp.device isfURL:url];
	
	self.testScene = [[TestMTLScene alloc] initWithDevice:rp.device];
	
	[NSTimer
		scheduledTimerWithTimeInterval:1./60.
		repeats:YES
		block:^(NSTimer *t)	{
			[self draw];
		}];
	
	/*
	//std::shared_ptr<vector<string>>		files = CreateArrayOfDefaultISFs();
	std::shared_ptr<vector<string>>		files = VVISF::CreateArrayOfISFsForPath("/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials");
	std::sort(
		files->begin(),
		files->end(),
		[](const string & a, const string & b) -> bool	{
			return lexicographical_compare(
				a.begin(), a.end(),
				b.begin(), b.end(),
				[](const char & c1, const char & c2)	{
					return tolower(c1) < tolower(c2);
				}
				);
		});
	for (auto path : *files)	{
		NSURL			*url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path.c_str()]];
		ISFMTLScene		*tmpScene = [[ISFMTLScene alloc] initWithDevice:rp.device isfURL:url];
	}
	*/
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
}
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
	return YES;
}


- (void) draw	{
	//NSLog(@"%s",__func__);
	
	MTLImgBuffer		*newFrame = [[MTLPool global] bgra8TexSized:CGSizeMake(1920,1080)];;
	

#define CAPTURE 0
#if CAPTURE
	MTLCaptureManager		*cm = nil;
	static int				counter = 0;
	++counter;
	if (counter > 10)
		return;
	if (counter == 10)
		cm = [MTLCaptureManager sharedCaptureManager];
	MTLCaptureDescriptor		*desc = [[MTLCaptureDescriptor alloc] init];
	desc.captureObject = [RenderProperties global].renderQueue;

	if (cm!=nil && ![cm startCaptureWithDescriptor:desc error:nil])
		NSLog(@"ERR: couldn't start capturing metal data");
#endif
	
	
	id<MTLCommandBuffer>		cmdBuffer = [[RenderProperties global].renderQueue commandBuffer];
	
	//[self.testScene renderToBuffer:newFrame inCommandBuffer:cmdBuffer];
	[self.isfScene renderToBuffer:newFrame inCommandBuffer:cmdBuffer];
	
	if (newFrame != nil)	{
		self.previewView.imgBuffer = newFrame;
		[self.previewView drawInCmdBuffer:cmdBuffer];
	}
	else if (self.previewView.imgBuffer != nil)	{
		[self.previewView drawInCmdBuffer:cmdBuffer];
	}
	
	
	[cmdBuffer commit];
	
	
#if CAPTURE
	if (cm != nil)	{
		[cm stopCapture];
		[cmdBuffer waitUntilCompleted];
	}
#endif
	
	[[MTLPool global] housekeeping];
}


@end

