//
//	ISFMTLCache.m
//	ISFMSLKitTestApp
//
//	Created by testadmin on 4/11/23.
//

#import "ISFMTLCache.h"

#import <VVCore/VVCore.h>

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




static ISFMTLCache		*primary = nil;




@interface ISFMTLCache ()
@property (strong) id<MTLDevice> device;
@property (strong) PINCache * isfCache;
@property (strong,readwrite) NSString * path;
@end




@implementation ISFMTLCache


+ (void) setPrimary:(ISFMTLCache *)n	{
	primary = n;
}
+ (ISFMTLCache *) primary	{
	return primary;
}


- (instancetype) initWithDevice:(id<MTLDevice>)inDevice path:(NSString *)inPath	{
	self = [super init];
	if (self != nil)	{
		_device = inDevice;
		_path = inPath;
		
		//	first make sure the directory that will contain binary archives exists
		NSError				*nsErr = nil;
		NSFileManager		*fm = [NSFileManager defaultManager];
		NSURL				*binaryArchiveDir = [NSURL fileURLWithPath:self.path];
		binaryArchiveDir = [binaryArchiveDir URLByAppendingPathComponent:@"BinaryArchives"];
		if (![fm fileExistsAtPath:binaryArchiveDir.path isDirectory:nil])	{
			if (![fm createDirectoryAtURL:binaryArchiveDir withIntermediateDirectories:YES attributes:nil error:&nsErr] || nsErr != nil)	{
				NSLog(@"ERR: unable to create binary archives directory (%@), (%@), %s",binaryArchiveDir.path,nsErr,__func__);
				self = nil;
				return self;
			}
		}
		
		//	make the cache
		PINDiskCacheSerializerBlock		serializer = ^NSData*(id<NSCoding> object, NSString* key) {
			return [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:nil];
		};
		PINDiskCacheDeserializerBlock		deserializer = ^id<NSCoding>(NSData* data, NSString* key) {
			NSKeyedUnarchiver		*unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
			unarchiver.requiresSecureCoding = NO;
			ISFMTLCacheObject		*unarchived = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
			unarchived.parentCache = self;
			unarchived.device = self.device;
			return unarchived;
		};
		
		self.isfCache = [[PINCache alloc]
			initWithName:@"ISFMSL"
			//prefix:@""
			rootPath:inPath
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
	return self;
}


- (ISFMTLCacheObject *) cacheISFAtURL:(NSURL *)n {
	if (n == nil)
		return nil;
	
	//	make sure there's a file at the path
	NSString			*fullPath = [n.path stringByExpandingTildeInPath];
	NSFileManager		*fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:fullPath])	{
		NSLog(@"ERR: file doesn't exist at %@ (%s)",n,__func__);
		return nil;
	}
	//	get the mod date of the file at the path- if we can't, bail, because a cache is only useful if we can check for modifications
	NSDictionary		*fileAttribs = [fm attributesOfItemAtPath:fullPath error:nil];
	NSDate				*modDate = (fileAttribs == nil) ? nil : [fileAttribs objectForKey:NSFileModificationDate];
	if (modDate == nil)	{
		NSLog(@"ERR: file mod date doesn't exist at %@ (%s)",n,__func__);
		return nil;
	}
	
	//	local path string (uses "~" to abbreviate the home directory if possible)
	NSString		*fullPathHash = [fullPath md5String];
	
	
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
	
	NSString		*fragSrcHash = [[NSString stringWithUTF8String:glslFragSrc.c_str()] md5String];
	
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
	ISFMTLCacheObject		*returnMe = [[ISFMTLCacheObject alloc] init];
	
	returnMe.name = [NSString stringWithUTF8String:raw_filename.c_str()];
	returnMe.path = fullPath;
	returnMe.glslShaderHash = fragSrcHash;
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
	
	//	populate the 'device' property last, but before we insert it into the cache (this generates the metal libs & funcs)
	returnMe.device = self.device;
	
	[_isfCache setObject:returnMe forKey:fullPathHash];
	
	return returnMe;
}


- (ISFMTLCacheObject *) getCachedISFAtURL:(NSURL *)n {
	if (n == nil)
		return nil;
	
	NSString		*fullPath = [n.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath md5String];
	ISFMTLCacheObject		*returnMe = [_isfCache objectForKey:fullPathHash];
	if (returnMe != nil)	{
		BOOL				purge = NO;
		//	if the modification date of the ISF file differs from the modification date of the cached data, purge & re-cash it
		NSDictionary		*fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
		NSDate				*modDate = (fileAttribs == nil) ? nil : [fileAttribs objectForKey:NSFileModificationDate];
		NSDate				*cachedModDate = returnMe.modDate;
		if ((modDate==nil && cachedModDate!=nil)
		|| (modDate!=nil && cachedModDate==nil)
		|| (modDate!=nil && cachedModDate!=nil && ![modDate isEqualTo:cachedModDate]))
		{
			purge = YES;
		}
		
		if (purge)	{
			returnMe = nil;
		}
		
	}
	
	if (returnMe == nil)	{
		returnMe = [self cacheISFAtURL:n];
	}
	
	return returnMe;
}


@end
