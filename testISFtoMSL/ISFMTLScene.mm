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
}
@end




@implementation ISFMTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice isfURL:(NSURL *)inURL	{
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
	
	id<MTLFunction>		vtxFunc = [vtxLib newFunctionWithName:[NSString stringWithUTF8String:vertFuncName.c_str()]];
	if (vtxFunc == nil)	{
		NSLog(@"ERR: unable to make func from vtx lib %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	id<MTLFunction>		frgFunc = [frgLib newFunctionWithName:[NSString stringWithUTF8String:fragFuncName.c_str()]];
	if (frgFunc == nil)	{
		NSLog(@"ERR: unable to make func from frg lib %s, bailing",std::filesystem::path(inURLPathCStr).stem().c_str());
		self = nil;
		return self;
	}
	
	MTLRenderPipelineDescriptor		*psDesc = [[MTLRenderPipelineDescriptor alloc] init];
	psDesc.vertexFunction = vtxFunc;
	psDesc.fragmentFunction = frgFunc;
	psDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
	
	//psDesc.alphaToCoverageEnabled = YES;
	//psDesc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	//psDesc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	////psDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	//psDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
	//psDesc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	////psDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	//psDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorZero;
	//psDesc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	//psDesc.colorAttachments[0].blendingEnabled = YES;
	
	MTLVertexDescriptor		*vtxDesc = [MTLVertexDescriptor vertexDescriptor];
	MTLVertexAttributeDescriptor	*attrDesc = [[MTLVertexAttributeDescriptor alloc] init];
	attrDesc.format = MTLVertexFormatFloat4;
	attrDesc.offset = 0;
	attrDesc.bufferIndex = 0;
	[vtxDesc.attributes setObject:attrDesc atIndexedSubscript:0];
	psDesc.vertexDescriptor = vtxDesc;
	
	self.renderPipelineStateObject = [self.device newRenderPipelineStateWithDescriptor:psDesc error:&nsErr];
	if (self.renderPipelineStateObject == nil || nsErr != nil)	{
		NSLog(@"ERR: unable to make PSO for file %s (%@)",std::filesystem::path(inURLPathCStr).stem().c_str(),nsErr);
		self = nil;
		return self;
	}
	
	return self;
}

@end
