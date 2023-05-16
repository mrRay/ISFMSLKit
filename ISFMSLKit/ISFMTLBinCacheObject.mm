//
//  ISFMTLBinCacheObject.m
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/18/23.
//

#import "ISFMTLBinCacheObject.h"
//#import <VVCore/VVCore.h>

//#import "ISFMTLCacheObject.h"
#import "ISFMTLCache.h"

#import "ISFMSLNSStringAdditions.h"

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <regex>
#include <typeinfo>




using namespace std;



@implementation ISFMTLBinCacheObject


- (instancetype) initWithParent:(ISFMTLCacheObject *)inParent device:(id<MTLDevice>)inDevice	{
	//NSLog(@"%s ... %@, %@",__func__,inParent,inDevice.name);
	self = [super init];
	
	if (inParent == nil)	{
		NSLog(@"ERR: parent nil in %s",__func__);
		self = nil;
	}
	if (inDevice == nil)	{
		NSLog(@"ERR: device nil for parent %@ in %s",inParent,__func__);
		self = nil;
	}
	
	if (self != nil)	{
		_device = inDevice;
		_parentObj = inParent;
		
		_vtxLib = nil;
		_frgLib = nil;
		_vtxFunc = nil;
		_frgFunc = nil;
		_archive = nil;
		
		
		NSError			*nsErr = nil;
		
		_vtxLib = [_device newLibraryWithSource:_parentObj.mslVertShader options:nil error:&nsErr];
		if (_vtxLib == nil)	{
			NSLog(@"ERR: unable to make lib from vtx src %@, bailing (%@)",_parentObj,nsErr);
			self = nil;
			return self;
		}
		
		_frgLib = [_device newLibraryWithSource:_parentObj.mslFragShader options:nil error:&nsErr];
		if (_frgLib == nil)	{
			NSLog(@"ERR: unable to make lib from frg src %@, bailing (%@)",_parentObj,nsErr);
			self = nil;
			return self;
		}
		
		_vtxFunc = [_vtxLib newFunctionWithName:_parentObj.vertFuncName];
		if (_vtxFunc == nil)	{
			NSLog(@"ERR: unable to make func from vtx lib %@, bailing",_parentObj);
			self = nil;
			return self;
		}
		
		_frgFunc = [_frgLib newFunctionWithName:_parentObj.fragFuncName];
		if (_frgFunc == nil)	{
			NSLog(@"ERR: unable to make func from frg lib %@, bailing",_parentObj);
			self = nil;
			return self;
		}
		
		//	it needs to be safe to assume that the bin cache on disk matches the metadata stored in the parent object's cache.  if it isn't, then that needs to be fixed in the cache- not here.
		
		_archive = nil;
		{
			NSURL		*binaryArchivesDir = _parentObj.parentCache.binaryArchivesDirectory;
			
			NSString	*mtlDeviceDirName = [_device.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSURL		*deviceDir = [binaryArchivesDir URLByAppendingPathComponent:mtlDeviceDirName];
			
			NSString	*fullPathHash = [_parentObj.path isfMD5String];
			NSURL		*archiveURL = [deviceDir URLByAppendingPathComponent:fullPathHash];
			//NSLog(@"\t\tarchiveURL is %@",archiveURL.path);
			
			//	if there's a binary archive on disk, try loading it
			BOOL		archiveExists = [[NSFileManager defaultManager] fileExistsAtPath:archiveURL.path];
			if (archiveExists)	{
				MTLBinaryArchiveDescriptor		*archiveDesc = [[MTLBinaryArchiveDescriptor alloc] init];
				archiveDesc.url = archiveURL;
				_archive = [self.device newBinaryArchiveWithDescriptor:archiveDesc error:&nsErr];
				if (_archive == nil || nsErr != nil)	{
					NSLog(@"ERR: (%@) making bin arch for device (%@) with parent (%@) in %s",nsErr,inDevice,inParent,__func__);
					_archive = nil;
				}
			}
			
			//	if we're here and the archive's still nil- either because there wasn't one on disk or there was but it couldn't be loaded- we need to create one
			if (_archive == nil)	{
				//NSLog(@"\t\tcreating & serializing binary cache...");
				//	make sure the device directory exists, create it if it doesn't
				if (![[NSFileManager defaultManager] fileExistsAtPath:deviceDir.path])
					[[NSFileManager defaultManager] createDirectoryAtURL:deviceDir withIntermediateDirectories:YES attributes:nil error:nil];
				
				//	create a new, empty, binary archive
				MTLBinaryArchiveDescriptor		*archiveDesc = [[MTLBinaryArchiveDescriptor alloc] init];
				archiveDesc.url = nil;
				_archive = [self.device newBinaryArchiveWithDescriptor:archiveDesc error:&nsErr];
				
				//	make a vertex descriptor that describes the vertex data we'll be passing to the shader
				MTLVertexDescriptor		*vtxDesc = [MTLVertexDescriptor vertexDescriptor];
				
				vtxDesc.attributes[0].format = MTLVertexFormatFloat4;
				vtxDesc.attributes[0].offset = 0;
				vtxDesc.attributes[0].bufferIndex = _parentObj.vtxFuncMaxBufferIndex + 1;
				vtxDesc.layouts[1].stride = sizeof(float) * 4;
				vtxDesc.layouts[1].stepFunction = MTLVertexStepFunctionPerVertex;
				vtxDesc.layouts[1].stepRate = 1;
				
				//	make pipeline descriptors for all possible states we need to describe (8bit & float)
				MTLRenderPipelineDescriptor		*passDesc_8bit = [[MTLRenderPipelineDescriptor alloc] init];
				MTLRenderPipelineDescriptor		*passDesc_float = [[MTLRenderPipelineDescriptor alloc] init];
				for (MTLRenderPipelineDescriptor * passDesc in @[ passDesc_8bit, passDesc_float ])	{
					passDesc.vertexFunction = _vtxFunc;
					passDesc.fragmentFunction = _frgFunc;
					passDesc.vertexDescriptor = vtxDesc;
				}
				passDesc_8bit.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
				passDesc_float.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA32Float;
				
				if (![_archive addRenderPipelineFunctionsWithDescriptor:passDesc_8bit error:&nsErr] || nsErr != nil)	{
					NSLog(@"ERR: problem adding pipeline A to bin arch for %@ (%@), %s",_parentObj,nsErr,__func__);
					self = nil;
					return self;
				}
				if (![_archive addRenderPipelineFunctionsWithDescriptor:passDesc_float error:&nsErr] || nsErr != nil)	{
					NSLog(@"ERR: problem adding pipeline B to bin arch for %@ (%@), %s",_parentObj,nsErr,__func__);
					self = nil;
					return self;
				}
				
				//	write the binary archive to disk
				if (![_archive serializeToURL:archiveURL error:&nsErr])	{
					NSLog(@"ERR: problem serializing binary archive for %@ to disk (%@), %s",_parentObj,nsErr,__func__);
					self = nil;
					return self;
				}
			}
			
		}
	}
	return self;
}


- (NSString *) description	{
	return [NSString stringWithFormat:@"<ISFMTLBinCacheObject (%@) %@ %p>",_parentObj,_device.name,self];
}


@end
