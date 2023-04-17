//
//  ISFMTLCacheObject.m
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import "ISFMTLCacheObject.h"
#import <VVCore/VVCore.h>

#import "ISFMTLCache.h"




NSString * const kISFMTLCacheObject_name = @"kISFMTLCacheObject_name";
NSString * const kISFMTLCacheObject_path = @"kISFMTLCacheObject_path";
NSString * const kISFMTLCacheObject_glslShaderHash = @"kISFMTLCacheObject_glslShaderHash";
NSString * const kISFMTLCacheObject_modDate = @"kISFMTLCacheObject_modDate";
NSString * const kISFMTLCacheObject_mslVertShader = @"kISFMTLCacheObject_mslVertShader";
NSString * const kISFMTLCacheObject_vertFuncName = @"kISFMTLCacheObject_vertFuncName";
NSString * const kISFMTLCacheObject_mslFragShader = @"kISFMTLCacheObject_mslFragShader";
NSString * const kISFMTLCacheObject_fragFuncName = @"kISFMTLCacheObject_fragFuncName";
NSString * const kISFMTLCacheObject_vertBufferVarIndexDict = @"kISFMTLCacheObject_vertBufferVarIndexDict";
NSString * const kISFMTLCacheObject_vertTextureVarIndexDict = @"kISFMTLCacheObject_vertTextureVarIndexDict";
NSString * const kISFMTLCacheObject_vertSamplerVarIndexDict = @"kISFMTLCacheObject_vertSamplerVarIndexDict";
NSString * const kISFMTLCacheObject_fragBufferVarIndexDict = @"kISFMTLCacheObject_fragBufferVarIndexDict";
NSString * const kISFMTLCacheObject_fragTextureVarIndexDict = @"kISFMTLCacheObject_fragTextureVarIndexDict";
NSString * const kISFMTLCacheObject_fragSamplerVarIndexDict = @"kISFMTLCacheObject_fragSamplerVarIndexDict";
NSString * const kISFMTLCacheObject_maxUBOSize = @"kISFMTLCacheObject_maxUBOSize";
NSString * const kISFMTLCacheObject_vtxFuncMaxBufferIndex = @"kISFMTLCacheObject_vtxFuncMaxBufferIndex";




@interface ISFMTLCacheObject ()

//@property (readwrite,strong) id<MTLLibrary> vtxLib;
//@property (readwrite,strong) id<MTLLibrary> frgLib;
//@property (readwrite,strong) id<MTLFunction> vtxFunc;
//@property (readwrite,strong) id<MTLFunction> frgFunc;


@end




@implementation ISFMTLCacheObject


#pragma mark - init/dealloc


- (instancetype) initWithCoder:(NSCoder *)n	{
	self = [super init];
	
	//	if the URL's nil, bail
	if (n == nil)
		return nil;
	
	if (self != nil)	{
		NSString		*tmpString = nil;
		//NSURL			*tmpURL = nil;
		NSDate			*tmpDate = nil;
		NSDictionary	*tmpDict = nil;
		NSNumber		*tmpNum = nil;
		
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_name];
		_name = tmpString;
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_path];
		_path = tmpString;
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_glslShaderHash];
		_glslShaderHash = tmpString;
		tmpDate = [n decodeObjectForKey:kISFMTLCacheObject_modDate];
		_modDate = tmpDate;
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_mslVertShader];
		_mslVertShader = tmpString;
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_vertFuncName];
		_vertFuncName = tmpString;
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_mslFragShader];
		_mslFragShader = tmpString;
		tmpString = [n decodeObjectForKey:kISFMTLCacheObject_fragFuncName];
		_fragFuncName = tmpString;
		tmpDict = [n decodeObjectForKey:kISFMTLCacheObject_vertBufferVarIndexDict];
		_vertBufferVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMTLCacheObject_vertTextureVarIndexDict];
		_vertTextureVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMTLCacheObject_vertSamplerVarIndexDict];
		_vertSamplerVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMTLCacheObject_fragBufferVarIndexDict];
		_fragBufferVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMTLCacheObject_fragTextureVarIndexDict];
		_fragTextureVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMTLCacheObject_fragSamplerVarIndexDict];
		_fragSamplerVarIndexDict = tmpDict;
		tmpNum = [n decodeObjectForKey:kISFMTLCacheObject_maxUBOSize];
		_maxUBOSize = tmpNum.intValue;
		tmpNum = [n decodeObjectForKey:kISFMTLCacheObject_vtxFuncMaxBufferIndex];
		_vtxFuncMaxBufferIndex = tmpNum.intValue;
		
		_device = nil;
		
		_vtxLib = nil;
		_frgLib = nil;
		_vtxFunc = nil;
		_frgFunc = nil;
	}
	
	return self;
}


#pragma mark - NSCoding


- (void) encodeWithCoder:(NSCoder *)coder	{
	if (coder == nil)
		return;
	
	if (_name != nil)
		[coder encodeObject:_name forKey:kISFMTLCacheObject_name];
	if (_path != nil)
		[coder encodeObject:_path forKey:kISFMTLCacheObject_path];
	if (_glslShaderHash != nil)
		[coder encodeObject:_glslShaderHash forKey:kISFMTLCacheObject_glslShaderHash];
	if (_modDate != nil)
		[coder encodeObject:_modDate forKey:kISFMTLCacheObject_modDate];
	if (_mslVertShader != nil)
		[coder encodeObject:_mslVertShader forKey:kISFMTLCacheObject_mslVertShader];
	if (_vertFuncName != nil)
		[coder encodeObject:_vertFuncName forKey:kISFMTLCacheObject_vertFuncName];
	if (_mslFragShader != nil)
		[coder encodeObject:_mslFragShader forKey:kISFMTLCacheObject_mslFragShader];
	if (_fragFuncName != nil)
		[coder encodeObject:_fragFuncName forKey:kISFMTLCacheObject_fragFuncName];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_vertBufferVarIndexDict forKey:kISFMTLCacheObject_vertBufferVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_vertTextureVarIndexDict forKey:kISFMTLCacheObject_vertTextureVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_vertSamplerVarIndexDict forKey:kISFMTLCacheObject_vertSamplerVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_fragBufferVarIndexDict forKey:kISFMTLCacheObject_fragBufferVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_fragTextureVarIndexDict forKey:kISFMTLCacheObject_fragTextureVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_fragSamplerVarIndexDict forKey:kISFMTLCacheObject_fragSamplerVarIndexDict];
	
	[coder encodeObject:@(_maxUBOSize) forKey:kISFMTLCacheObject_maxUBOSize];
	[coder encodeObject:@(_vtxFuncMaxBufferIndex) forKey:kISFMTLCacheObject_vtxFuncMaxBufferIndex];
}


#pragma mark - key-val overrides


@synthesize device=_device;
- (void) setDevice:(id<MTLDevice>)n	{
	//	if the device changed, we definitely need to purge
	BOOL			purge = YES;
	if ((_device==nil && n==nil) || (_device!=nil && n!=nil && /*[_device isEqualTo:n]*/ _device==n))
		purge = NO;
	
	_device = n;
	
	void (^PurgeBlock)(void) = ^()	{
		self->_vtxLib = nil;
		self->_vtxFunc = nil;
		self->_frgLib = nil;
		self->_frgFunc = nil;
		self->_archive = nil;
	};
	
	if (purge)	{
		PurgeBlock();
	}
	
	NSError			*nsErr = nil;
	
	if (_vtxLib == nil)	{
		_vtxLib = [_device newLibraryWithSource:_mslVertShader options:nil error:&nsErr];
		if (_vtxLib == nil)	{
			NSLog(@"ERR: unable to make lib from vtx src %@, bailing (%@)",_name,nsErr);
			PurgeBlock();
			return;
		}
	}
	
	if (_frgLib == nil)	{
		_frgLib = [_device newLibraryWithSource:_mslFragShader options:nil error:&nsErr];
		if (_frgLib == nil)	{
			NSLog(@"ERR: unable to make lib from frg src %@, bailing (%@)",_name,nsErr);
			PurgeBlock();
			return;
		}
	}
	
	if (_vtxFunc == nil)	{
		_vtxFunc = [_vtxLib newFunctionWithName:_vertFuncName];
		if (_vtxFunc == nil)	{
			NSLog(@"ERR: unable to make func from vtx lib %@, bailing",_name);
			PurgeBlock();
			return;
		}
	}
	
	if (_frgFunc == nil)	{
		_frgFunc = [_frgLib newFunctionWithName:_fragFuncName];
		if (_frgFunc == nil)	{
			NSLog(@"ERR: unable to make func from frg lib %@, bailing",_name);
			PurgeBlock();
			return;
		}
	}
	
	if (_archive == nil)	{
		NSURL			*binaryArchiveDir = [NSURL fileURLWithPath:self.parentCache.path];
		binaryArchiveDir = [binaryArchiveDir URLByAppendingPathComponent:@"BinaryArchives"];
		NSString		*fullPathHash = [self.path md5String];
		NSURL			*binaryArchiveURL = [binaryArchiveDir URLByAppendingPathComponent:fullPathHash];
		//NSLog(@"binaryArchiveURL is %@",binaryArchiveURL.path);
		MTLBinaryArchiveDescriptor		*archiveDesc = [[MTLBinaryArchiveDescriptor alloc] init];
		archiveDesc.url = nil;
		_archive = [self.device newBinaryArchiveWithDescriptor:archiveDesc error:&nsErr];
		
		//	make a vertex descriptor that describes the vertex data we'll be passing to the shader
		MTLVertexDescriptor		*vtxDesc = [MTLVertexDescriptor vertexDescriptor];
		
		vtxDesc.attributes[0].format = MTLVertexFormatFloat4;
		vtxDesc.attributes[0].offset = 0;
		vtxDesc.attributes[0].bufferIndex = _vtxFuncMaxBufferIndex + 1;
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
			NSLog(@"ERR: problem adding pipeline A to bin arch for %@ (%@), %s",self.path,nsErr,__func__);
			PurgeBlock();
			return;
		}
		if (![_archive addRenderPipelineFunctionsWithDescriptor:passDesc_float error:&nsErr] || nsErr != nil)	{
			NSLog(@"ERR: problem adding pipeline B to bin arch for %@ (%@), %s",self.path,nsErr,__func__);
			PurgeBlock();
			return;
		}
		
		//	write the binary archive to disk
		if (![_archive serializeToURL:binaryArchiveURL error:&nsErr])	{
			NSLog(@"ERR: problem serializing binary archive for %@ to disk (%@), %s",self.path,nsErr,__func__);
			PurgeBlock();
			return;
		}
	}
}
- (id<MTLDevice>) device	{
	return _device;
}


@end
