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

#include "VVISF.hpp"

#import "ISFMTLSceneImgRef_priv.h"
#import "ISFMTLSceneVal_priv.h"
#import "ISFMTLSceneAttrib_priv.h"
#import "ISFMTLScenePass_priv.h"




#define MAX_PASSES 32




using namespace std;
//using namespace VVISF;




@interface ISFMTLScene ()	{
	VVISF::ISFDocRef		doc;
	
	id<MTLLibrary>			vtxLib;
	id<MTLLibrary>			frgLib;
	
	id<MTLFunction>			vtxFunc;
	id<MTLFunction>			frgFunc;
	
	MTLImgBuffer		*vtxBufferRef;
	int					vtxBufferOffsetsByPass[MAX_PASSES];	//	the offset (in bytes) into the MTLBuffer containing vertex data at which the data relevant to that pass begins.  may be 0 for all passes, may be a bunch of zeros then a non-zero value then a bunch more zeroes, etc.
	
	//	when MSL is generated, we need to know what the max "buffer[XXX]" value is, because when we supply the 
	//	vertex data to the vertex shader, we're supplying it as an attribute to the vertex descriptor, which 
	//	means when we attach the corresponding buffer to the shader we need to do so at an index that is one 
	//	larger than the max index being used.  this is really only an issue because the shader code is the 
	//	result of a transpilation, if the shader was just...written (by a human or an AI) it's likely that 
	//	it'd use an enum in a header to declare and define attachment indexes.
	int			vtx_func_max_buffer_index;
	
	//NSArray<id<MTLRenderPipelineState>>		*psos;
	NSMutableArray<id<ISFMTLScenePass>>		*passes;
	
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
	
	vtxBufferRef = nil;
	for (int i=0; i<MAX_PASSES; ++i)
		vtxBufferOffsetsByPass[i] = 0;
	
	string		fragSrc;
	string		vertSrc;
	
	//doc->generateShaderSource(&fragSrc, &vertSrc, GLVersion_2, false);
	doc->generateShaderSource(&fragSrc, &vertSrc, VVISF::GLVersion_4, true, &maxUboSize);
	//cout << "***************************************************************" << endl;
	//cout << vertSrc << endl;
	//cout << "***************************************************************" << endl;
	//cout << fragSrc << endl;
	//cout << "***************************************************************" << endl;
	
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
	
	cout << "***************************************************************" << endl;
	cout << outMSLVtxString << endl;
	cout << "***************************************************************" << endl;
	cout << outMSLFrgString << endl;
	cout << "***************************************************************" << endl;
	
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
	
	//	the MTLVertexDescriptor needs to be configured such that the MTLBuffer containing vertex data is assigned at one higher than the max buffer(int) value in the vertex shader source code.  so we need to parse the vertex shader source code to find this value.
	//	first look for the line in the vertex shader src that contains the name of the main function- we need to search it, so first we want to make a standalone string with the whole line
	string			vertFuncLine;
	{
		regex			regex = std::regex(vertFuncName);
		smatch			matches;
		if (!regex_search(outMSLVtxString, matches, regex))	{
			NSLog(@"***************** ERR: unable to locate vert func %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
			self = nil;
			return self;
		}
		int				line_length = (int)matches.length();
		int				line_begin = (int)matches.position();
		int				line_end = line_begin + line_length;
		//  run from the beginning of the match backward until we find a line-break
		for (auto iter = std::begin(outMSLVtxString)+line_begin; iter != std::begin(outMSLVtxString); --iter) {
			if (*iter == 10 || *iter == 13)
				break;
			--line_begin;
		}
		//  run from the end of the match forward until we find a line-break
		for (auto iter = std::begin(outMSLVtxString)+line_end; iter != std::end(outMSLVtxString); ++iter) {
			//cout << "\tchecking " << *iter << endl;
			if (*iter == 10 || *iter == 13)
				break;
			++line_end;
		}
		
		vertFuncLine = outMSLVtxString.substr(line_begin, line_end - line_begin);
	}
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
	//NSLog(@"vtx_func_max_buffer_index is %d",vtx_func_max_buffer_index);
	
	
	//	allocate a block of memory- statically, so we only do it once per instance of ISFMTLScene and then re-use the mem
	#define UBO_BLOCK_BASE 16
	uboDataBufferSize = maxUboSize + (UBO_BLOCK_BASE - (maxUboSize % UBO_BLOCK_BASE));
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
	for (std::string renderPassName : doc->renderPasses())	{
		VVISF::ISFPassTargetRef		renderPass = doc->passTargetForKey(renderPassName);
		if (renderPass == nullptr)	{
			NSLog(@"ERR: pass %d null in %s",passIndex,__func__);
			self = nil;
			return self;
		}
		
		VVISF::ISFImageRef			imgRef = renderPass->image();
		if (imgRef == nullptr)	{
			NSLog(@"ERR: pass %d img null in %s",passIndex,__func__);
			self = nil;
			return self;
		}
		
		id<ISFMTLScenePass>		pass = [ISFMTLScenePass createWithPassTarget:renderPass];
		pass.target = nil;
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
		id<ISFMTLSceneAttrib>		attr = [ISFMTLSceneAttrib createWithISFAttr:attr_cpp];
		if (attr == nil)
			continue;
		[inputs addObject:attr];
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
	
	NSLog(@"sizeof ISFRenderInfo is %d",sizeof(ISFRenderInfo));
	NSLog(@"sizeof ISFImgInfo is %d",sizeof(ISFImgInfo));
	
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
	//NSLog(@"%s",__func__);
	
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
	
	{
		
		
		//	populate the data buffer with some of the vals we'll want to pass to the ISF shader
		VVISF::ISFRenderInfo		*renderInfoPtr = (VVISF::ISFRenderInfo *)uboDataBuffer;
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
		
		//	run through the doc's attributes, continuing to populate the data buffer...
		uint8_t			*baseAttrPtr = (uint8_t*)uboDataBuffer + sizeof(VVISF::ISFRenderInfo);
		for (VVISF::ISFAttrRef attrRef : doc->inputs())	{
			if (attrRef == nullptr)
				continue;
			
			VVISF::ISFAttr		&attr = *attrRef;
			VVISF::ISFVal		&val = attr.currentVal();
			
			switch (attr.type())	{
			case VVISF::ISFValType_None:
				break;
			case VVISF::ISFValType_Event:
			case VVISF::ISFValType_Bool:
				{
					uint		*wPtr = (uint*)(baseAttrPtr + attr.offsetInBuffer());
					*wPtr = (val.getBoolVal()) ? 1 : 0;
				}
				break;
			case VVISF::ISFValType_Long:
				{
					int32_t		*wPtr = (int32_t*)(baseAttrPtr + attr.offsetInBuffer());
					*wPtr = val.getLongVal();
				}
				break;
			case VVISF::ISFValType_Float:
				{
					float		*wPtr = (float*)(baseAttrPtr + attr.offsetInBuffer());
					*wPtr = val.getDoubleVal();
				}
				break;
			case VVISF::ISFValType_Point2D:
				{
					float		*wPtr = (float*)(baseAttrPtr + attr.offsetInBuffer());
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
			case VVISF::ISFValType_Color:
				{
					float		*wPtr = (float*)(baseAttrPtr + attr.offsetInBuffer());
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
			case VVISF::ISFValType_Cube:
				{
					//VVISF::ISFCubeInfo		*wPtr = (VVISF::ISFCubeInfo*)(baseAttrPtr + attr.offsetInBuffer());
					//wPtr->size[0] = XXX;
					//wPtr->size[1] = XXX;
				}
				break;
			case VVISF::ISFValType_Image:
			case VVISF::ISFValType_Audio:
			case VVISF::ISFValType_AudioFFT:
				{
					//VVISF::ISFImgInfo		*wPtr = (VVISF::ISFImgInfo*)(baseAttrPtr + attr.offsetInBuffer());
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
		
		
		
		
		
		//	make a MTLBuffer to contains the values of the inputs/etc we need to send to the shader to render
		id<MTLBuffer>		inputVals = [self.device
			newBufferWithBytes:uboDataBuffer
			length:uboDataBufferSize
			options:MTLResourceStorageModeShared];
		
		
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
	}
	
	//[self.renderEncoder
	//	drawPrimitives:MTLPrimitiveTypeTriangleStrip
	//	vertexStart:0
	//	vertexCount:4];
	
	
	//	don't forget to update the rendered frame index!
	++_renderFrameIndex;
}


- (NSArray<id<ISFMTLScenePass>> *) passes	{
	return [NSArray arrayWithArray:passes];
}
- (NSArray<id<ISFMTLSceneAttrib>> *) inputs	{
	return [NSArray arrayWithArray:inputs];
}


@end
