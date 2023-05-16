//
//  ISFMTLCacheObject.m
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import "ISFMTLCacheObject.h"
//#import <VVCore/VVCore.h>
#import "ISFMSLNSStringAdditions.h"

#import "ISFMTLCache.h"

#include "VVISF.hpp"




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

@property (strong) NSMutableArray<ISFMTLBinCacheObject*> * binCache;

@end




@implementation ISFMTLCacheObject


#pragma mark - init/dealloc


- (instancetype) init	{
	self = [super init];
	if (self != nil)	{
		_name = nil;
		_path = nil;
		_glslFragShaderHash = nil;
		_modDate = nil;
		_mslVertShader = nil;
		_vertFuncName = nil;
		_mslFragShader = nil;
		_fragFuncName = nil;
		_vertBufferVarIndexDict = nil;
		_vertTextureVarIndexDict = nil;
		_vertSamplerVarIndexDict = nil;
		_fragBufferVarIndexDict = nil;
		_fragTextureVarIndexDict = nil;
		_fragSamplerVarIndexDict = nil;
		_maxUBOSize = 0;
		_vtxFuncMaxBufferIndex = 0;
		
		_binCache = [[NSMutableArray alloc] init];
	}
	return self;
}
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
		_glslFragShaderHash = tmpString;
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
		
		_binCache = [[NSMutableArray alloc] init];
		
		//_device = nil;
		//
		//_vtxLib = nil;
		//_frgLib = nil;
		//_vtxFunc = nil;
		//_frgFunc = nil;
	}
	
	return self;
}


- (NSString *) description	{
	return [NSString stringWithFormat:@"<ISFMTLCacheObject %@ %p>",self.name,self];
}


#pragma mark - NSCoding


- (void) encodeWithCoder:(NSCoder *)coder	{
	if (coder == nil)
		return;
	
	if (_name != nil)
		[coder encodeObject:_name forKey:kISFMTLCacheObject_name];
	if (_path != nil)
		[coder encodeObject:_path forKey:kISFMTLCacheObject_path];
	if (_glslFragShaderHash != nil)
		[coder encodeObject:_glslFragShaderHash forKey:kISFMTLCacheObject_glslShaderHash];
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


#pragma mark - frontend


- (ISFMTLBinCacheObject *) binCacheForDevice:(id<MTLDevice>)inDevice	{
	if (inDevice == nil)
		return nil;
	
	for (ISFMTLBinCacheObject * cacheObj in _binCache)	{
		if (cacheObj.device == inDevice)
			return cacheObj;
	}
	
	//	...if we're here, we don't have any cached objects for that device- we need to make one, post-haste!
	
	ISFMTLBinCacheObject		*returnMe = [[ISFMTLBinCacheObject alloc] initWithParent:self device:inDevice];
	if (returnMe != nil)
		[_binCache addObject:returnMe];
	
	return returnMe;
}


- (BOOL) modDateChecksum	{
	NSString		*fullPath = [self.path stringByExpandingTildeInPath];
	//NSString		*fullPathHash = [fullPath isfMD5String];
	
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSDictionary		*fileAttribs = [fm attributesOfItemAtPath:fullPath error:nil];
	NSDate				*modDate = (fileAttribs == nil) ? nil : [fileAttribs objectForKey:NSFileModificationDate];
	NSDate				*cachedModDate = self.modDate;
	if ((modDate==nil && cachedModDate!=nil)
	|| (modDate!=nil && cachedModDate==nil)
	|| (modDate!=nil && cachedModDate!=nil && ![modDate isEqualTo:cachedModDate]))
	{
		return NO;
	}
	
	return YES;
}
- (BOOL) fragShaderHashChecksum	{
	//	create an ISFDoc from the passed URL
	NSString		*fullPath = [self.path stringByExpandingTildeInPath];
	const char		*inURLPathCStr = fullPath.UTF8String;
	//std::string		inURLPathStr { inURLPathCStr };
	VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, true);
	if (doc == nullptr)	{
		NSLog(@"ERR: unable to make doc from ISF %@ (%s)",fullPath,__func__);
		return NO;
	}
	
	std::string		glslFragSrc;
	std::string		glslVertSrc;
	
	//doc->generateShaderSource(&glslFragSrc, &glslVertSrc, GLVersion_2, false);
	doc->generateShaderSource(&glslFragSrc, &glslVertSrc, VVISF::GLVersion_4, true);
	NSString		*fragSrcHash = [[NSString stringWithUTF8String:glslFragSrc.c_str()] isfMD5String];
	NSString		*cachedFragSrcHash = self.glslFragShaderHash;
	if ((fragSrcHash==nil && cachedFragSrcHash!=nil)
	|| (fragSrcHash!=nil && cachedFragSrcHash==nil)
	|| (fragSrcHash!=nil && cachedFragSrcHash!=nil && ![fragSrcHash isEqualToString:cachedFragSrcHash]))
	{
		return NO;
	}
	
	return YES;
}


@end
