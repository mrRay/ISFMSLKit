//
//  ISFMSLCacheObject.m
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import "ISFMSLCacheObject.h"
//#import <VVCore/VVCore.h>
#import "ISFMSLNSStringAdditions.h"

#import "ISFMSLCache.h"

#include "VVISF.hpp"




NSString * const kISFMSLCacheObject_name = @"kISFMSLCacheObject_name";
NSString * const kISFMSLCacheObject_path = @"kISFMSLCacheObject_path";
NSString * const kISFMSLCacheObject_glslShaderHash = @"kISFMSLCacheObject_glslShaderHash";
NSString * const kISFMSLCacheObject_modDate = @"kISFMSLCacheObject_modDate";
NSString * const kISFMSLCacheObject_mslVertShader = @"kISFMSLCacheObject_mslVertShader";
NSString * const kISFMSLCacheObject_vertFuncName = @"kISFMSLCacheObject_vertFuncName";
NSString * const kISFMSLCacheObject_mslFragShader = @"kISFMSLCacheObject_mslFragShader";
NSString * const kISFMSLCacheObject_fragFuncName = @"kISFMSLCacheObject_fragFuncName";
NSString * const kISFMSLCacheObject_vertBufferVarIndexDict = @"kISFMSLCacheObject_vertBufferVarIndexDict";
NSString * const kISFMSLCacheObject_vertTextureVarIndexDict = @"kISFMSLCacheObject_vertTextureVarIndexDict";
NSString * const kISFMSLCacheObject_vertSamplerVarIndexDict = @"kISFMSLCacheObject_vertSamplerVarIndexDict";
NSString * const kISFMSLCacheObject_fragBufferVarIndexDict = @"kISFMSLCacheObject_fragBufferVarIndexDict";
NSString * const kISFMSLCacheObject_fragTextureVarIndexDict = @"kISFMSLCacheObject_fragTextureVarIndexDict";
NSString * const kISFMSLCacheObject_fragSamplerVarIndexDict = @"kISFMSLCacheObject_fragSamplerVarIndexDict";
NSString * const kISFMSLCacheObject_maxUBOSize = @"kISFMSLCacheObject_maxUBOSize";
NSString * const kISFMSLCacheObject_vtxFuncMaxBufferIndex = @"kISFMSLCacheObject_vtxFuncMaxBufferIndex";




@interface ISFMSLCacheObject ()

//@property (readwrite,strong) id<MTLLibrary> vtxLib;
//@property (readwrite,strong) id<MTLLibrary> frgLib;
//@property (readwrite,strong) id<MTLFunction> vtxFunc;
//@property (readwrite,strong) id<MTLFunction> frgFunc;

@property (strong) NSMutableArray<ISFMSLBinCacheObject*> * binCache;

@end




@implementation ISFMSLCacheObject


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
		
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_name];
		_name = tmpString;
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_path];
		_path = tmpString;
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_glslShaderHash];
		_glslFragShaderHash = tmpString;
		tmpDate = [n decodeObjectForKey:kISFMSLCacheObject_modDate];
		_modDate = tmpDate;
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_mslVertShader];
		_mslVertShader = tmpString;
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_vertFuncName];
		_vertFuncName = tmpString;
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_mslFragShader];
		_mslFragShader = tmpString;
		tmpString = [n decodeObjectForKey:kISFMSLCacheObject_fragFuncName];
		_fragFuncName = tmpString;
		tmpDict = [n decodeObjectForKey:kISFMSLCacheObject_vertBufferVarIndexDict];
		_vertBufferVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMSLCacheObject_vertTextureVarIndexDict];
		_vertTextureVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMSLCacheObject_vertSamplerVarIndexDict];
		_vertSamplerVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMSLCacheObject_fragBufferVarIndexDict];
		_fragBufferVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMSLCacheObject_fragTextureVarIndexDict];
		_fragTextureVarIndexDict = tmpDict;
		tmpDict = [n decodeObjectForKey:kISFMSLCacheObject_fragSamplerVarIndexDict];
		_fragSamplerVarIndexDict = tmpDict;
		tmpNum = [n decodeObjectForKey:kISFMSLCacheObject_maxUBOSize];
		_maxUBOSize = tmpNum.intValue;
		tmpNum = [n decodeObjectForKey:kISFMSLCacheObject_vtxFuncMaxBufferIndex];
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
	return [NSString stringWithFormat:@"<ISFMSLCacheObject %@ %p>",self.name,self];
}


#pragma mark - NSCoding


- (void) encodeWithCoder:(NSCoder *)coder	{
	if (coder == nil)
		return;
	
	if (_name != nil)
		[coder encodeObject:_name forKey:kISFMSLCacheObject_name];
	if (_path != nil)
		[coder encodeObject:_path forKey:kISFMSLCacheObject_path];
	if (_glslFragShaderHash != nil)
		[coder encodeObject:_glslFragShaderHash forKey:kISFMSLCacheObject_glslShaderHash];
	if (_modDate != nil)
		[coder encodeObject:_modDate forKey:kISFMSLCacheObject_modDate];
	if (_mslVertShader != nil)
		[coder encodeObject:_mslVertShader forKey:kISFMSLCacheObject_mslVertShader];
	if (_vertFuncName != nil)
		[coder encodeObject:_vertFuncName forKey:kISFMSLCacheObject_vertFuncName];
	if (_mslFragShader != nil)
		[coder encodeObject:_mslFragShader forKey:kISFMSLCacheObject_mslFragShader];
	if (_fragFuncName != nil)
		[coder encodeObject:_fragFuncName forKey:kISFMSLCacheObject_fragFuncName];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_vertBufferVarIndexDict forKey:kISFMSLCacheObject_vertBufferVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_vertTextureVarIndexDict forKey:kISFMSLCacheObject_vertTextureVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_vertSamplerVarIndexDict forKey:kISFMSLCacheObject_vertSamplerVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_fragBufferVarIndexDict forKey:kISFMSLCacheObject_fragBufferVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_fragTextureVarIndexDict forKey:kISFMSLCacheObject_fragTextureVarIndexDict];
	if (_vertBufferVarIndexDict != nil)
		[coder encodeObject:_fragSamplerVarIndexDict forKey:kISFMSLCacheObject_fragSamplerVarIndexDict];
	
	[coder encodeObject:@(_maxUBOSize) forKey:kISFMSLCacheObject_maxUBOSize];
	[coder encodeObject:@(_vtxFuncMaxBufferIndex) forKey:kISFMSLCacheObject_vtxFuncMaxBufferIndex];
}


#pragma mark - frontend


- (ISFMSLBinCacheObject *) binCacheForDevice:(id<MTLDevice>)inDevice	{
	if (inDevice == nil)
		return nil;
	
	for (ISFMSLBinCacheObject * cacheObj in _binCache)	{
		if (cacheObj.device == inDevice)
			return cacheObj;
	}
	
	//	...if we're here, we don't have any cached objects for that device- we need to make one, post-haste!
	
	ISFMSLBinCacheObject		*returnMe = [[ISFMSLBinCacheObject alloc] initWithParent:self device:inDevice];
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
