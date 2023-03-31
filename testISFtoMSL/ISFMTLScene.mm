//
//  ISFMTLScene.m
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import "ISFMTLScene.h"

#include "GLSLangValidatorLib.hpp"
#include "SPIRVCrossLib.hpp"

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <regex>
#include <typeinfo>

#include "VVISF.hpp"
#include "ISFImage.h"

#import "ISFMTLSceneImgRef_priv.h"
#import "ISFMTLSceneVal_priv.h"
#import "ISFMTLSceneAttrib_priv.h"
#import "ISFMTLScenePassTarget_priv.h"




#define MAX_PASSES 32




using namespace std;
//using namespace VVISF;




@interface ISFMTLScene ()	{
	VVISF::ISFDocRef		doc;
	
	id<MTLLibrary>			vtxLib;
	id<MTLLibrary>			frgLib;
	
	id<MTLFunction>			vtxFunc;
	id<MTLFunction>			frgFunc;
	
	//	the string is the ISF attribute name (or "VVISF_UNIFORMS&"), the int is the index in the shader at which 
	//	metal expects the corresponding resource to be attached.  populated by examining the frag shader.
	std::map<std::string,int>		fragBufferVarIndexMap;
	std::map<std::string,int>		fragTextureVarIndexMap;
	std::map<std::string,int>		fragSamplerVarIndexMap;
	
	std::map<std::string,int>		vertBufferVarIndexMap;
	std::map<std::string,int>		vertTextureVarIndexMap;
	std::map<std::string,int>		vertSamplerVarIndexMap;
	
	//	when MSL is generated, we need to know what the max "buffer[XXX]" value is, because when we supply the 
	//	vertex data to the vertex shader, we're supplying it as an attribute to the vertex descriptor, which 
	//	means when we attach the corresponding buffer to the shader we need to do so at an index that is one 
	//	larger than the max index being used ("XXX + 1").  this is really only an issue because the shader code is the 
	//	result of a transpilation, if the shader was just...written (by a human or an AI) it's likely that 
	//	it'd use an enum in a header to declare and define attachment indexes.
	int			vtx_func_max_buffer_index;
	
	//NSArray<id<MTLRenderPipelineState>>		*psos;
	NSMutableArray<id<ISFMTLScenePassTarget>>		*passes;
	
	NSMutableArray<id<ISFMTLSceneAttrib>>	*inputs;
	
	//	we need to pass data describing the state/value of the ISF's inputs to the shaders- since the shader 
	//	source code is generated programmatically, we can figure out exactly what the structure of the data we 
	//	need to pass needs to look like- and populate the data buffer automatically- by examining the ISFDoc's 
	//	structure and the state of its various attributes and passes.
	size_t		maxUboSize;
	
	size_t			uboDataBufferSize;
	void			*uboDataBuffer;
	
	VVISF::Timestamp	_baseTime;
	uint32_t			_renderFrameIndex;
	double				_renderTime;
	double				_renderTimeDelta;
	uint32_t			_passIndex;
}
@end




@implementation ISFMTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice isfURL:(NSURL *)inURL	{
	NSLog(@"%s ... %@",__func__,inURL.lastPathComponent);
	self = [super initWithDevice:inDevice];
	if (inURL == nil)
		self = nil;
	
	if (self == nil)
		return self;
	
	//	create an ISFDoc from the passed URL
	NSString		*inURLPath = inURL.path;
	const char		*inURLPathCStr = inURLPath.UTF8String;
	//std::string		inURLPathStr { inURLPathCStr };
	doc = VVISF::CreateISFDocRef(inURLPathCStr, false);
	//doc = CreateISFDocRef(inURLPathStr, false);
	if (doc == nullptr)	{
		self = nil;
		return self;
	}
	
	string		fragSrc;
	string		vertSrc;
	
	//doc->generateShaderSource(&fragSrc, &vertSrc, GLVersion_2, false);
	doc->generateShaderSource(&fragSrc, &vertSrc, VVISF::GLVersion_4, true, &maxUboSize);
	//cout << "***************************************************************" << endl;
	//cout << vertSrc << endl;
	//cout << "***************************************************************" << endl;
	//cout << fragSrc << endl;
	//cout << "***************************************************************" << endl;
	//cout << "***************************************************************" << endl;
	//cout << "***************************************************************" << endl;
	//cout << "***************************************************************" << endl;
	
	//NSLog(@"\t\tsizeof(ISFShaderRenderInfo) is %d, sizeof(ISFShaderImgInfo) is %d",sizeof(VVISF::ISFShaderRenderInfo),sizeof(VVISF::ISFShaderImgInfo));
	//NSLog(@"\t\tmaxUBOSize returned by libISFGLSLGenerator is %d",maxUboSize);
	
	vector<uint32_t>	outSPIRVVtxData;
	vector<uint32_t>	outSPIRVFrgData;
	if (!ConvertGLSLVertShaderToSPIRV(vertSrc, outSPIRVVtxData))	{
		NSLog(@"***************** ERR: unable to convert vert shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	
	if (!ConvertGLSLFragShaderToSPIRV(fragSrc, outSPIRVFrgData))	{
		NSLog(@"***************** ERR: unable to convert frag shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	
	//NSString		*filename = [inURL URLByDeletingPathExtension].lastPathComponent;
	string			raw_filename = std::filesystem::path(inURLPathCStr).stem().string();
	string			filename { "" };
	for (auto tmpchar : raw_filename)	{
		if (isalnum(tmpchar))
			filename += tmpchar;
		else
			filename += "_";
	}
	string			fragFuncName = filename+"FragFunc";
	string			vertFuncName = filename+"VertFunc";
	
	//	we're giving the vertex function an explicit name (we have to, otherwise it's just called "main" and we 
	//	won't be able to link it in a lib with other functions), so we go with a filename-based function name for now
	string		outMSLVtxString;
	string		outMSLFrgString;
	if (!ConvertVertSPIRVToMSL(outSPIRVVtxData, vertFuncName, outMSLVtxString))	{
		NSLog(@"***************** ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	if (!ConvertFragSPIRVToMSL(outSPIRVFrgData, fragFuncName, outMSLFrgString))	{
		NSLog(@"***************** ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
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
	
	NSError			*nsErr = nil;
	vtxLib = [self.device newLibraryWithSource:outMSLVtxSrc options:nil error:&nsErr];
	if (vtxLib == nil)	{
		NSLog(@"***************** ERR: unable to make lib from vtx src %s, bailing (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	frgLib = [self.device newLibraryWithSource:outMSLFrgSrc options:nil error:&nsErr];
	if (frgLib == nil)	{
		NSLog(@"***************** ERR: unable to make lib from frg src %s, bailing (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	
	vtxFunc = [vtxLib newFunctionWithName:[NSString stringWithUTF8String:vertFuncName.c_str()]];
	if (vtxFunc == nil)	{
		NSLog(@"***************** ERR: unable to make func from vtx lib %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	frgFunc = [frgLib newFunctionWithName:[NSString stringWithUTF8String:fragFuncName.c_str()]];
	if (frgFunc == nil)	{
		NSLog(@"***************** ERR: unable to make func from frg lib %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	
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
	string			vertFuncLine = FindNamedMainFuncDeclaration(vertFuncName, outMSLVtxString);
	string			fragFuncLine = FindNamedMainFuncDeclaration(fragFuncName, outMSLFrgString);
	
	
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
	vertBufferVarIndexMap = SearchForMetalAttrInFuncArgs("buffer", vertArgs);
	vertTextureVarIndexMap = SearchForMetalAttrInFuncArgs("texture", vertArgs);
	vertSamplerVarIndexMap = SearchForMetalAttrInFuncArgs("sampler", vertArgs);
	
	fragBufferVarIndexMap = SearchForMetalAttrInFuncArgs("buffer", fragArgs);
	fragTextureVarIndexMap = SearchForMetalAttrInFuncArgs("texture", fragArgs);
	fragSamplerVarIndexMap = SearchForMetalAttrInFuncArgs("sampler", fragArgs);
	
	
	//std::cout << "vertBufferVarIndexMap is: " << std::endl;
	//for (auto iter = std::begin(vertBufferVarIndexMap); iter != std::end(vertBufferVarIndexMap); ++iter)
	//	std::cout << "\t" << iter->first << " : " << iter->second << std::endl;
	//
	//std::cout << "vertTextureVarIndexMap is: " << std::endl;
	//for (auto iter = std::begin(vertTextureVarIndexMap); iter != std::end(vertTextureVarIndexMap); ++iter)
	//	std::cout << "\t" << iter->first << " : " << iter->second << std::endl;
	//
	//std::cout << "vertSamplerVarIndexMap is: " << std::endl;
	//for (auto iter = std::begin(vertSamplerVarIndexMap); iter != std::end(vertSamplerVarIndexMap); ++iter)
	//	std::cout << "\t" << iter->first << " : " << iter->second << std::endl;
	
	
	//std::cout << "fragBufferVarIndexMap is: " << std::endl;
	//for (auto iter = std::begin(fragBufferVarIndexMap); iter != std::end(fragBufferVarIndexMap); ++iter)
	//	std::cout << "\t" << iter->first << " : " << iter->second << std::endl;
	//
	//std::cout << "fragTextureVarIndexMap is: " << std::endl;
	//for (auto iter = std::begin(fragTextureVarIndexMap); iter != std::end(fragTextureVarIndexMap); ++iter)
	//	std::cout << "\t" << iter->first << " : " << iter->second << std::endl;
	//
	//std::cout << "fragSamplerVarIndexMap is: " << std::endl;
	//for (auto iter = std::begin(fragSamplerVarIndexMap); iter != std::end(fragSamplerVarIndexMap); ++iter)
	//	std::cout << "\t" << iter->first << " : " << iter->second << std::endl;
	
	
	//	now that we've assembled a collection of all of the args with the sampler attribute and their corresponding indexes, we can just look for the max index value and update the vertex function max buffer index ivar
	vtx_func_max_buffer_index = 0;
	for (auto iter = std::begin(fragBufferVarIndexMap); iter != std::end(fragBufferVarIndexMap); ++iter)	{
		if (iter->second > vtx_func_max_buffer_index)
			vtx_func_max_buffer_index = iter->second;
	}
	//NSLog(@"vtx_func_max_buffer_index is %d",vtx_func_max_buffer_index);
	
	
	
	
	/*
	//	...now we need to locate the maximum buffer(XXX) index used in this line- we'll use regex to run through all of them
	vtx_func_max_buffer_index = 0;
	{
		regex		regex = std::regex("\\[\\[[\\s]*buffer\\([\\s]*([0-9]+)[\\s]*\\)[\\s]*\\]\\]");
		for (auto iter = sregex_iterator(vertFuncLine.begin(), vertFuncLine.end(), regex); iter != sregex_iterator(); ++iter)	{
			smatch		match = *iter;
			int			buffer_index = stoi(match[1]);
			vtx_func_max_buffer_index = max(vtx_func_max_buffer_index, buffer_index);
		}
	}
	NSLog(@"vtx_func_max_buffer_index is %d",vtx_func_max_buffer_index);
	*/
	
	
	//	allocate a block of memory- statically, so we only do it once per instance of ISFMTLScene and then re-use the mem
	#define UBO_BLOCK_BASE 48
	uboDataBufferSize = maxUboSize + (UBO_BLOCK_BASE - (maxUboSize % UBO_BLOCK_BASE));
	//uboDataBufferSize = maxUboSize;
	//NSLog(@"** WARNING hard coding uboDataBufferSize to 96, %s",__func__);
	//uboDataBufferSize = 96;
	uboDataBuffer = malloc( uboDataBufferSize );
	
	
	//	make a vertex descriptor that describes the vertex data we'll be passing to the shader
	MTLVertexDescriptor		*vtxDesc = [MTLVertexDescriptor vertexDescriptor];
	
	vtxDesc.attributes[0].format = MTLVertexFormatFloat4;
	vtxDesc.attributes[0].offset = 0;
	vtxDesc.attributes[0].bufferIndex = vtx_func_max_buffer_index + 1;
	vtxDesc.layouts[1].stride = sizeof(float) * 4;
	vtxDesc.layouts[1].stepFunction = MTLVertexStepFunctionPerVertex;
	vtxDesc.layouts[1].stepRate = 1;
	
	//	make pipeline descriptors for all possible states we need to describe (8bit & float)
	MTLRenderPipelineDescriptor		*passDesc_8bit = [[MTLRenderPipelineDescriptor alloc] init];
	MTLRenderPipelineDescriptor		*passDesc_float = [[MTLRenderPipelineDescriptor alloc] init];
	for (MTLRenderPipelineDescriptor * passDesc in @[ passDesc_8bit, passDesc_float ])	{
		passDesc.vertexFunction = vtxFunc;
		passDesc.fragmentFunction = frgFunc;
		passDesc.vertexDescriptor = vtxDesc;
	}
	passDesc_8bit.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	passDesc_float.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA32Float;
	
	//	we want to minimize the # of PSOs we create and work with, so try to avoid creating one for each pass and instead try to reuse them
	id<MTLRenderPipelineState>		pso_8bit = nil;
	id<MTLRenderPipelineState>		pso_float = nil;
	
	//	make an obj-c pass for each pass in the doc- our obj-c pass object will hold intermediate render targets and other such conveniences required to implement stuff
	passes = [[NSMutableArray alloc] init];
	int			passIndex = 0;
	for (VVISF::ISFPassTargetRef tmpPass : doc->renderPasses())	{
		//VVISF::ISFPassTargetRef		tmpPass = doc->passTargetForKey(renderPassName);
		//if (tmpPass == nullptr)	{
		//	NSLog(@"ERR: pass %d for name \'%s\' was null in %s",passIndex,renderPassName.c_str(),__func__);
		//	self = nil;
		//	return self;
		//}
		
		//VVISF::ISFImageInfoRef			imgRef = tmpPass->image();
		//if (imgRef == nullptr)	{
		//	NSLog(@"ERR: pass %d img null in %s",passIndex,__func__);
		//	self = nil;
		//	return self;
		//}
		
		id<ISFMTLScenePassTarget>		pass = [ISFMTLScenePassTarget createWithPassTarget:tmpPass];
		//pass.target = nil;
		pass.passIndex = passIndex;
		if (pass.float32)	{
			if (pso_float == nil)
				pso_float = [self.device newRenderPipelineStateWithDescriptor:passDesc_float error:&nsErr];
			pass.pso = pso_float;
		}
		else	{
			if (pso_8bit == nil)
				pso_8bit = [self.device newRenderPipelineStateWithDescriptor:passDesc_8bit error:&nsErr];
			pass.pso = pso_8bit;
		}
		
		[passes addObject:pass];
		
		++passIndex;
	}
	
	//	make an obj-c attr for each attr in the doc- our objc-c attributes will be how other obj-c classes interact with the ISF and know what sort of inputs it offers and what kind of values they accept
	inputs = [[NSMutableArray alloc] init];
	for (VVISF::ISFAttrRef attr_cpp : doc->inputs())	{
		//	make the attr and add it to our local array of attrs immediately
		id<ISFMTLSceneAttrib>		attr = [ISFMTLSceneAttrib createWithISFAttr:attr_cpp];
		if (attr == nil)
			continue;
		[inputs addObject:attr];
	}
	
	
	//	run through the doc's image imports- load them into textures, and push the textures into the attrs
	for (VVISF::ISFAttrRef attr_cpp : doc->imageImports())	{
		//	...if it's an image-style attribute, and there's a path (or paths if it's a cube!), we need to load that image data into a texture using the supplied device
		switch (attr_cpp->type())	{
		case VVISF::ISFValType_None:
		case VVISF::ISFValType_Event:
		case VVISF::ISFValType_Bool:
		case VVISF::ISFValType_Long:
		case VVISF::ISFValType_Float:
		case VVISF::ISFValType_Point2D:
		case VVISF::ISFValType_Color:
			break;
		//	cube (six images), may have a paths array
		case VVISF::ISFValType_Cube:
			{
				NSLog(@"************** NOT IMPLEMENTED YET, %s",__func__);
				[[NSException
					exceptionWithName:@"not implemented yet"
					reason:@"not implemented yet"
					userInfo:nil] raise];
			}
			break;
		//	image, may have a path
		case VVISF::ISFValType_Image:
			{
				NSURL			*url = [NSURL fileURLWithPath: [NSString stringWithUTF8String:attr_cpp->description().c_str()] ];
				MTKTextureLoader		*loader = [[MTKTextureLoader alloc] initWithDevice:self.device];
				id<MTLTexture>			tex = [loader
					newTextureWithContentsOfURL:url
					options:@{
						MTKTextureLoaderOptionSRGB:@NO
					}
					error:&nsErr];
				MTLImgBuffer	*img = [[MTLPool global] bufferForExistingTexture:tex];
				if (img == nil)	{
					NSLog(@"ERR: couldn't make img from tex for attr %s, %s",attr_cpp->name().c_str(),__func__);
					self = nil;
					return self;
				}
				
				ISFImageRef		imgRef = std::make_shared<ISFImage>(img);
				attr_cpp->setCurrentImageRef(imgRef);
				//id<ISFMTLSceneVal>	val = [ISFMTLSceneVal createWithImg:img];
				//attr.currentVal = val;
			}
			break;
		//	image types...but never have paths (always audio)
		case VVISF::ISFValType_Audio:
		case VVISF::ISFValType_AudioFFT:
			break;
		}
	}
	
	
	//	make the base time timestamp now that we've finished loading the doc- this "starts the clock" on the ISF "scene"...
	_baseTime = VVISF::Timestamp();
	_renderFrameIndex = 0;
	_renderTime = 0.0;
	_renderTimeDelta = 0.0;
	_passIndex = 0;
	
	
	
	/*
	MTLRenderPipelineDescriptor		*psDesc = [[MTLRenderPipelineDescriptor alloc] init];
	psDesc.vertexFunction = vtxFunc;
	psDesc.fragmentFunction = frgFunc;
	psDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	psDesc.vertexDescriptor = vtxDesc;
	
	self.renderPipelineStateObject = [self.device newRenderPipelineStateWithDescriptor:psDesc error:&nsErr];
	if (self.renderPipelineStateObject == nil || nsErr != nil)	{
		NSLog(@"***************** ERR: unable to make PSO for file %s (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	
	NSLog(@"sizeof ISFShaderRenderInfo is %d",sizeof(ISFShaderRenderInfo));
	NSLog(@"sizeof ISFShaderImgInfo is %d",sizeof(ISFShaderImgInfo));
	
	for (auto inputAttr : doc->inputs())	{
		NSLog(@"\t\tattr %s has buffer offset %d",inputAttr->name().c_str(),inputAttr->offsetInBuffer());
	}
	for (auto pass : doc->persistentPassTargets())	{
		NSLog(@"\t\tpersistent pass %s has buffer offset %d",pass->name().c_str(),pass->offsetInBuffer());
	}
	for (auto pass : doc->tempPassTargets())	{
		NSLog(@"\t\ttemp pass %s has buffer offset %d",pass->name().c_str(),pass->offsetInBuffer());
	}
	*/
	
	return self;
}


- (void) renderCallback	{
	NSLog(@"%s",__func__);
	
	//	update local variables that get adjusted per-render or need to get pre-populated
	VVISF::Timestamp		targetRenderTime = VVISF::Timestamp() - _baseTime;
	double			targetRenderTimeInSeconds = targetRenderTime.getTimeInSeconds();
	_renderTimeDelta = fabs(targetRenderTimeInSeconds - _renderTime);
	_renderTime = targetRenderTimeInSeconds;
	_passIndex = 0;
	
	//	have the doc evaluate its buffer dimensions with the passed render size- do this before we allocate any image resources
	doc->evalBufferDimensionsWithRenderSize( round(renderSize.width), round(renderSize.height) );
	
	//	we're going to store the outputs of each render pass in this array, stored by name
	NSMutableDictionary		*outPassDict = [[NSMutableDictionary alloc] init];
	
	
	/*
	//	assemble the buffer of vertex data we're going to use (for all passes)
	CGRect			viewRect = CGRectMake( 0, 0, renderSize.width, renderSize.height );
	{
		
		//const simd_float4		quadVerts[] = {
		//	simd_make_float4( CGRectGetMinX(viewRect), CGRectGetMinY(viewRect), 0., 0. ),
		//	simd_make_float4( CGRectGetMinX(viewRect), CGRectGetMaxY(viewRect), 0., 0. ),
		//	simd_make_float4( CGRectGetMaxX(viewRect), CGRectGetMinY(viewRect), 0., 0. ),
		//	simd_make_float4( CGRectGetMaxX(viewRect), CGRectGetMaxY(viewRect), 0., 0. ),
		//};
		const vector_float4		quadVerts[4] = {
			simd_make_float4( static_cast<float>(CGRectGetMinX(viewRect)), static_cast<float>(CGRectGetMinY(viewRect)), float(0.), float(1.) ),
			simd_make_float4( static_cast<float>(CGRectGetMinX(viewRect)), static_cast<float>(CGRectGetMaxY(viewRect)), float(0.), float(1.) ),
			simd_make_float4( static_cast<float>(CGRectGetMaxX(viewRect)), static_cast<float>(CGRectGetMinY(viewRect)), float(0.), float(1.) ),
			simd_make_float4( static_cast<float>(CGRectGetMaxX(viewRect)), static_cast<float>(CGRectGetMaxY(viewRect)), float(0.), float(1.) ),
		};
		//NSLog(@"\t\tsizeof(float) is %d, sizeof(quadVerts) is %d",sizeof(float),sizeof(quadVerts));
		id<MTLBuffer>		vertBuffer = [self.device
			newBufferWithBytes:quadVerts
			length:sizeof(quadVerts)
			options:MTLResourceStorageModeShared];
		[self.renderEncoder
			setVertexBuffer:vertBuffer
			offset:0
			atIndex:vtx_func_max_buffer_index + 1];
	}
	*/
	
	
	
	
	//	these are some vars that we're going to use throughout this (relatively long) process
	
	//	every img ref used during every render pass is stored in here (which is retained through the command buffer's lifetime)
	NSMutableArray<ISFMTLSceneImgRef*>		*singleFrameTexCache = [[NSMutableArray alloc] init];
	//	the shader has attribute syntax like texture(2), etc- this dict maps these indexes to textures so we can apply them rapidly during rendering later
	NSMutableDictionary<NSNumber*,ISFMTLSceneImgRef*>	*vertRCEIndexToTexDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary<NSNumber*,id<MTLSamplerState>>	*vertRCEIndexToSamplerDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary<NSNumber*,ISFMTLSceneImgRef*>	*fragRCEIndexToTexDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary<NSNumber*,id<MTLSamplerState>>	*fragRCEIndexToSamplerDict = [[NSMutableDictionary alloc] init];
	//	maps NSSize-as-NSValue objects describing render target resolutions to id<MTLBuffer> instances that contain vertex data for a single quad for that resolution (these can be passed to the render encoder)
	NSMutableDictionary<NSValue*,id<MTLBuffer>>	*resToQuadVertsDict = [NSMutableDictionary dictionaryWithCapacity:0];
	//	at some point during rendering, we may need a random texture for stuff that doesn't have one yet.  use this (you'll have to populate it as needed first)
	MTLImgBuffer		*emptyTex = nil;
	
	//	textures need samplers! make the sampler, then populate the RCE-index-to-sampler dicts
	MTLSamplerDescriptor	*samplerDesc = [[MTLSamplerDescriptor alloc] init];
	samplerDesc.normalizedCoordinates = YES;
	samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
	samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
	samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
	samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
	id<MTLSamplerState>		sampler = [self.device newSamplerStateWithDescriptor:samplerDesc];
	for (const auto & [samplerName, samplerIndex] : vertSamplerVarIndexMap)	{
		[vertRCEIndexToSamplerDict setObject:sampler forKey:@(samplerIndex)];
	}
	for (const auto & [samplerName, samplerIndex] : fragSamplerVarIndexMap)	{
		[fragRCEIndexToSamplerDict setObject:sampler forKey:@(samplerIndex)];
	}
	
	
	//	run through the render passes, allocating some resources we'll need for rendering: textures for named render passes and quad vertex data
	int			tmpPassIndex = 0;
	for (auto tmpPassTarget : doc->renderPasses())	{
		if (tmpPassTarget == nullptr)	{
			++tmpPassIndex;
			continue;
		}
		
		VVISF::ISFImageInfo		targetInfo = tmpPassTarget->targetImageInfo();
		//ISFImageRef			imgRef = tmpPassTarget->image();
		
		//	make an NSValue* that describes the size in pixels of this render pass
		NSValue			*tmpVal = [NSValue valueWithSize:NSMakeSize(targetInfo.width, targetInfo.height)];
		//	do we already have a MTLBuffer containing quad data for this resolution?  if not...we have to make one!
		id<MTLBuffer>		tmpBuffer = [resToQuadVertsDict objectForKey:tmpVal];
		if (tmpBuffer == nil)	{
			CGRect			tmpRect = CGRectMake( 0, 0, targetInfo.width, targetInfo.height );
			const vector_float4		tmpVerts[4] = {
				simd_make_float4( static_cast<float>(CGRectGetMinX(tmpRect)), static_cast<float>(CGRectGetMinY(tmpRect)), float(0.), float(1.) ),
				simd_make_float4( static_cast<float>(CGRectGetMinX(tmpRect)), static_cast<float>(CGRectGetMaxY(tmpRect)), float(0.), float(1.) ),
				simd_make_float4( static_cast<float>(CGRectGetMaxX(tmpRect)), static_cast<float>(CGRectGetMinY(tmpRect)), float(0.), float(1.) ),
				simd_make_float4( static_cast<float>(CGRectGetMaxX(tmpRect)), static_cast<float>(CGRectGetMaxY(tmpRect)), float(0.), float(1.) ),
			};
			//NSLog(@"\t\tmaking a buffer for vertices sized %ld",sizeof(tmpVerts));
			tmpBuffer = [self.device
				newBufferWithBytes:tmpVerts
				length:sizeof(tmpVerts)
				options:MTLResourceStorageModeShared];
			if (tmpBuffer != nil)	{
				//[resArray addObject:tmpVal];
				[resToQuadVertsDict setObject:tmpBuffer forKey:tmpVal];
			}
		}
		
		//	we only want to make sure the pass has an available texture for the shader if it has a name
		std::string		&tmpPassName = tmpPassTarget->name();
		if (tmpPassName.length() > 0)	{
			//	make sure that the image associated with this render pass- the texture it renders into- is sized appropriately
			VVISF::ISFImageInfoRef		imgInfoRef = tmpPassTarget->image();
			VVISF::ISFImageInfo		*imgInfoPtr = imgInfoRef.get();
			
			ISFImage		*imgPtr = (imgInfoPtr==nullptr || typeid(imgInfoPtr)!=typeid(ISFImage)) ? nullptr : static_cast<ISFImage*>( imgInfoPtr );
			//	if the img currently exists but its size doesn't match the target info, clear the local img ptr
			if (imgPtr!=nullptr && (targetInfo.width != imgPtr->width || targetInfo.height != imgPtr->height))
				imgPtr = nullptr;
			
			//	...if the img is still non-nil then it exists & is of the appropriate dimensions- it's ready to go, so skip to the next pass...
			if (imgPtr == nullptr)	{
				//NSLog(@"\t\tallocating tex for pass %s",tmpPassName.c_str());
				//	...if we're here, we need to allocate a texture of the appropriate dimensions!
				MTLImgBuffer		*tmpTex = (tmpPassTarget->floatFlag())
					? [[MTLPool global] rgbaFloatTexSized:CGSizeMake(targetInfo.width, targetInfo.height)]
					: [[MTLPool global] bgra8TexSized:CGSizeMake(targetInfo.width, targetInfo.height)];
				ISFImageRef			newImgRef = std::make_shared<ISFImage>(tmpTex);
				tmpPassTarget->setImage(newImgRef);
			}
		}
		
		++tmpPassIndex;
	}
	//	run through the attributes, allocating textures for any image-based attributes that don't have image resources yet
	for (auto tmpAttr : doc->imageInputs())	{
		VVISF::ISFImageInfoRef	imgInfoRef = tmpAttr->getCurrentImageRef();
		VVISF::ISFImageInfo		*imgInfoPtr = imgInfoRef.get();
		
		ISFImageRef		imgRef = (imgInfoPtr==nullptr || typeid(*imgInfoPtr)!=typeid(ISFImage)) ? nullptr : std::static_pointer_cast<ISFImage>(imgInfoRef);
		ISFImage		*imgPtr = imgRef.get();
		
		//	if we have an image for this attr, great!  skip it and check the next one
		if (imgPtr != nullptr)
			continue;
		
		//	...if we're here, this attr doesn't have an image yet, just give it a generic empty black texture
		
		if (emptyTex == nil)
			emptyTex = [[MTLPool global] bgra8TexSized:CGSizeMake(64,64)];
		imgRef = std::make_shared<ISFImage>(emptyTex);
		imgInfoRef = std::static_pointer_cast<VVISF::ISFImageInfo>(imgRef);
		tmpAttr->setCurrentImageRef(imgInfoRef);
	}
	for (auto tmpAttr : doc->audioInputs())	{
		VVISF::ISFImageInfoRef	imgInfoRef = tmpAttr->getCurrentImageRef();
		VVISF::ISFImageInfo		*imgInfoPtr = imgInfoRef.get();
		
		ISFImageRef		imgRef = (imgInfoPtr==nullptr || typeid(*imgInfoPtr)!=typeid(ISFImage)) ? nullptr : std::static_pointer_cast<ISFImage>(imgInfoRef);
		ISFImage		*imgPtr = imgRef.get();
		
		//	if we have an image for this attr, great!  skip it and check the next one
		if (imgPtr != nullptr)
			continue;
		
		//	...if we're here, this attr doesn't have an image yet, just give it a generic empty black texture
		
		if (emptyTex == nil)
			emptyTex = [[MTLPool global] bgra8TexSized:CGSizeMake(64,64)];
		imgRef = std::make_shared<ISFImage>(emptyTex);
		imgInfoRef = std::static_pointer_cast<VVISF::ISFImageInfo>(imgRef);
		tmpAttr->setCurrentImageRef(imgInfoRef);
	}
	
	
	//	continue prepping values for the shader to read with the attribute values by populating the CPU-side UBO (we'll copy it to the GPU each pass)
	VVISF::ISFShaderRenderInfo		*renderInfoPtr = (VVISF::ISFShaderRenderInfo *)uboDataBuffer;
	renderInfoPtr->PASSINDEX = _passIndex;
	renderInfoPtr->RENDERSIZE[0] = renderSize.width;
	renderInfoPtr->RENDERSIZE[1] = renderSize.height;
	renderInfoPtr->TIME = _renderTime;
	renderInfoPtr->TIMEDELTA = _renderTimeDelta;
	{
		time_t		now = time(0);
		tm			*localTime = localtime(&now);
		double		timeInSeconds = 0.;
		timeInSeconds += localTime->tm_sec;
		timeInSeconds += localTime->tm_min * 60.;
		timeInSeconds += localTime->tm_hour * 60. * 60.;
		
		renderInfoPtr->DATE[0] = float(localTime->tm_year+1900.);
		renderInfoPtr->DATE[1] = float(localTime->tm_mon+1);
		renderInfoPtr->DATE[2] = float(localTime->tm_mday);
		renderInfoPtr->DATE[3] = float(timeInSeconds);
	}
	renderInfoPtr->FRAMEINDEX = _renderFrameIndex;
	
	//	run through the doc's attributes, continuing to populate the data buffer with everything except image-based value
	uint8_t			*uboBaseAttrPtr = (uint8_t*)uboDataBuffer + sizeof(VVISF::ISFShaderRenderInfo);
	for (VVISF::ISFAttrRef attrRef : doc->inputs())	{
		if (attrRef == nullptr)
			continue;
		
		VVISF::ISFAttr		&attr = *attrRef;
		VVISF::ISFVal		&val = attr.currentVal();
		
		switch (attr.type())	{
		case VVISF::ISFValType_None:
			break;
		case VVISF::ISFValType_Event:
		case VVISF::ISFValType_Bool:	{
				uint		*wPtr = (uint*)(uboBaseAttrPtr + attr.offsetInBuffer());
				*wPtr = (val.getBoolVal()) ? 1 : 0;
			}
			break;
		case VVISF::ISFValType_Long:	{
				int32_t		*wPtr = (int32_t*)(uboBaseAttrPtr + attr.offsetInBuffer());
				*wPtr = val.getLongVal();
			}
			break;
		case VVISF::ISFValType_Float:	{
				float		*wPtr = (float*)(uboBaseAttrPtr + attr.offsetInBuffer());
				*wPtr = val.getDoubleVal();
			}
			break;
		case VVISF::ISFValType_Point2D:	{
				float		*wPtr = (float*)(uboBaseAttrPtr + attr.offsetInBuffer());
				double		*rPtr = val.getPointValPtr();
				if (rPtr == nullptr)	{
					for (int i=0; i<2; ++i)	{
						*wPtr = 0.;
						++wPtr;
					}
				}
				else	{
					for (int i=0; i<2; ++i)	{
						*wPtr = (float)*rPtr;
						++wPtr;
						++rPtr;
					}
				}
			}
			break;
		case VVISF::ISFValType_Color:	{
				float		*wPtr = (float*)(uboBaseAttrPtr + attr.offsetInBuffer());
				double		*rPtr = val.getColorValPtr();
				if (rPtr == nullptr)	{
					for (int i=0; i<4; ++i)	{
						*wPtr = 0.;
						++wPtr;
					}
				}
				else	{
					for (int i=0; i<4; ++i)	{
						*wPtr = (float)*rPtr;
						++wPtr;
						++rPtr;
					}
				}
			}
			break;
		case VVISF::ISFValType_Cube:	{
				//VVISF::ISFShaderCubeInfo		*wPtr = (VVISF::ISFShaderCubeInfo*)(uboBaseAttrPtr + attr.offsetInBuffer());
				//wPtr->size[0] = XXX;
				//wPtr->size[1] = XXX;
			}
			break;
		case VVISF::ISFValType_Image:
		case VVISF::ISFValType_Audio:
		case VVISF::ISFValType_AudioFFT:	{
				//VVISF::ISFShaderImgInfo		*wPtr = (VVISF::ISFShaderImgInfo*)(uboBaseAttrPtr + attr.offsetInBuffer());
				//wPtr->rect[0] = XXX;
				//wPtr->rect[1] = XXX;
				//wPtr->rect[2] = XXX;
				//wPtr->rect[3] = XXX;
				//
				//wPtr->size[0] = XXX;
				//wPtr->size[1] = XXX;
				//
				//wPtr->flip = XXX;
			}
			break;
		}
	}
	
	
	//	this block pushes the passed texture to the RCE and writes info about it to the UBO, starting at the passed offset
	void		(^PushNamedTexToUBOandRCE)(const VVISF::ISFImageInfoRef &, const std::string &, const size_t &) = ^(const VVISF::ISFImageInfoRef & imgInfoRef, const std::string & name, const size_t & uboOffset)	{
		//	try to figure out the index in the render encoder at which this pass's texture needs to be attached
		uint32_t			fragRenderEncoderIndex = std::numeric_limits<uint32_t>::max();
		try	{
			fragRenderEncoderIndex = self->fragTextureVarIndexMap.at(name);
		}
		catch (...)	{
		}
		
		uint32_t			vertRenderEncoderIndex = std::numeric_limits<uint32_t>::max();
		try	{
			vertRenderEncoderIndex = self->vertTextureVarIndexMap.at(name);
		}
		catch (...)	{
		}
		
		//	get the current image from the attr- if it's not the expected type (ISFImage class), skip it- otherwise, recast to an ISFImageRef
		VVISF::ISFImageInfo		*imgInfoPtr = imgInfoRef.get();
		ISFImageRef		imgRef = (imgInfoPtr==nil || typeid(*imgInfoPtr)!=typeid(ISFImage)) ? nullptr : std::static_pointer_cast<ISFImage>(imgInfoRef);
		ISFImage		*imgPtr = imgRef.get();
		if (imgPtr == nullptr)	{
			std::cout << "ERR: attr missing img, " << __PRETTY_FUNCTION__ << std::endl;
			return;
		}
		
		//	if there's no image (no texture) associated with the render pass, skip it
		MTLImgBuffer		*tmpImgBuffer = imgPtr->img;
		id<MTLTexture>		tmpTex = tmpImgBuffer.texture;
		if (tmpTex == nil)
			return;
		
		//	add the img to the tex cache so it's guaranteed to stick around through the completion of rendering
		ISFMTLSceneImgRef		*objCImgRef = [ISFMTLSceneImgRef createWithImgRef:imgRef];
		if (![singleFrameTexCache containsObject:objCImgRef])
			[singleFrameTexCache addObject:objCImgRef];
		if (vertRenderEncoderIndex != std::numeric_limits<uint32_t>::max())	{
			//[renderEncoder
			//	setVertexTexture:tmpTex
			//	atIndex:vertRenderEncoderIndex];
			[vertRCEIndexToTexDict setObject:objCImgRef forKey:@( vertRenderEncoderIndex )];
		}
		if (fragRenderEncoderIndex != std::numeric_limits<uint32_t>::max())	{
			//[renderEncoder
			//	setFragmentTexture:tmpTex
			//	atIndex:fragRenderEncoderIndex];
			[fragRCEIndexToTexDict setObject:objCImgRef forKey:@( fragRenderEncoderIndex )];
		}
		
		//	if the ubo offset we were passed appears to be valid, update the texture's data in the UBO
		if (uboOffset != std::numeric_limits<uint32_t>::max())	{
			VVISF::ISFShaderImgInfo		*wPtr = (VVISF::ISFShaderImgInfo*)(uboBaseAttrPtr + uboOffset);
			NSSize			texSize = (tmpImgBuffer==nil) ? NSMakeSize(1,1) : NSMakeSize(tmpImgBuffer.width, tmpImgBuffer.height);
			NSRect			imgRect = (tmpImgBuffer==nil) ? NSMakeRect(0,0,texSize.width,texSize.height) : tmpImgBuffer.srcRect;
			BOOL			flipped = (tmpImgBuffer==nil) ? NO : tmpImgBuffer.flipV;
			
			wPtr->rect[0] = imgRect.origin.x;
			wPtr->rect[1] = imgRect.origin.y;
			wPtr->rect[2] = imgRect.size.width;
			wPtr->rect[3] = imgRect.size.height;
			
			wPtr->size[0] = imgRect.size.width;
			wPtr->size[1] = imgRect.size.height;
			
			wPtr->flip = (flipped) ? 1 : 0;
		}
	};
	//	this block pulls the current image from the passed attribute and pushes the texture to the RCE and writes info about the image to the UBO
	void		(^PushAttrRefImageToUBOandRCE)(VVISF::ISFAttrRef) = ^(VVISF::ISFAttrRef attr)	{
		//	if the atttr doesn't have a name, skip it
		std::string		name = attr->name();
		if (name.length() < 1)
			return;
		
		//	get the current image from the attr- if it's not the expected type (ISFImage class), skip it- otherwise, recast to an ISFImageRef
		VVISF::ISFImageInfoRef	imgInfoRef = attr->getCurrentImageRef();
		if (imgInfoRef == nullptr)
			return;
		
		size_t			offset = attr->offsetInBuffer();
		
		PushNamedTexToUBOandRCE(imgInfoRef, name, offset);
	};
	//	this block pulls the current image from the passed pass and pushes the texture to the RCE and writes info about the image to the UBO
	void		(^PushPassRefImgToUBOandRCE)(VVISF::ISFPassTargetRef) = ^(VVISF::ISFPassTargetRef passTarget)	{
		//	if the atttr doesn't have a name, skip it
		std::string		name = passTarget->name();
		if (name.length() < 1)
			return;
		
		//	get the current image from the attr- if it's not the expected type (ISFImage class), skip it- otherwise, recast to an ISFImageRef
		VVISF::ISFImageInfoRef	imgInfoRef = passTarget->image();
		if (imgInfoRef == nullptr)
			return;
		
		size_t			offset = passTarget->offsetInBuffer();
		
		PushNamedTexToUBOandRCE(imgInfoRef, name, offset);
	};
	
	
	//	run through all of the image-based attributes, pushing their textures to the RCE and vals to the UBO
	for (const VVISF::ISFAttrRef & attr : doc->imageImports())	{
		PushAttrRefImageToUBOandRCE(attr);
	}
	for (const VVISF::ISFAttrRef & attr : doc->imageInputs())	{
		PushAttrRefImageToUBOandRCE(attr);
	}
	for (const VVISF::ISFAttrRef & attr : doc->audioInputs())	{
		PushAttrRefImageToUBOandRCE(attr);
	}
	
	//	run through the doc's render passes- if it has a name and a texture and we can figure out the associated index, attach it
	for (const VVISF::ISFPassTargetRef & passTarget : doc->renderPasses())	{
		PushPassRefImgToUBOandRCE(passTarget);
	}
	
	
	//	run through each pass, doing the actual rendering!
	_passIndex = 0;
	for (ISFMTLScenePassTarget *objCRenderPass in passes)	{
		//	get the basic properties of the pass
		VVISF::ISFPassTargetRef		&renderPassRef = objCRenderPass.passTargetRef;
		VVISF::ISFImageInfo		renderPassTargetInfo = renderPassRef->targetImageInfo();
		NSSize			renderPassSize = NSMakeSize(renderPassTargetInfo.width, renderPassTargetInfo.height);
		
		//	allocate a new texture for the render pass- this is what we're going to render into
		MTLImgBuffer		*newTex = nil;
		if (_passIndex == (passes.count-1))	{
			newTex = self.renderTarget;
		}
		else	{
			newTex = (objCRenderPass.float32)
				? [[MTLPool global] rgbaFloatTexSized:CGSizeMake(renderPassTargetInfo.width, renderPassTargetInfo.height)]
				: [[MTLPool global] bgra8TexSized:CGSizeMake(renderPassTargetInfo.width, renderPassTargetInfo.height)];
		}
		
		//	make a render pass descriptor and then a command encoder, configure the viewport & attach the PSO
		MTLRenderPassDescriptor			*passDesc = [MTLRenderPassDescriptor renderPassDescriptor];
		MTLRenderPassColorAttachmentDescriptor		*attachDesc = passDesc.colorAttachments[0];
		attachDesc.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
		attachDesc.texture = newTex.texture;
		attachDesc.loadAction = MTLLoadActionDontCare;
		
		id<MTLRenderCommandEncoder>		renderEncoder = [self.commandBuffer renderCommandEncoderWithDescriptor:passDesc];
		[renderEncoder setViewport:(MTLViewport){ 0.f, 0.f, renderSize.width, renderSize.height, -1.f, 1.f }];
		[renderEncoder setRenderPipelineState:objCRenderPass.pso];
		
		//	attach the appropriate quad verts buffer to the render encoder
		NSValue			*resValue = [NSValue valueWithSize:renderPassSize];
		id<MTLBuffer>	quadVertsBuffer = [resToQuadVertsDict objectForKey:resValue];
		[renderEncoder
			setVertexBuffer:quadVertsBuffer
			offset:0
			atIndex:vtx_func_max_buffer_index + 1];
		
		//	iterate across the dicts of index-to-texture mappings, pushing the textures to the RCE
		[vertRCEIndexToTexDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNum, ISFMTLSceneImgRef *objCImgRef, BOOL *stop)	{
			MTLImgBuffer		*tmpImgBuffer = objCImgRef.img;
			id<MTLTexture>		tmpTex = tmpImgBuffer.texture;
			if (tmpTex == nil)
				return;
			[renderEncoder
				setVertexTexture:tmpTex
				atIndex:indexNum.intValue];
		}];
		[fragRCEIndexToTexDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNum, ISFMTLSceneImgRef *objCImgRef, BOOL *stop)	{
			MTLImgBuffer		*tmpImgBuffer = objCImgRef.img;
			id<MTLTexture>		tmpTex = tmpImgBuffer.texture;
			if (tmpTex == nil)
				return;
			[renderEncoder
				setFragmentTexture:tmpTex
				atIndex:indexNum.intValue];
		}];
		
		//	iterate across the dicts of index-to-sampler mappings, pushing the samplers to the RCE
		[vertRCEIndexToSamplerDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNum, id<MTLSamplerState> sampler, BOOL *stop)	{
			[renderEncoder setVertexSamplerState:sampler atIndex:indexNum.intValue];
		}];
		[fragRCEIndexToSamplerDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNum, id<MTLSamplerState> sampler, BOOL *stop)	{
			[renderEncoder setFragmentSamplerState:sampler atIndex:indexNum.intValue];
		}];
		
		//	update the pass index and render size values in the ubo
		renderInfoPtr->PASSINDEX = _passIndex;
		renderInfoPtr->RENDERSIZE[0] = renderPassTargetInfo.width;
		renderInfoPtr->RENDERSIZE[1] = renderPassTargetInfo.height;
		//	make a new MTLBuffer with the attribute vals and attach it to the RCE
		//NSLog(@"\t\tmaking a UBO sized %ld",uboDataBufferSize);
		id<MTLBuffer>		uboMtlBuffer = [self.device
			newBufferWithBytes:uboDataBuffer
			length:uboDataBufferSize
			options:MTLResourceStorageModeShared];
		[renderEncoder
			setVertexBuffer:uboMtlBuffer
			offset:0
			atIndex:0];
		[renderEncoder
			setFragmentBuffer:uboMtlBuffer
			offset:0
			atIndex:0];
		
		//	tell the render encoder to actually draw!
		[renderEncoder
			drawPrimitives:MTLPrimitiveTypeTriangleStrip
			vertexStart:0
			vertexCount:4];
		
		//	end encoding!
		[renderEncoder endEncoding];
		
		//	we just rendered into the texture we allocated for this pass- store this texture in the render pass (so subsequent passes can use it)
		ISFImageRef			newTexImgRef = std::make_shared<ISFImage>(newTex);
		renderPassRef->setImage(newTexImgRef);
		//	push the new texture to the cache array, the tex/RCE index dict, the UBO data buffer, etc...
		PushPassRefImgToUBOandRCE(renderPassRef);
		
		++_passIndex;
	}
	
	//	add the single frmae cache array to the completion handler, so we send all the textures we were hanging onto during rendering back to the pool
	[self.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> completed)	{
		NSMutableArray<ISFMTLSceneImgRef*>		*localSingleFrameTexCache = singleFrameTexCache;
		localSingleFrameTexCache = nil;
	}];
	
	
	
	/*
	//	make a MTLBuffer to contains the values of the inputs/etc we need to send to the shader to render
	id<MTLBuffer>		inputVals = [self.device
		newBufferWithBytes:uboDataBuffer
		length:uboDataBufferSize
		options:MTLResourceStorageModeShared];
	*/
	
	
	
	/*
	struct VVISF_UNIFORMS {
		int PASSINDEX;
		vector_float2 RENDERSIZE;
		float TIME;
		float TIMEDELTA;
		vector_float4 DATE;
		int FRAMEINDEX;
		vector_float4 _inputImage_imgRect;
		vector_float2 _inputImage_imgSize;
		uint _inputImage_flip;
	};
	
	VVISF_UNIFORMS		paramVals;
	paramVals.PASSINDEX = 0;
	paramVals.RENDERSIZE = simd_make_float2(1920, 1080);
	paramVals.TIME = 0.0;
	paramVals.TIMEDELTA = 0.0;
	paramVals.DATE = simd_make_float4(0,0,0,0);
	paramVals.FRAMEINDEX = 0;
	paramVals._inputImage_imgRect = simd_make_float4(0,0,1920,1080);
	paramVals._inputImage_imgSize = simd_make_float2(1920,1080);
	paramVals._inputImage_flip = 0;
	//NSLog(@"\t\tsizeof(VVISF_UNIFORMS) is %d",sizeof(paramVals));
	
	id<MTLBuffer>		paramsBuffer = [self.device
		newBufferWithBytes:&paramVals
		length:sizeof(paramVals)
		options:MTLResourceStorageModeShared];
	[self.renderEncoder
		setVertexBuffer:paramsBuffer
		offset:0
		atIndex:0];
	[self.renderEncoder
		setFragmentBuffer:paramsBuffer
		offset:0
		atIndex:0];
	*/
	
	//[self.renderEncoder
	//	drawPrimitives:MTLPrimitiveTypeTriangleStrip
	//	vertexStart:0
	//	vertexCount:4];
	
	
	//	don't forget to update the rendered frame index!
	++_renderFrameIndex;
}


- (NSArray<id<ISFMTLScenePassTarget>> *) passes	{
	return [NSArray arrayWithArray:passes];
}
- (NSArray<id<ISFMTLSceneAttrib>> *) inputs	{
	return [NSArray arrayWithArray:inputs];
}


- (id<ISFMTLSceneVal>) valueForInputNamed:(NSString *)n	{
	if (n == nil)
		return nil;
	
	std::string			tmpName { n.UTF8String };
	VVISF::ISFAttrRef	tmpAttr = doc->input(tmpName);
	VVISF::ISFVal		tmpVal = (tmpAttr==nullptr) ? VVISF::CreateISFValNull() : tmpAttr->currentVal();
	//VVISF::ISFVal	tmpVal = doc->valueForInputNamed(tmpName);
	return [ISFMTLSceneVal createWithISFVal:tmpVal];
}
- (void) setValue:(id<ISFMTLSceneVal>)inVal forInputNamed:(NSString *)inName	{
}


@end
