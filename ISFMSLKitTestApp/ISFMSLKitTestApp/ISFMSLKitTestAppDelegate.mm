//
//  AppDelegate.m
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/3/23.
//

#import "ISFMSLKitTestAppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <Dispatch/Dispatch.h>
#import <CoreMedia/CoreMedia.h>
#import <ISFMSLKit/ISFMSLKit.h>




@interface ISFMSLKitTestAppDelegate ()	{
}
@property (strong) ISFMSLScene * srcScene;
@property (strong) ISFMSLScene * filterScene;
@property (strong) NSTimer * renderTimer;
- (void) renderTimer:(NSTimer *)t;
@end




@implementation ISFMSLKitTestAppDelegate


- (nullable instancetype) init	{
	NSLog(@"%s",__func__);
	self = [super init];
	
	//	make sure that we can get a RenderProperties for rendering...
	RenderProperties		*rp = [RenderProperties global];
	if (rp == nil)	{
		NSLog(@"ERR: render properties nil, bailing, %s",__func__);
		self = nil;
	}
	
	if (self != nil)	{
		//	make a pool- this will recycle textures/etc used by VVMetalKit (and ISFMSLKit)
		VVMTLPool.global = [[VVMTLPool alloc] initWithDevice:RenderProperties.global.device];
		
		//	make and ISF cache to store compiled shader data on disk
		NSString		*cacheDir = [@"~/Library/Application Support/ISFMSLKitTestApp" stringByExpandingTildeInPath];
		ISFMSLCache		*cache = [[ISFMSLCache alloc] initWithDirectoryPath:cacheDir];
		ISFMSLCache.primary = cache;
	}
	return self;
}
- (void) awakeFromNib	{
	//	the preview needs to know which device to use to for drawing...
	_preview.device = [RenderProperties global].device;
	
	//	get the paths to the embedded ISF files
	NSBundle		*mb = NSBundle.mainBundle;
	NSURL		*srcURL = [mb URLForResource:@"Shaderdough_fairy" withExtension:@"fs"];
	NSURL		*filterURL = [mb URLForResource:@"City Lights" withExtension:@"fs"];
	
	//	make the scenes that will render ISF content (src + filter) to textures
	_srcScene = [[ISFMSLScene alloc] initWithDevice:RenderProperties.global.device];
	_filterScene = [[ISFMSLScene alloc] initWithDevice:RenderProperties.global.device];
	
	[_srcScene loadURL:srcURL];
	[_filterScene loadURL:filterURL];
	
	//	we're going to make a menu and populate it with every ISF we can find
	NSMenu			*tmpMenu = [[NSMenu alloc] init];
	tmpMenu.autoenablesItems = NO;
	uint32_t		failCount = 0;
	uint32_t		totalCount = 0;
	NSMenuItem		*tmpItem = nil;
	
	//	add the ISFs that are embedded in the app to the menu...
	tmpItem = [[NSMenuItem alloc] initWithTitle:@"Embedded ISFs:" action:nil keyEquivalent:@""];
	tmpItem.enabled = NO;
	[tmpMenu addItem:tmpItem];
	
	tmpItem = [[NSMenuItem alloc]
		initWithTitle:[srcURL.lastPathComponent stringByDeletingPathExtension]
		action:nil
		keyEquivalent:@""];
	tmpItem.representedObject = srcURL.path;
	[tmpMenu addItem:tmpItem];
	
	tmpItem = [[NSMenuItem alloc]
		initWithTitle:[filterURL.lastPathComponent stringByDeletingPathExtension]
		action:nil
		keyEquivalent:@""];
	tmpItem.representedObject = filterURL.path;
	[tmpMenu addItem:tmpItem];
	
	tmpItem = [[NSMenuItem alloc] initWithTitle:@"Other ISFs:" action:nil keyEquivalent:@""];
	tmpItem.enabled = NO;
	[tmpMenu addItem:tmpItem];
	
	//	get the array of all IFSs found on the system (in /Library/Graphics/ISF, ~/Library/Graphics/ISF)
	NSArray<NSString*>		*defaultISFPaths = GetArrayOfDefaultISFs(ISFMSLProto_All);
	
	
	//	cache all of these ISFs- this will compile them, and store the compiled shaders in the ISF cache on disk so you only have to do it once.
	NSLog(@"beginning caching");
	for (NSString * tmpPath in defaultISFPaths)	{
		NSURL			*tmpURL = [NSURL fileURLWithPath:tmpPath];
		if (tmpURL == nil)
			continue;
		
		//	if this ISF isn't an src or a filter, skip it
		ISFMSLDoc		*doc = [ISFMSLDoc createWithURL:tmpURL];
		switch (doc.type)	{
			case ISFMSLProto_None:
			case ISFMSLProto_Transition:
			case ISFMSLProto_All:
				continue;
			case ISFMSLProto_Source:
			case ISFMSLProto_Filter:
				//	intentionally blank
				break;
		}
		
		//	caching an ISF is as easy as requesting the bin from the cache- if it doesn't exist, it gets cached synchronously
		id<MTLDevice>		tmpDevice = [RenderProperties global].device;
		ISFMSLBinCacheObject		*cachedObj = [ISFMSLCache.primary
			getCachedISFAtURL:tmpURL
			forDevice:tmpDevice
			hint:ISFMSLCacheHint_TranspileIfDateDelta
			logErrorToDisk:YES];	//	if an ISF can't be compiled, a nice, human-readable error log is generated and placed in the "Error Logs" folder in the ISF cache directory
		if (cachedObj == nil)	{
			++failCount;
		}
		
		++totalCount;
		
		//	make a menu item for the ISF, stick it in the PUB so we can select different ISFs at runtime...
		tmpItem = [[NSMenuItem alloc]
			initWithTitle:[tmpPath.lastPathComponent stringByDeletingPathExtension]
			action:nil
			keyEquivalent:@""];
		tmpItem.representedObject = tmpPath;
		
		if (tmpItem != nil)
			[tmpMenu addItem:tmpItem];
	}
	NSLog(@"done caching");
	NSLog(@"**************** FAIL COUNT: %d",failCount);
	NSLog(@"**************** TOTAL PROCESSED: %d",totalCount);
	
	self.isfPUB.menu = tmpMenu;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.renderTimer = [NSTimer scheduledTimerWithTimeInterval:1./60. target:self selector:@selector(renderTimer:) userInfo:nil repeats:YES];
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[self.renderTimer invalidate];
}


- (IBAction) pubUsed:(NSPopUpButton *)sender	{
	NSLog(@"%s ... %@",__func__,sender);
	NSMenuItem		*item = sender.selectedItem;
	if (!item.enabled)
		return;
	//	get the path stored with the menu item
	NSString		*path = item.representedObject;
	NSURL		*url = [NSURL fileURLWithPath:path];
	//	make a doc from the path- this is very fast, and doesn't deal with any rendering-related resources (basically just string ops)
	ISFMSLDoc		*doc = [ISFMSLDoc createWithURL:url];
	//	if the doc's a src, tell the src scene to load it- if it's a filter, tell the filter scene to load it
	switch (doc.type)	{
		case ISFMSLProto_None:
		case ISFMSLProto_Transition:
		case ISFMSLProto_All:
			break;
		case ISFMSLProto_Source:
			[self.srcScene loadURL:url];
			break;
		case ISFMSLProto_Filter:
			[self.filterScene loadURL:url];
			break;
	}
}


- (void) renderTimer:(NSTimer *)t	{
	//NSLog(@"%s",__func__);
	NSSize		renderSize = NSMakeSize(1920,1080);
	
	id<VVMTLTextureImage>		texToDraw = nil;
	id<MTLCommandBuffer>		cmdBuffer = [RenderProperties.global.renderQueue commandBuffer];
	
	//	have the src scene render a texture
	id<VVMTLTextureImage>		srcTex = [self.srcScene createAndRenderToTextureSized:renderSize inCommandBuffer:cmdBuffer];
	
	id<VVMTLTextureImage>		filterTex = nil;
	if (srcTex != nil)	{
		//	make an ISFMSLSceneVal from the texture, pass it to the filter scene
		id<ISFMSLSceneVal>		inputImageVal = [ISFMSLSceneVal createWithImg:srcTex];
		[self.filterScene setValue:inputImageVal forInputNamed:@"inputImage"];
		//	tell the filter scene to render to a texture
		filterTex = [self.filterScene createAndRenderToTextureSized:renderSize inCommandBuffer:cmdBuffer];
	}
	
	if (filterTex != nil)
		texToDraw = filterTex;
	else if (srcTex != nil)
		texToDraw = srcTex;
	
	//	tell the preview to draw.  this will draw the frame currently held by the preview- the frame we just 
	//	rendered won't get drawn until after the cmd buffer completes and it gets passed to the texture.
	[self.preview drawInCmdBuffer:cmdBuffer];
	
	//	when the cmd buffer finishes, pass the tex we want to draw in it to the preview (which will draw it in the next cmd buffer)
	[cmdBuffer addCompletedHandler:^(id<MTLCommandBuffer> completed)	{
		if (texToDraw != nil)
			self.preview.imgBuffer = texToDraw;
	}];
	[cmdBuffer commit];
}


@end
