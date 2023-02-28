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

#include "VVISF.hpp"




using namespace std;
using namespace VVISF;




@interface ISFMTLScene ()	{
	ISFDocRef		doc;
	id<MTLLibrary>			vtxLib;
	id<MTLLibrary>			frgLib;
	
	id<MTLFunction>			vtxFunc;
	id<MTLFunction>			frgFunc;
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
	doc = CreateISFDocRef(inURLPathCStr, false);
	//doc = CreateISFDocRef(inURLPathStr, false);
	if (doc == nullptr)	{
		self = nil;
		return self;
	}
	
	string		fragSrc;
	string		vertSrc;
	//doc->generateShaderSource(&fragSrc, &vertSrc, GLVersion_2, false);
	doc->generateShaderSource(&fragSrc, &vertSrc, GLVersion_4, true);
	cout << "***************************************************************" << endl;
	cout << vertSrc << endl;
	cout << "***************************************************************" << endl;
	cout << fragSrc << endl;
	cout << "***************************************************************" << endl;
	
	vector<uint32_t>	outSPIRVVtxData;
	vector<uint32_t>	outSPIRVFrgData;
	if (!ConvertGLSLVertShaderToSPIRV(vertSrc, outSPIRVVtxData))	{
		NSLog(@"ERR: unable to convert vert shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	
	if (!ConvertGLSLFragShaderToSPIRV(fragSrc, outSPIRVFrgData))	{
		NSLog(@"ERR: unable to convert frag shader for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
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
		NSLog(@"ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	if (!ConvertFragSPIRVToMSL(outSPIRVFrgData, fragFuncName, outMSLFrgString))	{
		NSLog(@"ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
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
		NSLog(@"ERR: unable to make lib from vtx src %s, bailing (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	frgLib = [self.device newLibraryWithSource:outMSLFrgSrc options:nil error:&nsErr];
	if (frgLib == nil)	{
		NSLog(@"ERR: unable to make lib from frg src %s, bailing (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	
	vtxFunc = [vtxLib newFunctionWithName:[NSString stringWithUTF8String:vertFuncName.c_str()]];
	if (vtxFunc == nil)	{
		NSLog(@"ERR: unable to make func from vtx lib %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	frgFunc = [frgLib newFunctionWithName:[NSString stringWithUTF8String:fragFuncName.c_str()]];
	if (frgFunc == nil)	{
		NSLog(@"ERR: unable to make func from frg lib %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	
	MTLVertexDescriptor		*vtxDesc = [MTLVertexDescriptor vertexDescriptor];
	
	vtxDesc.attributes[0].format = MTLVertexFormatFloat4;
	vtxDesc.attributes[0].offset = 0;
	vtxDesc.attributes[0].bufferIndex = 1;
	vtxDesc.layouts[1].stride = sizeof(float) * 4;
	vtxDesc.layouts[1].stepFunction = MTLVertexStepFunctionPerVertex;
	vtxDesc.layouts[1].stepRate = 1;
	
	MTLRenderPipelineDescriptor		*psDesc = [[MTLRenderPipelineDescriptor alloc] init];
	psDesc.vertexFunction = vtxFunc;
	psDesc.fragmentFunction = frgFunc;
	psDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	psDesc.vertexDescriptor = vtxDesc;
	
	self.renderPipelineStateObject = [self.device newRenderPipelineStateWithDescriptor:psDesc error:&nsErr];
	if (self.renderPipelineStateObject == nil || nsErr != nil)	{
		NSLog(@"ERR: unable to make PSO for file %s (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	
	return self;
}

- (void) renderCallback	{
	//NSLog(@"%s",__func__);
	
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
			atIndex:1];
	}
	
	{
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
	}
	
	[self.renderEncoder
		drawPrimitives:MTLPrimitiveTypeTriangleStrip
		vertexStart:0
		vertexCount:4];
}

@end
