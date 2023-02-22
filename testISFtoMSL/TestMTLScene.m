//
//  TestMTLScene.m
//  testISFtoMSL
//
//  Created by testadmin on 2/21/23.
//

#import "TestMTLScene.h"




@implementation TestMTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice	{
	self = [super initWithDevice:inDevice];
	
	if (self == nil)
		return self;
	
	NSError		*nsErr = nil;
	NSBundle	*myBundle = [NSBundle mainBundle];
	id<MTLLibrary>		defaultLib = [self.device newDefaultLibraryWithBundle:myBundle error:&nsErr];
	id<MTLFunction>		vertFunc = [defaultLib newFunctionWithName:@"TestSceneVertFunc"];
	id<MTLFunction>		fragFunc = [defaultLib newFunctionWithName:@"TestSceneFragFunc"];
	
	MTLRenderPipelineDescriptor		*psDesc = [[MTLRenderPipelineDescriptor alloc] init];
	psDesc.label = @"TestMTLScene";
	psDesc.vertexFunction = vertFunc;
	psDesc.fragmentFunction = fragFunc;
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
	
	self.renderPipelineStateObject = [self.device newRenderPipelineStateWithDescriptor:psDesc error:&nsErr];
	if (self.renderPipelineStateObject == nil)	{
		NSLog(@"ERR: unable to make PSO, %s",__func__);
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
		const vector_float2		quadVerts[] = {
			{ CGRectGetMinX(viewRect), CGRectGetMinY(viewRect) },
			{ CGRectGetMinX(viewRect), CGRectGetMaxY(viewRect) },
			{ CGRectGetMaxX(viewRect), CGRectGetMinY(viewRect) },
			{ CGRectGetMaxX(viewRect), CGRectGetMaxY(viewRect) },
		};
		
		id<MTLBuffer>		vertBuffer = [self.device
			newBufferWithBytes:quadVerts
			length:sizeof(quadVerts)
			options:MTLResourceStorageModeShared];
		[self.renderEncoder
			setVertexBuffer:vertBuffer
			offset:0
			atIndex:0];
	}
	
	{
		double			left = 0.0;
		double			right = renderSize.width;
		double			top = renderSize.height;
		double			bottom = 0.0;
		double			far = 1.0;
		double			near = -1.0;
		BOOL		flipV = YES;
		BOOL		flipH = NO;
		if (flipV)	{
			top = 0.0;
			bottom = renderSize.height;
		}
		if (flipH)	{
			right = 0.0;
			left = renderSize.width;
		}
		matrix_float4x4			mvp = simd_matrix_from_rows(
			simd_make_float4( 2.0/(right-left), 0.0, 0.0, -1.0*(right+left)/(right-left) ),
			simd_make_float4( 0.0, 2.0/(top-bottom), 0.0, -1.0*(top+bottom)/(top-bottom) ),
			simd_make_float4( 0.0, 0.0, -2.0/(far-near), -1.0*(far+near)/(far-near) ),
			simd_make_float4( 0.0, 0.0, 0.0, 1.0 )
		);
		
		id<MTLBuffer>		mvpBuffer = [self.device
			newBufferWithBytes:&mvp
			length:sizeof(mvp)
			options:MTLResourceStorageModeShared];
		[self.renderEncoder
			setVertexBuffer:mvpBuffer
			offset:0
			atIndex:1];
	}
	
	[self.renderEncoder
		drawPrimitives:MTLPrimitiveTypeTriangleStrip
		vertexStart:0
		vertexCount:4];
}

@end
