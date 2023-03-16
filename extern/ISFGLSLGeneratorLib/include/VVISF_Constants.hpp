#ifndef ISFConstants_h
#define ISFConstants_h




namespace VVISF
{


//	string constants used by the ISFScene to compiled the ISFs
static const std::string		ISF_ES_Compatibility = std::string("\
	\n\
precision highp float;	\n\
precision highp int;	\n\
	\n\
");
static const std::string		ISFGLMacro2D_GL2 = std::string("\
vec4 VVSAMPLER_2DBYPIXEL(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc)	{	\n\
	return (inSamplerFlip)	\n\
		? texture2D		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)))	\n\
		: texture2D		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)));	\n\
}	\n\
vec4 VVSAMPLER_2DBYNORM(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc)	{	\n\
	vec4		returnMe = VVSAMPLER_2DBYPIXEL(		inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgSize.x, normLoc.y*inSamplerImgSize.y));	\n\
	return returnMe;	\n\
}	\n\
");
static const std::string		ISFGLMacro2DBias_GL2 = std::string("\
vec4 VVSAMPLER_2DBYPIXEL(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc, float bias)	{	\n\
	return (inSamplerFlip)	\n\
		? texture2D		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)), bias)	\n\
		: texture2D		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)), bias);	\n\
}	\n\
vec4 VVSAMPLER_2DBYNORM(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc, float bias)	{	\n\
	vec4		returnMe = VVSAMPLER_2DBYPIXEL(		inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgSize.x, normLoc.y*inSamplerImgSize.y), bias);	\n\
	return returnMe;	\n\
}	\n\
");
static const std::string		ISFGLMacro2DRect_GL2 = std::string("	\n\
vec4 VVSAMPLER_2DRECTBYPIXEL(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc)	{	\n\
	return (inSamplerFlip)	\n\
		? texture2DRect	(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)))	\n\
		: texture2DRect	(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)));	\n\
}	\n\
vec4 VVSAMPLER_2DRECTBYNORM(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc)	{	\n\
	vec4		returnMe = VVSAMPLER_2DRECTBYPIXEL(	inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgRect.z, normLoc.y*inSamplerImgRect.w));	\n\
	return returnMe;	\n\
}	\n\
");
static const std::string		ISFGLMacro2DRectBias_GL2 = std::string("	\n\
vec4 VVSAMPLER_2DRECTBYPIXEL(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc, float bias)	{	\n\
	return (inSamplerFlip)	\n\
		? texture2DRect	(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)))	\n\
		: texture2DRect	(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)));	\n\
}	\n\
vec4 VVSAMPLER_2DRECTBYNORM(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc, float bias)	{	\n\
	vec4		returnMe = VVSAMPLER_2DRECTBYPIXEL(	inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgRect.z, normLoc.y*inSamplerImgRect.w), bias);	\n\
	return returnMe;	\n\
}	\n\
");




static const std::string		ISFGLMacro2D_GL3 = std::string("\
vec4 VVSAMPLER_2DBYPIXEL(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc)	{	\n\
	return (inSamplerFlip)	\n\
		? texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)))	\n\
		: texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)));	\n\
}	\n\
vec4 VVSAMPLER_2DBYNORM(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc)	{	\n\
	vec4		returnMe = VVSAMPLER_2DBYPIXEL(		inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgSize.x, normLoc.y*inSamplerImgSize.y));	\n\
	return returnMe;	\n\
}	\n\
");
static const std::string		ISFGLMacro2DBias_GL3 = std::string("\
vec4 VVSAMPLER_2DBYPIXEL(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc, float bias)	{	\n\
	return (inSamplerFlip)	\n\
		? texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)), bias)	\n\
		: texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)), bias);	\n\
}	\n\
vec4 VVSAMPLER_2DBYNORM(sampler2D inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc, float bias)	{	\n\
	vec4		returnMe = VVSAMPLER_2DBYPIXEL(		inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgSize.x, normLoc.y*inSamplerImgSize.y), bias);	\n\
	return returnMe;	\n\
}	\n\
");
static const std::string		ISFGLMacro2DRect_GL3 = std::string("	\n\
vec4 VVSAMPLER_2DRECTBYPIXEL(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc)	{	\n\
	return (inSamplerFlip)	\n\
		? texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)))	\n\
		: texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)));	\n\
}	\n\
vec4 VVSAMPLER_2DRECTBYNORM(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc)	{	\n\
	vec4		returnMe = VVSAMPLER_2DRECTBYPIXEL(	inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgRect.z, normLoc.y*inSamplerImgRect.w));	\n\
	return returnMe;	\n\
}	\n\
");
static const std::string		ISFGLMacro2DRectBias_GL3 = std::string("	\n\
vec4 VVSAMPLER_2DRECTBYPIXEL(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 inLoc, float bias)	{	\n\
	return (inSamplerFlip)	\n\
		? texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), (inSamplerImgRect.w-(inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)))	\n\
		: texture		(inSampler,vec2(((inLoc.x/inSamplerImgSize.x*inSamplerImgRect.z)+inSamplerImgRect.x), ((inLoc.y/inSamplerImgSize.y*inSamplerImgRect.w)+inSamplerImgRect.y)));	\n\
}	\n\
vec4 VVSAMPLER_2DRECTBYNORM(sampler2DRect inSampler, vec4 inSamplerImgRect, vec2 inSamplerImgSize, bool inSamplerFlip, vec2 normLoc, float bias)	{	\n\
	vec4		returnMe = VVSAMPLER_2DRECTBYPIXEL(	inSampler,inSamplerImgRect,inSamplerImgSize,inSamplerFlip,vec2(normLoc.x*inSamplerImgRect.z, normLoc.y*inSamplerImgRect.w), bias);	\n\
	return returnMe;	\n\
}	\n\
");




static const std::string		ISFVertPassthru_GL2 = std::string("	\n\
	\n\
void main(void)	{	\n\
	isf_vertShaderInit();	\n\
}	\n\
	\n\
");
static const std::string		ISFVertInitFunc = std::string("	\n\
	\n\
	//	gl_Position should be equal to gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex	\n\
	mat4			projectionMatrix = mat4(2./RENDERSIZE.x, 0., 0., -1.,	\n\
		0., 2./RENDERSIZE.y, 0., -1.,	\n\
		0., 0., -1., 0.,	\n\
		0., 0., 0., 1.);	\n\
	gl_Position = VERTEXDATA * projectionMatrix;	\n\
	isf_FragNormCoord = vec2((gl_Position.x+1.0)/2.0, (gl_Position.y+1.0)/2.0);	\n\
	vec2	isf_fragCoord = floor(isf_FragNormCoord * RENDERSIZE);	\n\
	\n\
");
static const std::string		ISFVertVarDec_GLES2 = std::string("	\n\
	\n\
attribute vec4		VERTEXDATA;	\n\
void isf_vertShaderInit();	\n\
	\n\
");
static const std::string		ISFVertVarDec_GL3 = std::string("	\n\
	\n\
in vec4		VERTEXDATA;	\n\
void isf_vertShaderInit();	\n\
	\n\
");


}


#endif /* ISFConstants_h */
