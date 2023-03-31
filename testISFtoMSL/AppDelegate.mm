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
	
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Audio.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-AudioFFT.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Bool.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Color.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Event.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Float.fs"];
	NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Functionality.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-IMG_NORM_PIXEL.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-IMG_PIXEL.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-IMG_THIS_NORM_PIXEL.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-IMG_THIS_PIXEL.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-ImportedImage.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Long.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-MultiPassRendering.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-PersistentBuffer.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-PersistentBufferDifferingSizes.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Point.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Sampler.fs"];
	//NSURL				*url = [NSURL fileURLWithPath:@"/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-TempBufferDifferingSizes.fs"];
	self.isfScene = [[ISFMTLScene alloc] initWithDevice:rp.device isfURL:url];
	
	self.testScene = [[TestMTLScene alloc] initWithDevice:rp.device];
	
	//[NSTimer
	//	scheduledTimerWithTimeInterval:1./60.
	//	repeats:YES
	//	block:^(NSTimer *t)	{
	//		[self draw];
	//	}];
	
	[self draw];
	
	/*
	std::shared_ptr<vector<string>>		files = VVISF::CreateArrayOfDefaultISFs();
	//std::shared_ptr<vector<string>>		files = VVISF::CreateArrayOfISFsForPath("/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials");
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
	
	id<MTLCommandBuffer> cmdBuffer = nil;
	MTLImgBuffer * newFrame = [[MTLPool global] bgra8TexSized:CGSizeMake(1920,1080)];;
	
#define CAPTURE 0
#if CAPTURE
	MTLCaptureManager		*cm = nil;
	static int				counter = 0;
	++counter;
	if (counter > 10)
		return;
	if (counter == 1)
		cm = [MTLCaptureManager sharedCaptureManager];
	MTLCaptureDescriptor		*desc = [[MTLCaptureDescriptor alloc] init];
	desc.captureObject = [RenderProperties global].renderQueue;

	if (cm!=nil && ![cm startCaptureWithDescriptor:desc error:nil])
		NSLog(@"ERR: couldn't start capturing metal data");
#endif
	
	
	cmdBuffer = [[RenderProperties global].renderQueue commandBuffer];
	
	//[self.testScene renderToBuffer:newFrame inCommandBuffer:cmdBuffer];
	[self.isfScene renderToBuffer:newFrame inCommandBuffer:cmdBuffer];
	
	[cmdBuffer commit];
	
	
#if CAPTURE
	if (cm != nil)	{
		[cm stopCapture];
		[cmdBuffer waitUntilCompleted];
	}
#endif
	
	cmdBuffer = [[RenderProperties global].renderQueue commandBuffer];
	
	if (newFrame != nil)	{
		self.previewView.imgBuffer = newFrame;
		[self.previewView drawInCmdBuffer:cmdBuffer];
	}
	else if (self.previewView.imgBuffer != nil)	{
		[self.previewView drawInCmdBuffer:cmdBuffer];
	}
	
	[cmdBuffer commit];
	
	[[MTLPool global] housekeeping];
}


@end

