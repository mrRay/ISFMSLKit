//
//	ISFMSLCache.m
//	ISFMSLKitTestApp
//
//	Created by testadmin on 4/11/23.
//

#import "ISFMSLCache.h"

//#import <VVCore/VVCore.h>
#import "ISFMSLNSStringAdditions.h"

#include "GLSLangValidatorLib.hpp"
#include "SPIRVCrossLib.hpp"

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <regex>
#include <typeinfo>

#include "VVISF.hpp"




using namespace std;




static ISFMSLCache		*primary = nil;




@interface ISFMSLCache ()

- (void) generalInit;

- (void) _clearCachedISFAtURL:(NSURL *)inURL;

//	doesn't check anything- immediately begins ops necessary to transpile the ISF to MSL.  ALSO KILLS ANY BINARY ARCHIVES!
- (ISFMSLCacheObject *) _cacheISFAtURL:(NSURL *)inURL;
- (ISFMSLCacheObject *) _getCachedISFAtURL:(NSURL *)inURL;

@property (strong) PINCache * isfCache;
@property (strong,readwrite) NSURL * directory;

@end




@implementation ISFMSLCache


+ (void) setPrimary:(ISFMSLCache *)n	{
	primary = n;
}
+ (ISFMSLCache *) primary	{
	return primary;
}


- (instancetype) initWithDirectoryPath:(NSString *)inPath	{
	//NSLog(@"%s ... %@",__func__,inPath);
	self = [super init];
	
	if (inPath == nil)
		self = nil;
	
	if (self != nil)	{
		_directory = [NSURL fileURLWithPath:inPath];
		
		[self generalInit];
	}
	return self;
}
- (instancetype) initWithDirectoryURL:(NSURL *)inURL	{
	//NSLog(@"%s ... %@",__func__,inURL.path);
	self = [super init];
	
	if (inURL == nil)
		self = nil;
	
	if (self != nil)	{
		_directory = inURL;
		
		[self generalInit];
	}
	
	return self;
}


- (void) generalInit	{
	//	first make sure the directory that will contain binary archives exists
	NSError				*nsErr = nil;
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSURL				*binaryArchiveDir = self.directory;
	binaryArchiveDir = [self binaryArchivesDirectory];
	if (![fm fileExistsAtPath:binaryArchiveDir.path isDirectory:nil])	{
		if (![fm createDirectoryAtURL:binaryArchiveDir withIntermediateDirectories:YES attributes:nil error:&nsErr] || nsErr != nil)	{
			NSLog(@"ERR: unable to create binary archives directory (%@), (%@), %s",binaryArchiveDir.path,nsErr,__func__);
		}
	}
	
	//	make the cache
	PINDiskCacheSerializerBlock		serializer = ^NSData*(id<NSCoding> object, NSString* key) {
		return [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:nil];
	};
	PINDiskCacheDeserializerBlock		deserializer = ^id<NSCoding>(NSData* data, NSString* key) {
		NSKeyedUnarchiver		*unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
		unarchiver.requiresSecureCoding = NO;
		ISFMSLCacheObject		*unarchived = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		unarchived.parentCache = self;
		return unarchived;
	};
	
	self.isfCache = [[PINCache alloc]
		initWithName:@"ISFMSL"
		//prefix:@""
		rootPath:_directory.path
		serializer:serializer
		deserializer:deserializer
		keyEncoder:nil
		keyDecoder:nil
		ttlCache:false];
	_isfCache.diskCache.byteLimit = 0;
	_isfCache.diskCache.ageLimit = 0;
	_isfCache.memoryCache.costLimit = 100 * 1024 * 1024;
	_isfCache.memoryCache.ageLimit = 0;
}


- (void) clearCachedISFAtURL:(NSURL *)n	{
	if (n == nil)	{
		return;
	}
	
	@synchronized (self)	{
		[self _clearCachedISFAtURL:n];
	}
}
- (void) _clearCachedISFAtURL:(NSURL *)inURL	{
	
	NSString		*fullPath = [inURL.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath isfMD5String];
	NSError			*nsErr = nil;
	
	NSFileManager	*fm = [NSFileManager defaultManager];
	
	[_isfCache removeObjectForKey:fullPathHash];
	
	for (NSURL * binArchiveDir in self.binaryArchiveDirectories)	{
		NSURL		*binArchiveFile = [binArchiveDir URLByAppendingPathComponent:fullPathHash];
		if ([fm fileExistsAtPath:binArchiveFile.path])	{
			if (![fm trashItemAtURL:binArchiveFile resultingItemURL:nil error:&nsErr] || nsErr != nil)	{
				NSLog(@"ERR: (%@) moving (%@) in %s",nsErr,binArchiveFile.path,__func__);
			}
		}
	}
}

/*
- (ISFMSLBinCacheObject *) cacheISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice	{
	ISFMSLCacheObject		*returnMe = [self cacheISFAtURL:inURL forDevice:inDevice hint:ISFMSLCacheHint_NoHint];
	return returnMe;
}
- (ISFMSLBinCacheObject *) cacheISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice hint:(ISFMSLCacheHint)inHint	{
	if (inURL == nil || inDevice == nil)
		return nil;
	
	ISFMSLBinCacheObject		*returnMe = nil;
	
	@synchronized (self)	{
		
		ISFMSLCacheObject			*parentObj = nil;
		switch (inHint)	{
		case ISFMSLCacheHint_NoHint:
			parentObj = [self _getCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_ForceTranspile:
			[self _clearCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_TranspileIfDateDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj modDateChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		case ISFMSLCacheHint_TranspileIfContentDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj fragShaderHashChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		}
		
		if (parentObj == nil)	{
			parentObj = [self _cacheISFAtURL:inURL];
		}
		
		returnMe = [parentObj binCacheForDevice:inDevice];
	}
	return returnMe;
}
*/

- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice	{
	return [self getCachedISFAtURL:inURL forDevice:inDevice hint:ISFMSLCacheHint_NoHint];
}
- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice hint:(ISFMSLCacheHint)inHint	{
	if (inURL == nil || inDevice == nil)
		return nil;
	
	ISFMSLBinCacheObject		*returnMe = nil;
	
	@synchronized (self)	{
		
		ISFMSLCacheObject			*parentObj = nil;
		switch (inHint)	{
		case ISFMSLCacheHint_NoHint:
			parentObj = [self _getCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_ForceTranspile:
			[self _clearCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_TranspileIfDateDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj modDateChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		case ISFMSLCacheHint_TranspileIfContentDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj fragShaderHashChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		}
		
		if (parentObj == nil)	{
			parentObj = [self _cacheISFAtURL:inURL];
		}
		
		returnMe = [parentObj binCacheForDevice:inDevice];
	}
	
	return returnMe;
}


- (ISFMSLCacheObject *) _getCachedISFAtURL:(NSURL *)inURL	{
	if (inURL == nil)
		return nil;
	NSString		*fullPath = [inURL.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath isfMD5String];
	ISFMSLCacheObject		*returnMe = [_isfCache objectForKey:fullPathHash];
	return returnMe;
}


- (ISFMSLCacheObject *) _cacheISFAtURL:(NSURL *)inURL	{
	if (inURL == nil)
		return nil;
	
	//	make sure there's a file at the path
	NSString			*fullPath = [inURL.path stringByExpandingTildeInPath];
	NSFileManager		*fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:fullPath])	{
		NSLog(@"ERR: file doesn't exist at %@ (%s)",inURL,__func__);
		return nil;
	}
	//	get the mod date of the file at the path- if we can't, bail, because a cache is only useful if we can check for modifications
	NSDictionary		*fileAttribs = [fm attributesOfItemAtPath:fullPath error:nil];
	NSDate				*modDate = (fileAttribs == nil) ? nil : [fileAttribs objectForKey:NSFileModificationDate];
	if (modDate == nil)	{
		NSLog(@"ERR: file mod date doesn't exist at %@ (%s)",inURL,__func__);
		return nil;
	}
	
	//	local path string (uses "~" to abbreviate the home directory if possible)
	NSString		*fullPathHash = [fullPath isfMD5String];
	
	
	//	create an ISFDoc from the passed URL
	const char		*inURLPathCStr = fullPath.UTF8String;
	//std::string		inURLPathStr { inURLPathCStr };
	VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, true);
	//doc = CreateISFDocRef(inURLPathStr, false);
	if (doc == nullptr)	{
		NSLog(@"ERR: unable to make doc from ISF %@ (%s)",fullPath,__func__);
		return nil;
	}
	
	//NSDate			*isfDocDate = [NSDate date];
	
	std::string		glslFragSrc;
	std::string		glslVertSrc;
	
	//doc->generateShaderSource(&glslFragSrc, &glslVertSrc, GLVersion_2, false);
	doc->generateShaderSource(&glslFragSrc, &glslVertSrc, VVISF::GLVersion_4, true);
	//cout << "***************************************************************" << endl;
	//cout << glslVertSrc << endl;
	//cout << "***************************************************************" << endl;
	//cout << glslFragSrc << endl;
	//cout << "***************************************************************" << endl;
	//cout << "***************************************************************" << endl;
	//cout << "***************************************************************" << endl;
	//cout << "***************************************************************" << endl;
	
	//NSDate			*glslSourceDate = [NSDate date];
	
	//NSLog(@"\t\tsizeof(ISFShaderRenderInfo) is %d, sizeof(ISFShaderImgInfo) is %d",sizeof(VVISF::ISFShaderRenderInfo),sizeof(VVISF::ISFShaderImgInfo));
	//NSLog(@"\t\tmaxUBOSize returned by libISFGLSLGenerator is %d",maxUboSize);
	
	NSString		*fragSrcHash = [[NSString stringWithUTF8String:glslFragSrc.c_str()] isfMD5String];
	
	std::vector<uint32_t>	outSPIRVVtxData;
	std::vector<uint32_t>	outSPIRVFrgData;
	if (!ConvertGLSLVertShaderToSPIRV(glslVertSrc, outSPIRVVtxData))	{
		NSLog(@"ERR: unable to convert vert shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		return nil;
	}
	
	if (!ConvertGLSLFragShaderToSPIRV(glslFragSrc, outSPIRVFrgData))	{
		NSLog(@"ERR: unable to convert frag shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		return nil;
	}
	
	//NSDate			*transpiledDate = [NSDate date];
	
	//NSString		*filename = [inURL URLByDeletingPathExtension].lastPathComponent;
	std::string			raw_filename = std::filesystem::path(inURLPathCStr).stem().string();
	std::string			filename { "" };
	for (auto tmpchar : raw_filename)	{
		if (isalnum(tmpchar))
			filename += tmpchar;
		else
			filename += "_";
	}
	std::string			fragFuncName = filename+"FragFunc";
	std::string			vertFuncName = filename+"VertFunc";
	
	//	we're giving the vertex function an explicit name (we have to, otherwise it's just called "main" and we 
	//	won't be able to link it in a lib with other functions), so we go with a filename-based function name for now
	std::string		outMSLVtxString;
	std::string		outMSLFrgString;
	if (!ConvertVertSPIRVToMSL(outSPIRVVtxData, vertFuncName, outMSLVtxString))	{
		NSLog(@"ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		return nil;
	}
	if (!ConvertFragSPIRVToMSL(outSPIRVFrgData, fragFuncName, outMSLFrgString))	{
		NSLog(@"ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		return nil;
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
	
	
	//	this lambda finds the passed string (whole-word-match only) in the other passed string
	auto FindNamedMainFuncDeclaration = [](const std::string &inFuncName, const std::string &inShaderString) -> std::string	{
		std::regex			regex = std::regex( std::string("\\b") + inFuncName + std::string("\\b") );
		std::smatch			matches;
		if (!std::regex_search(inShaderString, matches, regex))	{
			return std::string("");
		}
		int				line_begin = (int)matches.position();
		int				line_end = line_begin + (int)matches.length();
		//  run from the beginning of the match backward until we find a line-break
		for (auto iter = std::begin(inShaderString)+line_begin; iter != std::begin(inShaderString); --iter) {
			if (*iter == 10 || *iter == 13)
				break;
			--line_begin;
		}
		//  run from the end of the match forward until we find a line-break
		for (auto iter = std::begin(inShaderString)+line_end; iter != std::end(inShaderString); ++iter) {
			//cout << "\tchecking " << *iter << endl;
			if (*iter == 10 || *iter == 13)
				break;
			++line_end;
		}
		return inShaderString.substr(line_begin, line_end - line_begin);
	};
	//	the MTLVertexDescriptor needs to be configured such that the MTLBuffer containing vertex data is assigned at one higher than the max buffer(int) value in the vertex shader source code.  so we need to parse the vertex shader source code to find this value.
	//	first look for the line in the vertex shader src that contains the name of the main function- we need to search it, so first we want to make a standalone string with the whole line
	std::string			vertFuncLine = FindNamedMainFuncDeclaration(vertFuncName, outMSLVtxString);
	std::string			fragFuncLine = FindNamedMainFuncDeclaration(fragFuncName, outMSLFrgString);
	
	
	//	this lambda accepts a function declaration, and returns an array of the args passed to it, stripped of enclosing whitespace
	auto GetFuncStringArgs = [](const std::string &inFuncLine) -> std::vector<std::string>	{
		std::vector<std::string>		returnMe;
		//	find the first left parenthesis in inFuncLine using find_first_of
		auto		leftParenIter = inFuncLine.find_first_of('(');
		//	find the last right parenthesis in inFuncLine using find_last_of
		auto		rightParenIter = inFuncLine.find_last_of(')');
		//	make a substring of inFuncLine using the characters between leftParenIter and rightParenIter, non-inclusive
		std::string		inFuncParams = inFuncLine.substr(leftParenIter+1, rightParenIter-leftParenIter-1);
		//	split up inFuncParams using commas as the delimiter
		std::vector<std::string>		inFuncParamsSplit;
		std::regex			regex = std::regex( std::string(",") );
		std::sregex_token_iterator		iter(inFuncParams.begin(), inFuncParams.end(), regex, -1);
		std::sregex_token_iterator		end;
		while (iter != end)	{
			if (iter->length() > 0)
				inFuncParamsSplit.push_back(*iter);
			++iter;
		}
		for (auto iter = std::begin(inFuncParamsSplit); iter != std::end(inFuncParamsSplit); ++iter)	{
			//	trim whitespace from the beginning of the string
			auto		trimBeginIter = iter->find_first_not_of(" \t");
			//	trim whitespace from the end of the string
			auto		trimEndIter = iter->find_last_not_of(" \t");
			//	make a substring of the string using the trimmed indices
			std::string		trimmedString = iter->substr(trimBeginIter, trimEndIter-trimBeginIter+1);
			//	add the trimmed string to the map
			returnMe.push_back(trimmedString);
		}
		return returnMe;
	};
	std::vector<std::string>		vertArgs = GetFuncStringArgs(vertFuncLine);
	std::vector<std::string>		fragArgs = GetFuncStringArgs(fragFuncLine);
	
	
	//	this lambda looks through the array of function arguments looking for the passed attribute string (stuff 
	//	like "buffer(0)") and returns a map of the variable name and the index.  it also inserts "VVISF_UNIFORMS" 
	//	instead of the var name (which is expected to be an arbitray integer) in the map where appropriate.
	auto SearchForMetalAttrInFuncArgs = [](const std::string &searchAttrName, const std::vector<std::string> &funcArgsToSearch) -> std::map<std::string,int>	{
		//std::cout << "SearchForMetalAttrInFuncArgs()" << std::endl;
		std::map<std::string,int>		returnMe;
		
		for (auto funcArg : funcArgsToSearch)	{
			std::string		regexString = std::string("\\[\\[[\\s]*") + searchAttrName + std::string("\\([\\s]*([0-9]+)[\\s]*\\)[\\s]*\\]\\]");
			std::regex		regex = std::regex(regexString);
			for (auto searchTermIter = std::sregex_iterator(funcArg.begin(), funcArg.end(), regex); searchTermIter != std::sregex_iterator(); ++searchTermIter)	{
				std::smatch		match = *searchTermIter;
				int			parsedBufferIndex = stoi(match[1]);
				
				//	split 'funcArg' up using spaces as the delimiter
				std::vector<std::string>		funcArgWords;
				std::regex			regex = std::regex( std::string(" ") );
				std::sregex_token_iterator		iter(funcArg.begin(), funcArg.end(), regex, -1);
				std::sregex_token_iterator		end;
				while (iter != end)	{
					funcArgWords.push_back(*iter);
					++iter;
				}
				//std::cout << "funcArgWords are: ";
				//bool		first = true;
				//for (auto tmpStr : funcArgWords)	{
				//	if (!first)
				//		std::cout << ", ";
				//	std::cout << tmpStr;
				//	first = false;
				//}
				//std::cout << std::endl;
				
				if (funcArgWords.size() < 2)
					continue;
				
				//	variable name's the second-to-last term in the array!
				std::string		varName = funcArgWords[ funcArgWords.size()-2 ];
				//	if 'funcArgWords' contains a string that is equal to "VVISF_UNIFORMS&", then set 'varName' equal to "VVISF_UNIFORMS&"
				for (auto tmpStr : funcArgWords)	{
					if (tmpStr == "VVISF_UNIFORMS&")	{
						varName = "VVISF_UNIFORMS&";
						break;
					}
				}
				
				returnMe[varName] = parsedBufferIndex;
			}
		}
		
		return returnMe;
	};
	//	these maps let you figure out which variable name (eg: "inputImage") a given attribute index (eg: "texture", "0") corresponds to.
	//	we need this data to apply textures/buffers to the metal render command encoder.  technically, the 'vert' and 'frag' arrays should contain matching vals?
	std::map<std::string,int>		vertBufferVarIndexMap = SearchForMetalAttrInFuncArgs("buffer", vertArgs);
	std::map<std::string,int>		vertTextureVarIndexMap = SearchForMetalAttrInFuncArgs("texture", vertArgs);
	std::map<std::string,int>		vertSamplerVarIndexMap = SearchForMetalAttrInFuncArgs("sampler", vertArgs);
	
	std::map<std::string,int>		fragBufferVarIndexMap = SearchForMetalAttrInFuncArgs("buffer", fragArgs);
	std::map<std::string,int>		fragTextureVarIndexMap = SearchForMetalAttrInFuncArgs("texture", fragArgs);
	std::map<std::string,int>		fragSamplerVarIndexMap = SearchForMetalAttrInFuncArgs("sampler", fragArgs);
	
	//	dump the maps to dicts we'll be caching
	NSMutableDictionary			*vertBufferVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (const auto & [key, value] : vertBufferVarIndexMap)	{
		NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
		NSNumber		*tmpNum = @( value );
		if (tmpKey != nil && tmpNum != nil)	{
			[vertBufferVarIndexDict setObject:tmpNum forKey:tmpKey];
		}
	}
	NSMutableDictionary			*vertTextureVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (const auto & [key, value] : vertTextureVarIndexMap)	{
		NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
		NSNumber		*tmpNum = @( value );
		if (tmpKey != nil && tmpNum != nil)	{
			[vertTextureVarIndexDict setObject:tmpNum forKey:tmpKey];
		}
	}
	NSMutableDictionary			*vertSamplerVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (const auto & [key, value] : vertSamplerVarIndexMap)	{
		NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
		NSNumber		*tmpNum = @( value );
		if (tmpKey != nil && tmpNum != nil)	{
			[vertSamplerVarIndexDict setObject:tmpNum forKey:tmpKey];
		}
	}
	
	NSMutableDictionary			*fragBufferVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (const auto & [key, value] : fragBufferVarIndexMap)	{
		NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
		NSNumber		*tmpNum = @( value );
		if (tmpKey != nil && tmpNum != nil)	{
			[fragBufferVarIndexDict setObject:tmpNum forKey:tmpKey];
		}
	}
	NSMutableDictionary			*fragTextureVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (const auto & [key, value] : fragTextureVarIndexMap)	{
		NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
		NSNumber		*tmpNum = @( value );
		if (tmpKey != nil && tmpNum != nil)	{
			[fragTextureVarIndexDict setObject:tmpNum forKey:tmpKey];
		}
	}
	NSMutableDictionary			*fragSamplerVarIndexDict = [NSMutableDictionary dictionaryWithCapacity:0];
	for (const auto & [key, value] : fragSamplerVarIndexMap)	{
		NSString		*tmpKey = [NSString stringWithUTF8String:key.c_str()];
		NSNumber		*tmpNum = @( value );
		if (tmpKey != nil && tmpNum != nil)	{
			[fragSamplerVarIndexDict setObject:tmpNum forKey:tmpKey];
		}
	}
	
	
	//	now that we've assembled a collection of all of the args with the sampler attribute and their corresponding indexes, we can just look for the max index value and update the vertex function max buffer index ivar
	uint32_t			vtx_func_max_buffer_index = 0;
	for (auto iter = std::begin(fragBufferVarIndexMap); iter != std::end(fragBufferVarIndexMap); ++iter)	{
		if (iter->second > vtx_func_max_buffer_index)	{
			vtx_func_max_buffer_index = iter->second;
		}
	}
	//NSLog(@"vtx_func_max_buffer_index is %d",vtx_func_max_buffer_index);
	
	
	
	
	//	make the cache object, populate it, cache it
	ISFMSLCacheObject		*returnMe = [[ISFMSLCacheObject alloc] init];
	
	returnMe.name = [NSString stringWithUTF8String:raw_filename.c_str()];
	returnMe.path = fullPath;
	returnMe.glslFragShaderHash = fragSrcHash;
	returnMe.modDate = modDate;
	returnMe.mslVertShader = outMSLVtxSrc;
	returnMe.vertFuncName = [NSString stringWithUTF8String:vertFuncName.c_str()];
	returnMe.mslFragShader = outMSLFrgSrc;
	returnMe.fragFuncName = [NSString stringWithUTF8String:fragFuncName.c_str()];
	
	
	returnMe.vertBufferVarIndexDict = vertBufferVarIndexDict;
	returnMe.vertTextureVarIndexDict = vertTextureVarIndexDict;
	returnMe.vertSamplerVarIndexDict = vertSamplerVarIndexDict;
	returnMe.fragBufferVarIndexDict = fragBufferVarIndexDict;
	returnMe.fragTextureVarIndexDict = fragTextureVarIndexDict;
	returnMe.fragSamplerVarIndexDict = fragSamplerVarIndexDict;
	
	returnMe.maxUBOSize = (uint32_t)doc->getMaxUBOSize();
	returnMe.vtxFuncMaxBufferIndex = vtx_func_max_buffer_index;
	
	returnMe.parentCache = self;
	
	[_isfCache setObject:returnMe forKey:fullPathHash];
	
	return returnMe;
}


- (NSURL *) binaryArchivesDirectory	{
	return [[self.directory URLByAppendingPathComponent:@"BinaryArchives"] URLByAppendingPathComponent:@"ISFMSL"];
}
- (NSArray<NSURL*> *) binaryArchiveDirectories	{
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSError				*nsErr = nil;
	NSArray<NSURL*>		*returnMe = [fm
		contentsOfDirectoryAtURL:self.binaryArchivesDirectory
		includingPropertiesForKeys:@[ NSURLIsDirectoryKey ]
		options:NSDirectoryEnumerationSkipsHiddenFiles
		error:&nsErr];
	return returnMe;
}


@end
