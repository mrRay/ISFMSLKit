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




@interface ISFMSLCacheObject ()

//@property (readwrite,strong) id<MTLLibrary> vtxLib;
//@property (readwrite,strong) id<MTLLibrary> frgLib;
//@property (readwrite,strong) id<MTLFunction> vtxFunc;
//@property (readwrite,strong) id<MTLFunction> frgFunc;

@property (strong) NSMutableArray<ISFMSLBinCacheObject*> * binCache;

@end




@implementation ISFMSLCacheObject


#pragma mark - init/dealloc


+ (instancetype) createWithCache:(ISFMSLCache *)inParent url:(NSURL *)inURL	{
	return [[ISFMSLCacheObject alloc] initWithCache:inParent url:inURL];
}
- (instancetype) initWithCache:(ISFMSLCache *)inParent url:(NSURL *)inURL	{
	self = [super init];
	
	if (inParent == nil)
		self = nil;
	if (inURL == nil)
		self = nil;
	
	if (self != nil)	{
		//	make sure there's a file at the path
		NSString			*fullPath = [inURL.path stringByExpandingTildeInPath];
		NSFileManager		*fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:fullPath])	{
			NSLog(@"ERR: file doesn't exist at %@ (%s)",inURL,__func__);
			self = nil;
			return self;
		}
		//	get the mod date of the file at the path- if we can't, bail, because a cache is only useful if we can check for modifications
		NSDictionary		*fileAttribs = [fm attributesOfItemAtPath:fullPath error:nil];
		NSDate				*modDate = (fileAttribs == nil) ? nil : [fileAttribs objectForKey:NSFileModificationDate];
		if (modDate == nil)	{
			NSLog(@"ERR: file mod date doesn't exist at %@ (%s)",inURL,__func__);
			self = nil;
			return self;
		}
		
		//	local path string (uses "~" to abbreviate the home directory if possible)
		//NSString		*fullPathHash = [fullPath isfMD5String];
		
		
		//	create an ISFDoc from the passed URL
		const char		*inURLPathCStr = fullPath.UTF8String;
		//std::string		inURLPathStr { inURLPathCStr };
		VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, true);
		//doc = CreateISFDocRef(inURLPathStr, false);
		if (doc == nullptr)	{
			NSLog(@"ERR: unable to make doc from ISF %@ (%s)",fullPath,__func__);
			self = nil;
			return self;
		}
		
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
		if (!ConvertGLSLVertShaderToSPIRV(glslVertSrc, outSPIRVVtxData))	{
			NSLog(@"ERR: unable to convert vert shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
			self = nil;
			return self;
		}
		
		if (!ConvertGLSLFragShaderToSPIRV(glslFragSrc, outSPIRVFrgData))	{
			NSLog(@"ERR: unable to convert frag shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
			self = nil;
			return self;
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
		if (outSPIRVVtxData.size()<1 || !ConvertVertSPIRVToMSL(outSPIRVVtxData, vertFuncName, outMSLVtxString))	{
			NSLog(@"ERR: unable to convert SPIRV for file %s, bailing A",std::filesystem::path(inURLPathCStr).stem().c_str());
			self = nil;
			return self;
		}
		if (outSPIRVFrgData.size()<1 || !ConvertFragSPIRVToMSL(outSPIRVFrgData, fragFuncName, outMSLFrgString))	{
			NSLog(@"ERR: unable to convert SPIRV for file %s, bailing B",std::filesystem::path(inURLPathCStr).stem().c_str());
			self = nil;
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
		
		
		self.name = [NSString stringWithUTF8String:raw_filename.c_str()];
		self.path = fullPath;
		self.glslFragShaderHash = fragSrcHash;
		self.modDate = modDate;
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
		
		self.parentCache = inParent;
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
