//
//  TestScene.metal
//  testISFtoMSL
//
//  Created by testadmin on 2/21/23.
//

#include <metal_stdlib>
using namespace metal;




struct RasterizerData	{
	vector_float4		position [[ position ]];
};




vertex RasterizerData TestSceneVertFunc(
	uint vertexID [[ vertex_id ]],
	constant vector_float4 * inVerts [[ buffer(0) ]],
	constant float4x4 * inMVP [[ buffer(1) ]])
{
	RasterizerData		returnMe;
	float4x4			mvp = float4x4(*inMVP);
	//float4				pos = float4(inVerts[vertexID], 0, 1);
	float4				pos = inVerts[vertexID];
	returnMe.position = mvp * pos;
	return returnMe;
}




fragment float4 TestSceneFragFunc(
	RasterizerData inRasterData [[ stage_in ]])
{
	float4		returnMe = float4(0,0,1,1);
	return returnMe;
}

