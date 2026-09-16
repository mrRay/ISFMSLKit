//
//  ISFMSLCacheObject.m
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import "ISFMSLCacheObject.h"
//#import <VVCore/VVCore.h>
#import "ISFMSLNSStringAdditions.h"

#include "GLSLangValidatorLib.hpp"
#include "SPIRVCrossLib.hpp"

#import "ISFMSLCache.h"
#import "ISFMSLCache_priv.h"
#include "ISFMSLFuncSignature.hpp"

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <regex>
#include <typeinfo>

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
NSString * const kISFMSLCacheObject_hasCustomVertShader = @"kISFMSLCacheObject_hasCustomVertShader";




@interface ISFMSLCacheObject ()

//@property (readwrite,strong) id<MTLLibrary> vtxLib;
//@property (readwrite,strong) id<MTLLibrary> frgLib;
//@property (readwrite,strong) id<MTLFunction> vtxFunc;
//@property (readwrite,strong) id<MTLFunction> frgFunc;

@property (strong) NSMutableArray<ISFMSLBinCacheObject*> * binCache;

@end




//	YES if the passed cached dict describes a buffer arg that the render path can't bind- the decode-time half of ISFMSLFindUnboundArgs()
static BOOL BufferVarIndexDictHasUnbindableVar(NSDictionary *inDict)	{
	for (NSString * varName in inDict)	{
		if (![varName isEqualToString:@"VVISF_UNIFORMS&"])
			return YES;
	}
	return NO;
}




@implementation ISFMSLCacheObject


#pragma mark - init/dealloc


+ (instancetype) createWithCache:(ISFMSLCache *)inParent url:(NSURL *)inURL	{
	return [[ISFMSLCacheObject alloc] initWithCache:inParent url:inURL];
}
- (instancetype) initWithCache:(ISFMSLCache *)inParent url:(NSURL *)inURL	{
	//NSLog(@"%s ... %@",__func__,inURL.lastPathComponent);
	self = [super init];
	
	if (inParent == nil)
		self = nil;
	if (inURL == nil)
		self = nil;
	
	if (self != nil)	{
		_name = @"";
		_path = @"";
		_glslFragShaderHash = @"";
		//_modDate = nil;
		_mslVertShader = nil;
		_vertFuncName = @"";
		_mslFragShader = nil;
		_fragFuncName = @"";
		_vertBufferVarIndexDict = @{};
		_vertTextureVarIndexDict = @{};
		_vertSamplerVarIndexDict = @{};
		_fragBufferVarIndexDict = @{};
		_fragTextureVarIndexDict = @{};
		_fragSamplerVarIndexDict = @{};
		_maxUBOSize = 0;
		_vtxFuncMaxBufferIndex = 0;
		_hasCustomVertShader = NO;
		
		self.parentCache = inParent;
		
		//	make sure there's a file at the path
		NSString			*fullPath = [inURL.path stringByExpandingTildeInPath];
		NSFileManager		*fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:fullPath])	{
			NSLog(@"ERR: file doesn't exist at %@ (%s)",inURL,__func__);
			self = nil;
			return self;
		}
		
		self.path = fullPath;
		
		//	get the mod date of the file at the path- if we can't, bail, because a cache is only useful if we can check for modifications
		NSDictionary		*fileAttribs = [fm attributesOfItemAtPath:fullPath error:nil];
		NSDate				*modDate = (fileAttribs == nil) ? nil : [fileAttribs objectForKey:NSFileModificationDate];
		if (modDate == nil)	{
			NSLog(@"ERR: file mod date doesn't exist at %@ (%s)",inURL,__func__);
			self = nil;
			return self;
		}
		
		self.modDate = modDate;
		
		//	local path string (uses "~" to abbreviate the home directory if possible)
		//NSString		*fullPathHash = [fullPath isfMD5String];
		
		
		//	create an ISFDoc from the passed URL
		const char		*inURLPathCStr = fullPath.UTF8String;
		//std::string		inURLPathStr { inURLPathCStr };
		#if DEBUG
		VVISF::ISFDocRef		doc;
		try	{
			doc = VVISF::CreateISFDocRef(inURLPathCStr, true);
		}
		catch (const VVISF::ISFErr & isfErr)	{
			NSLog(@"ERR: unable to make doc from ISF %@ (%s) - %s",fullPath,__func__,isfErr.getTypeString().c_str());
			doc = nullptr;
		}
		#else
		VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, false);
		#endif
		if (doc == nullptr)	{
			NSLog(@"ERR: unable to make doc from ISF %@ (%s)",fullPath,__func__);
			self = nil;
			return self;
		}
		
		_hasCustomVertShader = doc->hasCustomVertShader();
		
		//NSString		*filename = [inURL URLByDeletingPathExtension].lastPathComponent;
		std::string			raw_filename = std::filesystem::path(inURLPathCStr).stem().string();
		ISFMSLEntryPointNames		entryPointNames = ISFMSLEntryPointNamesForPath(std::string(inURLPathCStr));
		
		self.name = [NSString stringWithUTF8String:raw_filename.c_str()];
		
		//NSDate			*isfDocDate = [NSDate date];
		
		std::string		glslFragSrc;
		std::string		glslVertSrc;
		
		//doc->generateShaderSource(&glslFragSrc, &glslVertSrc, GLVersion_2, false);
		doc->generateShaderSource(&glslFragSrc, &glslVertSrc, VVISF::GLVersion_4, true);
		//std::cout << "***************************************************************" << std::endl;
		//std::cout << glslVertSrc << std::endl;
		//std::cout << "***************************************************************" << std::endl;
		//std::cout << glslFragSrc << std::endl;
		//std::cout << "***************************************************************" << std::endl;
		//std::cout << "***************************************************************" << std::endl;
		//std::cout << "***************************************************************" << std::endl;
		//std::cout << "***************************************************************" << std::endl;
		
		//NSDate			*glslSourceDate = [NSDate date];
		
		//NSLog(@"\t\tsizeof(ISFShaderRenderInfo) is %d, sizeof(ISFShaderImgInfo) is %d",sizeof(VVISF::ISFShaderRenderInfo),sizeof(VVISF::ISFShaderImgInfo));
		//NSLog(@"\t\tmaxUBOSize returned by libISFGLSLGenerator is %d",maxUboSize);
		
		NSString		*fragSrcHash = [[NSString stringWithUTF8String:glslFragSrc.c_str()] isfMD5String];
		
		std::vector<uint32_t>	outSPIRVVtxData;
		std::vector<uint32_t>	outSPIRVFrgData;
		std::string		glslVertErrString;
		std::string		glslFragErrString;
		if (!ConvertGLSLVertShaderToSPIRV(glslVertSrc, outSPIRVVtxData, glslVertErrString))	{
			NSLog(@"ERR: unable to convert vert shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
			//self = nil;
			return self;
		}
		
		if (!ConvertGLSLFragShaderToSPIRV(glslFragSrc, outSPIRVFrgData, glslFragErrString))	{
			NSLog(@"ERR: unable to convert frag shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
			//self = nil;
			return self;
		}
		
		//NSDate			*transpiledDate = [NSDate date];
		
		
		const std::string &		fragFuncName = entryPointNames.frag;
		const std::string &		vertFuncName = entryPointNames.vert;
		std::string		outMSLVtxString;
		std::string		outMSLFrgString;
		std::string		outMSLVtxErrString;
		std::string		outMSLFrgErrString;
		if (outSPIRVVtxData.size()<1 || !ConvertVertSPIRVToMSL(outSPIRVVtxData, vertFuncName, outMSLVtxString, outMSLVtxErrString))	{
			NSLog(@"ERR: unable to convert SPIRV for file %s, bailing A",std::filesystem::path(inURLPathCStr).stem().c_str());
			//self = nil;
			return self;
		}
		if (outSPIRVFrgData.size()<1 || !ConvertFragSPIRVToMSL(outSPIRVFrgData, fragFuncName, outMSLFrgString, outMSLFrgErrString))	{
			NSLog(@"ERR: unable to convert SPIRV for file %s, bailing B",std::filesystem::path(inURLPathCStr).stem().c_str());
			//self = nil;
			return self;
		}
		
		//NSLog(@"%s- bailing early",__func__);
		//self = nil;
		//return self;
		
		//cout << "***************************************************************" << endl;
		//cout << outMSLVtxString << endl;
		//cout << "***************************************************************" << endl;
		//cout << outMSLFrgString << endl;
		//cout << "***************************************************************" << endl;
		
		NSString		*outMSLVtxSrc = [NSString stringWithUTF8String:outMSLVtxString.c_str()];
		NSString		*outMSLFrgSrc = [NSString stringWithUTF8String:outMSLFrgString.c_str()];
		
		
		//	the MTLVertexDescriptor needs to be configured such that the MTLBuffer containing vertex data is assigned at one higher than the max buffer(int) value in the vertex shader source code, so we have to parse the transpiled MSL signatures to find the args and their indexes
		ISFMSLFuncSignature		vertSig = ISFMSLParseFuncSignature(vertFuncName, outMSLVtxString);
		ISFMSLFuncSignature		fragSig = ISFMSLParseFuncSignature(fragFuncName, outMSLFrgString);
		
		//	a GLSL "uniform" declared in the ISF's shader body isn't part of the ISF spec, but survives to the MSL as its own entry-point
		//	arg that we have no value to bind- metal API validation would abort the process at draw time, so treat it as a failed compile
		std::vector<ISFMSLUnboundArg>		vertUnboundArgs = ISFMSLFindUnboundArgs(vertSig, *doc);
		std::vector<ISFMSLUnboundArg>		fragUnboundArgs = ISFMSLFindUnboundArgs(fragSig, *doc);
		if (vertUnboundArgs.size() > 0 || fragUnboundArgs.size() > 0)	{
			for (const ISFMSLUnboundArg & unboundArg : vertUnboundArgs)
				NSLog(@"ERR: vert shader for file %s declares %s (%s %d), which the ISF host can't supply, bailing",raw_filename.c_str(),unboundArg.name.c_str(),unboundArg.kind.c_str(),unboundArg.index);
			for (const ISFMSLUnboundArg & unboundArg : fragUnboundArgs)
				NSLog(@"ERR: frag shader for file %s declares %s (%s %d), which the ISF host can't supply, bailing",raw_filename.c_str(),unboundArg.name.c_str(),unboundArg.kind.c_str(),unboundArg.index);
			return self;
		}
		
		//	dump the maps to dicts we'll be caching
		NSMutableDictionary			*vertBufferVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (const auto & [key, value] : vertSig.buffers)	{
			NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
			NSNumber		*tmpNum = @( value );
			if (tmpKey != nil && tmpNum != nil)	{
				[vertBufferVarIndexDict setObject:tmpNum forKey:tmpKey];
			}
		}
		NSMutableDictionary			*vertTextureVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (const auto & [key, value] : vertSig.textures)	{
			NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
			NSNumber		*tmpNum = @( value );
			if (tmpKey != nil && tmpNum != nil)	{
				[vertTextureVarIndexDict setObject:tmpNum forKey:tmpKey];
			}
		}
		NSMutableDictionary			*vertSamplerVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (const auto & [key, value] : vertSig.samplers)	{
			NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
			NSNumber		*tmpNum = @( value );
			if (tmpKey != nil && tmpNum != nil)	{
				[vertSamplerVarIndexDict setObject:tmpNum forKey:tmpKey];
			}
		}
		
		NSMutableDictionary			*fragBufferVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (const auto & [key, value] : fragSig.buffers)	{
			NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
			NSNumber		*tmpNum = @( value );
			if (tmpKey != nil && tmpNum != nil)	{
				[fragBufferVarIndexDict setObject:tmpNum forKey:tmpKey];
			}
		}
		NSMutableDictionary			*fragTextureVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (const auto & [key, value] : fragSig.textures)	{
			NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
			NSNumber		*tmpNum = @( value );
			if (tmpKey != nil && tmpNum != nil)	{
				[fragTextureVarIndexDict setObject:tmpNum forKey:tmpKey];
			}
		}
		NSMutableDictionary			*fragSamplerVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
		for (const auto & [key, value] : fragSig.samplers)	{
			NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
			NSNumber		*tmpNum = @( value );
			if (tmpKey != nil && tmpNum != nil)	{
				[fragSamplerVarIndexDict setObject:tmpNum forKey:tmpKey];
			}
		}
		
		
		//	now that we've assembled a collection of all of the args with the sampler attribute and their corresponding indexes, we can just look for the max index value and update the vertex function max buffer index ivar
		uint32_t			vtx_func_max_buffer_index = 0;
		//for (auto iter = std::begin(fragSig.buffers); iter != std::end(fragSig.buffers); ++iter)
		for (auto iter = std::begin(vertSig.buffers); iter != std::end(vertSig.buffers); ++iter)
		{
			if (iter->second > vtx_func_max_buffer_index)	{
				vtx_func_max_buffer_index = iter->second;
			}
		}
		//NSLog(@"vtx_func_max_buffer_index is %d",vtx_func_max_buffer_index);
		
		
		self.glslFragShaderHash = fragSrcHash;
		self.mslVertShader = outMSLVtxSrc;
		self.vertFuncName = [NSString stringWithUTF8String:vertFuncName.c_str()];
		self.mslFragShader = outMSLFrgSrc;
		self.fragFuncName = [NSString stringWithUTF8String:fragFuncName.c_str()];
		
		
		self.vertBufferVarIndexDict = vertBufferVarIndexDict;
		self.vertTextureVarIndexDict = vertTextureVarIndexDict;
		self.vertSamplerVarIndexDict = vertSamplerVarIndexDict;
		self.fragBufferVarIndexDict = fragBufferVarIndexDict;
		self.fragTextureVarIndexDict = fragTextureVarIndexDict;
		self.fragSamplerVarIndexDict = fragSamplerVarIndexDict;
		
		self.maxUBOSize = (uint32_t)doc->getMaxUBOSize();
		self.vtxFuncMaxBufferIndex = vtx_func_max_buffer_index;
		
	}
	return self;
}


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
		_hasCustomVertShader = NO;
		
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
		
		//	a successful entry with an unbindable buffer var was cached before we started rejecting them- dropping it here makes it re-transpile (and get its error log) instead of crashing at draw time
		if (_mslFragShader != nil
		&& (BufferVarIndexDictHasUnbindableVar(_vertBufferVarIndexDict) || BufferVarIndexDictHasUnbindableVar(_fragBufferVarIndexDict)))
		{
			self = nil;
			return self;
		}
		
		tmpNum = [n decodeObjectForKey:kISFMSLCacheObject_maxUBOSize];
		_maxUBOSize = tmpNum.intValue;
		tmpNum = [n decodeObjectForKey:kISFMSLCacheObject_vtxFuncMaxBufferIndex];
		_vtxFuncMaxBufferIndex = tmpNum.intValue;
		tmpNum = [n decodeObjectForKey:kISFMSLCacheObject_hasCustomVertShader];
		if (tmpNum == nil)	{
			//NSLog(@"************* ERR: hasCusomVertShader property not found, %s",__func__);
			self = nil;
			return self;
			//tmpNum = @(NO);
		}
		_hasCustomVertShader = tmpNum.boolValue;
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
	[coder encodeObject:@(_hasCustomVertShader) forKey:kISFMSLCacheObject_hasCustomVertShader];
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
- (void) logTranspilerErrorForDevice:(id<MTLDevice>)inDevice	{
	if (inDevice == nil)
		return;
	
	//	collect all the data we want to export: make the transpiler error, use that to generate the log string
	NSURL		*tmpURL = (self.path==nil) ? nil : [NSURL fileURLWithPath:self.path];
	ISFMSLTranspilerError	*transErr = [ISFMSLTranspilerError createWithURL:tmpURL device:inDevice];
	NSString		*exportString = (transErr==nil) ? nil : [transErr generateStringForLogFile];
	if (exportString == nil)
		return;
	
	//	make sure the error logs directory exists- create it if it doesn't yet
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSError		*nsErr = nil;
	NSURL		*localErrorLogsDir = self.parentCache.transpilerErrorLogsDirectory;
	
	if (![fm fileExistsAtPath:localErrorLogsDir.path])	{
		if (![fm createDirectoryAtURL:localErrorLogsDir withIntermediateDirectories:YES attributes:nil error:&nsErr] || nsErr!=nil)	{
			NSLog(@"ERR: %s, unable to make logs directory (%@) because (%@)",__func__,localErrorLogsDir.path,nsErr.localizedDescription);
			return;
		}
	}
	
	//	craft the URL at which the error log will be saved
	NSString	*dstFilename = [[self.path.lastPathComponent stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"];
	NSURL		*dstURL = [localErrorLogsDir URLByAppendingPathComponent:dstFilename];
	
	//	save the error string at the target URL
	if (![exportString writeToURL:dstURL atomically:YES encoding:NSUTF8StringEncoding error:&nsErr])	{
		NSLog(@"ERR: %s, problem (%@) writing to URL (%@)",__func__,nsErr.localizedDescription,dstURL.path);
		return;
	}
	
}


- (void) updateInParentCache	{
	[_parentCache _pushCacheObjectToCache:self];
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
	#if DEBUG
	VVISF::ISFDocRef		doc;
	try	{
		doc = VVISF::CreateISFDocRef(inURLPathCStr, true);
	}
	catch (const VVISF::ISFErr & isfErr)	{
		NSLog(@"ERR: unable to make doc from ISF %@ (%s) - %s",fullPath,__func__,isfErr.getTypeString().c_str());
		doc = nullptr;
	}
	#else
	VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, false);
	#endif
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


- (MTLVertexDescriptor *) generateVertexDescriptor	{
	
	MTLVertexDescriptor		*vtxDesc = [MTLVertexDescriptor vertexDescriptor];
	
	vtxDesc.attributes[0].format = MTLVertexFormatFloat4;
	vtxDesc.attributes[0].offset = 0;
	vtxDesc.attributes[0].bufferIndex = self.vtxFuncMaxBufferIndex + 1;
	vtxDesc.layouts[1].stride = sizeof(float) * 4;
	vtxDesc.layouts[1].stepFunction = MTLVertexStepFunctionPerVertex;
	vtxDesc.layouts[1].stepRate = 1;
	
	return vtxDesc;
	
}


@end
