//
//  ISFMSLScene.m
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import "ISFMSLScene.h"
#import <MetalKit/MetalKit.h>

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

#import "ISFMSLSceneImgRef_priv.h"
#import "ISFMSLSceneVal_priv.h"
#import "ISFMSLSceneAttrib_priv.h"
#import "ISFMSLScenePassTarget_priv.h"

#import "ISFMSLCache.h"
#import "ISFMSLCacheObject.h"




#define MAX_PASSES 32




using namespace std;
//using namespace VVISF;




@interface ISFMSLScene ()	{
	VVISF::ISFDocRef		doc;
	
	NSMutableArray<id<ISFMSLScenePassTarget>>		*passes;
	
	NSMutableArray<id<ISFMSLSceneAttrib>>	*inputs;
	
	//	we need to pass data describing the state/value of the ISF's inputs to the shaders- since the shader 
	//	source code is generated programmatically, we can figure out exactly what the structure of the data we 
	//	need to pass needs to look like- and populate the data buffer automatically- by examining the ISFDoc's 
	//	structure and the state of its various attributes and passes.
	//size_t		maxUboSize;
	
	//ISFMSLCacheObject		*cacheObj;
	ISFMSLCacheObject		*cachedObj;
	ISFMSLBinCacheObject	*cachedRenderObj;
	
	size_t			uboDataBufferSize;
	void			*uboDataBuffer;
	
	VVISF::Timestamp	_baseTime;
	uint32_t			_renderFrameIndex;
	double				_renderTime;
	double				_renderTimeDelta;
	uint32_t			_passIndex;
	
	CopierMTLScene		*_copierScene;	//	used for backend copies only
}
@property (readwrite) BOOL compilerError;
@end




@implementation ISFMSLScene


#pragma mark - init/dealloc


- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice	{
	self = [super initWithDevice:inDevice];
	
	if (self != nil)	{
		doc = nullptr;
		passes = [[NSMutableArray alloc] init];
		inputs = [[NSMutableArray alloc] init];
		cachedObj = nil;
		cachedRenderObj = nil;
		uboDataBufferSize = 0;
		uboDataBuffer = nil;
	}
	
	return self;
}


#pragma mark - frontend


- (void) loadURL:(NSURL *)n	{
	[self loadURL:n resetTimer:YES];
}
- (void) loadURL:(NSURL *)n resetTimer:(BOOL)r	{
	//NSLog(@"%s ... %@",__func__,n.path.lastPathComponent);
	
	@synchronized (self)	{
		
		self.compilerError = NO;
		
		//	if the URL we're being asked to load results in no change, bail
		NSString		*tmpPath = (doc==nullptr) ? nil : [NSString stringWithUTF8String:doc->path().c_str()];
		NSURL			*currentURL = (tmpPath==nil) ? nil : [NSURL fileURLWithPath:tmpPath];
		if ((currentURL==nil && n==nil)
		|| (currentURL!=nil && n!=nil && [currentURL isEqual:n]))
		{
			return;
		}
		
		//	clear out the old
		doc = nullptr;
		[passes removeAllObjects];
		[inputs removeAllObjects];
		cachedObj = nil;
		cachedRenderObj = nil;
		
		uboDataBufferSize = 0;
		if (uboDataBuffer != nil)	{
			free(uboDataBuffer);
			uboDataBuffer = nil;
		}
		
		//	load the new- if there's nothing new to load, bail early
		NSString		*path = n.path;
		if (path == nil)	{
			return;
		}
		
		//	create an ISFDoc from the passed URL
		const char		*pathCStr = path.UTF8String;
		//std::string		inURLPathStr { pathCStr };
		#if DEBUG
		doc = VVISF::CreateISFDocRef(pathCStr, true);
		#else
		doc = VVISF::CreateISFDocRef(pathCStr, false);
		#endif
		if (doc == nullptr)	{
			NSLog(@"ERR: unable to make doc from path %@ (%s)",path,__func__);
			return;
		}
		
		NSError		*nsErr = nil;
		
		cachedRenderObj = [ISFMSLCache.primary getCachedISFAtURL:n forDevice:self.device hint:ISFMSLCacheHint_TranspileIfDateDelta logErrorToDisk:NO];
		if (cachedRenderObj == nil)	{
			NSLog(@"ERR: unable to load file (%@), %s",n.lastPathComponent,__func__);
			self.compilerError = YES;
			return;
		}
		cachedObj = cachedRenderObj.parentObj;
		//NSLog(@"\t\tfragTextureVarIndexDict is %@",cachedObj.fragTextureVarIndexDict);
		//NSLog(@"\t\tvertTextureVarIndexDict is %@",cachedObj.vertTextureVarIndexDict);
		
		
		//	allocate a block of memory- statically, so we only do it once per instance of ISFMSLScene and then re-use the mem
		#define UBO_BLOCK_BASE 48
		uboDataBufferSize = cachedObj.maxUBOSize + (UBO_BLOCK_BASE - (cachedObj.maxUBOSize % UBO_BLOCK_BASE));
		//NSLog(@"\t\tmaxUBOSize is %d, data buffer size is %d",cachedObj.maxUBOSize,uboDataBufferSize);
		//uboDataBufferSize = maxUboSize;
		//NSLog(@"** WARNING hard coding uboDataBufferSize to 96, %s",__func__);
		//uboDataBufferSize = 96;
		uboDataBuffer = malloc( uboDataBufferSize );
		
		//	make pipeline descriptors for all possible states we need to describe (8bit & float)
		MTLRenderPipelineDescriptor		*passDesc_8bit = [cachedRenderObj generate8BitPipelineDescriptor];
		passDesc_8bit.binaryArchives = @[ cachedRenderObj.archive ];
		MTLRenderPipelineDescriptor		*passDesc_float = [cachedRenderObj generateFloatPipelineDescriptor];
		passDesc_float.binaryArchives = @[ cachedRenderObj.archive ];
		
		//	we want to minimize the # of PSOs we create and work with, so try to avoid creating one for each pass and instead try to reuse them
		id<MTLRenderPipelineState>		pso_8bit = [self.device newRenderPipelineStateWithDescriptor:passDesc_8bit options:MTLPipelineOptionFailOnBinaryArchiveMiss reflection:nil error:&nsErr];
		if (pso_8bit == nil || nsErr != nil)	{
			NSLog(@"ERR: problem retrieving pso A (%@) %s",nsErr,__func__);
			return;
		}
		id<MTLRenderPipelineState>		pso_float = [self.device newRenderPipelineStateWithDescriptor:passDesc_float options:MTLPipelineOptionFailOnBinaryArchiveMiss reflection:nil error:&nsErr];
		if (pso_float == nil || nsErr != nil)	{
			NSLog(@"ERR: problem retrieving pso B (%@) %s",nsErr,__func__);
			return;
		}
		
		//	make an obj-c pass for each pass in the doc- our obj-c pass object will hold intermediate render targets and other such conveniences required to implement stuff
		int			passIndex = 0;
		for (VVISF::ISFPassTargetRef tmpPass : doc->renderPasses())	{
			id<ISFMSLScenePassTarget>		pass = [ISFMSLScenePassTarget createWithPassTarget:tmpPass];
			pass.passIndex = passIndex;
			if (pass.float32)	{
				pass.pso = pso_float;
			}
			else	{
				pass.pso = pso_8bit;
			}
			
			[passes addObject:pass];
			
			++passIndex;
		}
		
		
		//	make an obj-c attr for each attr in the doc- our objc-c attributes will be how other obj-c classes interact with the ISF and know what sort of inputs it offers and what kind of values they accept
		//inputs = [[NSMutableArray alloc] init];
		for (VVISF::ISFAttrRef attr_cpp : doc->inputs())	{
			//	make the attr and add it to our local array of attrs immediately
			id<ISFMSLSceneAttrib>		attr = [ISFMSLSceneAttrib createWithISFAttr:attr_cpp];
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
					#if DEBUG
					[[NSException
						exceptionWithName:@"not implemented yet"
						reason:@"not implemented yet"
						userInfo:nil] raise];
					#endif
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
					id<VVMTLTextureImage>		img = [[VVMTLPool global] textureForExistingTexture:tex];
					if (img == nil)	{
						NSLog(@"ERR: couldn't make img from tex for attr %s, %s",attr_cpp->name().c_str(),__func__);
						return;
					}
					
					ISFImageRef		imgRef = std::make_shared<ISFImage>(img);
					attr_cpp->setCurrentImageRef(imgRef);
					//id<ISFMSLSceneVal>	val = [ISFMSLSceneVal createWithImg:img];
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
		if (r)
			_baseTime = VVISF::Timestamp();
		_renderFrameIndex = 0;
		_renderTime = 0.0;
		_renderTimeDelta = 0.0;
		_passIndex = 0;
		
	}
}
- (NSURL *) url	{
	if (doc == nullptr)
		return nil;
	const auto			cppPath = doc->path();
	NSString			*tmpString = [[NSString stringWithUTF8String:cppPath.c_str()] stringByExpandingTildeInPath];
	return [NSURL fileURLWithPath:tmpString];
}
- (NSString *) fileDescription	{
	if (doc == nullptr)
		return nil;
	const auto			cppStr = doc->description();
	NSString			*tmpStr = [[NSString stringWithUTF8String:cppStr.c_str()] stringByExpandingTildeInPath];
	return tmpStr;
}
- (NSString *) credit	{
	if (doc == nullptr)
		return nil;
	const auto			cppStr = doc->credit();
	NSString			*tmpStr = [[NSString stringWithUTF8String:cppStr.c_str()] stringByExpandingTildeInPath];
	return tmpStr;
}
- (NSString *) vsn	{
	if (doc == nullptr)
		return nil;
	const auto			cppStr = doc->vsn();
	NSString			*tmpStr = [[NSString stringWithUTF8String:cppStr.c_str()] stringByExpandingTildeInPath];
	return tmpStr;
}
- (NSArray<NSString*> *) categoryNames	{
	if (doc == nullptr)
		return nil;
	NSMutableArray		*returnMe = [[NSMutableArray alloc] init];
	for (const auto & category : doc->categories())	{
		NSString		*tmpStr = [NSString stringWithUTF8String:category.c_str()];
		if (tmpStr != nil)
			[returnMe addObject:tmpStr];
	}
	return returnMe;
}


#pragma mark - render callback


- (void) renderCallback	{
	//NSLog(@"%s ... %@",__func__,self.url.lastPathComponent);
	if (doc == nullptr)
		return;
	
	if (cachedRenderObj == nil)
		return;
	//NSDate			*startDate = [NSDate date];
	
	ISFMSLCacheObject		*localCachedObj = cachedObj;
	//ISFMSLBinCacheObject	*localCachedRenderObj = cachedRenderObj;
	
	//	update local variables that get adjusted per-render or need to get pre-populated
	VVISF::Timestamp		targetRenderTime = VVISF::Timestamp() - _baseTime;
	double			targetRenderTimeInSeconds = targetRenderTime.getTimeInSeconds();
	_renderTimeDelta = fabs(targetRenderTimeInSeconds - _renderTime);
	_renderTime = targetRenderTimeInSeconds;
	_passIndex = 0;
	
	//	have the doc evaluate its buffer dimensions with the passed render size- do this before we allocate any image resources
	CGSize			localRenderSize = self.renderSize;
	doc->evalBufferDimensionsWithRenderSize( round(localRenderSize.width), round(localRenderSize.height) );
	
	
	//	these are some vars that we're going to use throughout this (relatively long) process
	
	
	//	every img ref used during every render pass is stored in here (which is retained through the command buffer's lifetime)
	NSMutableArray<ISFMSLSceneImgRef*>		*singleFrameTexCache = [[NSMutableArray alloc] init];
	//	the shader has attribute syntax like texture(2), etc- this dict maps these indexes to textures so we can apply them rapidly during rendering later
	NSMutableDictionary<NSNumber*,ISFMSLSceneImgRef*>	*vertRCEIndexToTexDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary<NSNumber*,id<MTLSamplerState>>	*vertRCEIndexToSamplerDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary<NSNumber*,ISFMSLSceneImgRef*>	*fragRCEIndexToTexDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary<NSNumber*,id<MTLSamplerState>>	*fragRCEIndexToSamplerDict = [[NSMutableDictionary alloc] init];
	//	maps NSSize-as-NSValue objects describing render target resolutions to id<MTLBuffer> instances that contain vertex data for a single quad for that resolution (these can be passed to the render encoder)
	NSMutableDictionary<NSValue*,id<VVMTLBuffer>>	*resToQuadVertsDict = [NSMutableDictionary dictionaryWithCapacity:0];
	//	at some point during rendering, we may need a random texture for stuff that doesn't have one yet.  use this (you'll have to populate it as needed first)
	id<VVMTLTextureImage>		emptyTex = nil;
	
	
	//	textures need samplers! make the sampler, then populate the RCE-index-to-sampler dicts
	MTLSamplerDescriptor	*samplerDesc = [[MTLSamplerDescriptor alloc] init];
	samplerDesc.normalizedCoordinates = YES;
	//samplerDesc.normalizedCoordinates = NO;
	samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
	samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
	samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
	samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
	id<MTLSamplerState>		sampler = [self.device newSamplerStateWithDescriptor:samplerDesc];
	[localCachedObj.vertSamplerVarIndexDict enumerateKeysAndObjectsUsingBlock:^(NSString *samplerName, NSNumber *attrIndex, BOOL *stop)	{
		[vertRCEIndexToSamplerDict setObject:sampler forKey:attrIndex];
	}];
	[localCachedObj.fragSamplerVarIndexDict enumerateKeysAndObjectsUsingBlock:^(NSString *samplerName, NSNumber *attrIndex, BOOL *stop)	{
		[fragRCEIndexToSamplerDict setObject:sampler forKey:attrIndex];
	}];
	
	
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
		id<VVMTLBuffer>		tmpBuffer = [resToQuadVertsDict objectForKey:tmpVal];
		if (tmpBuffer == nil)	{
			CGRect			tmpRect = CGRectMake( 0, 0, targetInfo.width, targetInfo.height );
			const vector_float4		tmpVerts[4] = {
				simd_make_float4( static_cast<float>(CGRectGetMinX(tmpRect)), static_cast<float>(CGRectGetMinY(tmpRect)), float(0.), float(1.) ),
				simd_make_float4( static_cast<float>(CGRectGetMinX(tmpRect)), static_cast<float>(CGRectGetMaxY(tmpRect)), float(0.), float(1.) ),
				simd_make_float4( static_cast<float>(CGRectGetMaxX(tmpRect)), static_cast<float>(CGRectGetMinY(tmpRect)), float(0.), float(1.) ),
				simd_make_float4( static_cast<float>(CGRectGetMaxX(tmpRect)), static_cast<float>(CGRectGetMaxY(tmpRect)), float(0.), float(1.) ),
			};
			//NSLog(@"\t\tmaking a buffer for vertices sized %ld",sizeof(tmpVerts));
			tmpBuffer = [VVMTLPool.global
				bufferWithLength:sizeof(tmpVerts)
				storage:MTLStorageModeShared
				basePtr:(void*)tmpVerts];
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
			ISFImage		*imgPtr = (imgInfoPtr==nullptr) ? nullptr : dynamic_cast<ISFImage*>(imgInfoPtr);
			//	if the img currently exists but its size doesn't match the target info, clear the local img ptr
			if (imgPtr!=nullptr && (targetInfo.width != imgPtr->width || targetInfo.height != imgPtr->height))
				imgPtr = nullptr;
			
			//	...if the img is still non-nil then it exists & is of the appropriate dimensions- it's ready to go, so skip to the next pass...
			if (imgPtr == nullptr)	{
				//NSLog(@"\t\tallocating tex for pass %s",tmpPassName.c_str());
				//	...if we're here, we need to allocate a texture of the appropriate dimensions!
				id<VVMTLTextureImage>		tmpTex = (tmpPassTarget->floatFlag())
					? [[VVMTLPool global] rgbaFloatTexSized:CGSizeMake(targetInfo.width, targetInfo.height)]
					: [[VVMTLPool global] bgra8TexSized:CGSizeMake(targetInfo.width, targetInfo.height)];
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
		ISFImage		*imgPtr = (imgInfoPtr==nullptr) ? nullptr : dynamic_cast<ISFImage*>(imgInfoPtr);
		
		//	if we have an image for this attr, great!  skip it and check the next one
		if (imgPtr != nullptr)
			continue;
		
		//	...if we're here, this attr doesn't have an image yet, just give it a generic empty black texture
		
		if (emptyTex == nil)	{
			emptyTex = [[VVMTLPool global] bgra8TexSized:CGSizeMake(64,64)];
		}
		ISFImageRef		imgRef = std::make_shared<ISFImage>(emptyTex);
		imgInfoRef = std::static_pointer_cast<VVISF::ISFImageInfo>(imgRef);
		tmpAttr->setCurrentImageRef(imgInfoRef);
	}
	for (auto tmpAttr : doc->audioInputs())	{
		VVISF::ISFImageInfoRef	imgInfoRef = tmpAttr->getCurrentImageRef();
		VVISF::ISFImageInfo		*imgInfoPtr = imgInfoRef.get();
		ISFImage		*imgPtr = (imgInfoPtr==nullptr) ? nullptr : dynamic_cast<ISFImage*>(imgInfoPtr);
		
		//	if we have an image for this attr, great!  skip it and check the next one
		if (imgPtr != nullptr)
			continue;
		
		//	...if we're here, this attr doesn't have an image yet, just give it a generic empty black texture
		
		if (emptyTex == nil)
			emptyTex = [[VVMTLPool global] bgra8TexSized:CGSizeMake(64,64)];
		ISFImageRef		imgRef = std::make_shared<ISFImage>(emptyTex);
		imgInfoRef = std::static_pointer_cast<VVISF::ISFImageInfo>(imgRef);
		tmpAttr->setCurrentImageRef(imgInfoRef);
	}
	
	
	//	continue prepping values for the shader to read with the attribute values by populating the CPU-side UBO (we'll copy it to the GPU each pass)
	VVISF::ISFShaderRenderInfo		*renderInfoPtr = (VVISF::ISFShaderRenderInfo *)uboDataBuffer;
	renderInfoPtr->PASSINDEX = _passIndex;
	renderInfoPtr->RENDERSIZE[0] = localRenderSize.width;
	renderInfoPtr->RENDERSIZE[1] = localRenderSize.height;
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
		case VVISF::ISFValType_Event:	{
				uint		*wPtr = (uint*)(uboBaseAttrPtr + attr.offsetInBuffer());
				if (val.isEventVal())	{
					*wPtr = 1;
				}
				else	{
					*wPtr = (val.getBoolVal()) ? 1 : 0;
				}
				//	events are one-frame-only, so immediately give the attr a null value...
				attr.setCurrentVal(VVISF::CreateISFValNull());
			}
			break;
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
		//	the data values describing these images are written to the UBO at the same time that the texture 
		//	they'll use is set asside and associated with specific RCE vert/frag texture indexes
		case VVISF::ISFValType_Cube:
		case VVISF::ISFValType_Image:
		case VVISF::ISFValType_Audio:
		case VVISF::ISFValType_AudioFFT:
			break;
		}
	}
	
	
	//	this block pushes the passed texture to the RCE and writes info about it to the UBO, starting at the passed offset
	void		(^PrepNamedTexForRenderAtOffset)(const VVISF::ISFImageInfoRef &, const std::string &, const size_t &) = ^(const VVISF::ISFImageInfoRef & imgInfoRef, const std::string & name, const size_t & uboOffset)	{
		//	try to figure out the index in the render encoder at which this pass's texture needs to be attached
		NSString			*attrName = [NSString stringWithUTF8String:name.c_str()];
		//NSLog(@"PrepNamedTexForRenderAtOffset() ... %@",attrName);
		NSNumber			*tmpNum = nil;
		tmpNum = [localCachedObj.fragTextureVarIndexDict objectForKey:attrName];
		uint32_t			fragRenderEncoderIndex = (tmpNum==nil) ? std::numeric_limits<uint32_t>::max() : tmpNum.unsignedIntValue;
		tmpNum = [localCachedObj.vertTextureVarIndexDict objectForKey:attrName];
		uint32_t			vertRenderEncoderIndex = (tmpNum==nil) ? std::numeric_limits<uint32_t>::max() : tmpNum.unsignedIntValue;
		
		//	get the current image from the attr- if it's not the expected type (ISFImage class), skip it- otherwise, recast to an ISFImageRef
		VVISF::ISFImageInfo		*imgInfoPtr = imgInfoRef.get();
		ISFImage		*imgPtr = (imgInfoPtr==nullptr) ? nullptr : dynamic_cast<ISFImage*>(imgInfoPtr);
		if (imgPtr == nullptr)	{
			std::cout << "ERR: attr missing img, " << __PRETTY_FUNCTION__ << std::endl;
			return;
		}
		ISFImageRef		imgRef = std::static_pointer_cast<ISFImage>(imgInfoRef);
		
		//	if there's no image (no texture) associated with the render pass, skip it
		id<VVMTLTextureImage>		tmpImgBuffer = imgPtr->img;
		id<MTLTexture>		tmpTex = tmpImgBuffer.texture;
		if (tmpTex == nil)
			return;
		
		#if DEBUG
		//	assign the attribute's name to the texture's label to make debugging easier
		tmpTex.label = [NSString stringWithUTF8String:name.c_str()];
		//NSLog(@"\t\t\ttex is named %@, index is %ld",tmpTex.label,fragRenderEncoderIndex);
		#endif
		
		//	add the img to the tex cache so it's guaranteed to stick around through the completion of rendering
		ISFMSLSceneImgRef		*objCImgRef = [ISFMSLSceneImgRef createWithImgRef:imgRef];
		if (![singleFrameTexCache containsObject:objCImgRef])
			[singleFrameTexCache addObject:objCImgRef];
		if (vertRenderEncoderIndex != std::numeric_limits<uint32_t>::max())	{
			[vertRCEIndexToTexDict setObject:objCImgRef forKey:@( vertRenderEncoderIndex )];
		}
		if (fragRenderEncoderIndex != std::numeric_limits<uint32_t>::max())	{
			[fragRCEIndexToTexDict setObject:objCImgRef forKey:@( fragRenderEncoderIndex )];
		}
		
		//	if the ubo offset we were passed appears to be valid, update the texture's data in the UBO
		if (uboOffset != std::numeric_limits<uint32_t>::max())	{
			VVISF::ISFShaderImgInfo		*wPtr = (VVISF::ISFShaderImgInfo*)(uboBaseAttrPtr + uboOffset);
			NSSize			texSize = (tmpImgBuffer==nil) ? NSMakeSize(1,1) : NSMakeSize(tmpImgBuffer.width, tmpImgBuffer.height);
			NSRect			imgRect = (tmpImgBuffer==nil) ? NSMakeRect(0,0,texSize.width,texSize.height) : tmpImgBuffer.srcRect;
			BOOL			flipped = (tmpImgBuffer==nil) ? NO : tmpImgBuffer.flipV;
			
			//	these apply the src rect's coords as normalized vals
			wPtr->rect[0] = imgRect.origin.x/texSize.width;
			wPtr->rect[1] = imgRect.origin.y/texSize.height;
			wPtr->rect[2] = imgRect.size.width/texSize.width;
			wPtr->rect[3] = imgRect.size.height/texSize.height;
			
			wPtr->size[0] = imgRect.size.width;
			wPtr->size[1] = imgRect.size.height;
			
			//wPtr->flip = (flipped) ? 1 : 0;
			wPtr->flip = (flipped) ? 0 : 1;	//	the GLSL source code uses a bottom-left origin for sampling, but metal uses top-left origin- so we flip things here!
		}
	};
	//	this block pulls the current image from the passed attribute ref (populates CPU-side UBO with data describing tex, puts tex in dicts that we use at runtime to pass the tex to the RCE at the appropriate index)
	void		(^PrepAttrRefImgForRender)(VVISF::ISFAttrRef) = ^(VVISF::ISFAttrRef attr)	{
		//	if the atttr doesn't have a name, skip it
		std::string		name = attr->name();
		if (name.length() < 1)
			return;
		//	get the current image from the attr- if it's not the expected type (ISFImage class), skip it- otherwise, recast to an ISFImageRef
		VVISF::ISFImageInfoRef	imgInfoRef = attr->getCurrentImageRef();
		if (imgInfoRef == nullptr)
			return;
		size_t			offset = attr->offsetInBuffer();
		//NSLog(@"\t\tprepping attr named %@",[NSString stringWithUTF8String:name.c_str()]);
		PrepNamedTexForRenderAtOffset(imgInfoRef, name, offset);
	};
	//	this block pulls the current image from the passed render pass ref (populates CPU-side UBO with data describing tex, puts tex in dicts that we use at runtime to pass the tex to the RCE at the appropriate index)
	void		(^PrepPassRefImgForRender)(VVISF::ISFPassTargetRef) = ^(VVISF::ISFPassTargetRef passTarget)	{
		//	if the atttr doesn't have a name, skip it
		std::string		name = passTarget->name();
		if (name.length() < 1)
			return;
		//	get the current image from the attr- if it's not the expected type (ISFImage class), skip it- otherwise, recast to an ISFImageRef
		VVISF::ISFImageInfoRef	imgInfoRef = passTarget->image();
		if (imgInfoRef == nullptr)
			return;
		size_t			offset = passTarget->offsetInBuffer();
		//NSLog(@"\t\tprepping render pass named %@",[NSString stringWithUTF8String:name.c_str()]);
		PrepNamedTexForRenderAtOffset(imgInfoRef, name, offset);
	};
	
	
	//	run through all of the image-based attributes, pushing their textures to the RCE and vals to the UBO
	for (const VVISF::ISFAttrRef & attr : doc->imageImports())	{
		PrepAttrRefImgForRender(attr);
	}
	for (const VVISF::ISFAttrRef & attr : doc->imageInputs())	{
		PrepAttrRefImgForRender(attr);
	}
	for (const VVISF::ISFAttrRef & attr : doc->audioInputs())	{
		PrepAttrRefImgForRender(attr);
	}
	
	//	run through the doc's render passes- if it has a name and a texture and we can figure out the associated index, attach it
	for (const VVISF::ISFPassTargetRef & passTarget : doc->renderPasses())	{
		PrepPassRefImgForRender(passTarget);
	}
	
	
	BOOL		sceneRenderTargetIsFloat = IsMTLPixelFormatFloatingPoint(self.renderTarget.texture.pixelFormat);
	//	run through each pass, doing the actual rendering!
	_passIndex = 0;
	for (ISFMSLScenePassTarget *objCRenderPass in passes)	{
		//	get the basic properties of the pass
		VVISF::ISFPassTargetRef		&renderPassRef = objCRenderPass.passTargetRef;
		VVISF::ISFImageInfo		renderPassTargetInfo = renderPassRef->targetImageInfo();
		NSSize			renderPassSize = NSMakeSize(renderPassTargetInfo.width, renderPassTargetInfo.height);
		//NSLog(@"\t\trendering pass %d",_passIndex);
		
		BOOL		lastPassFlag = (_passIndex == (passes.count - 1));
		BOOL		sceneRenderTargetMatchesLastPassPSO = (sceneRenderTargetIsFloat == objCRenderPass.float32);
		//	allocate a new texture for the render pass- this is what we're going to render into
		id<VVMTLTextureImage>		newTex = nil;
		//	if this is the last pass, try to render into the scene's render target (if it's of a compatible pixel format!)
		if (lastPassFlag)	{
			if (sceneRenderTargetMatchesLastPassPSO)	{
				newTex = self.renderTarget;
			}
		}
		//	make sure we create a new texture for the render pass
		if (newTex == nil)	{
			if (objCRenderPass.float32)
				newTex = [[VVMTLPool global] rgbaFloatTexSized:CGSizeMake(renderPassTargetInfo.width, renderPassTargetInfo.height)];
			else
				newTex = [[VVMTLPool global] bgra8TexSized:CGSizeMake(renderPassTargetInfo.width, renderPassTargetInfo.height)];
		}
		
		//	make a render pass descriptor and then a command encoder, configure the viewport & attach the PSO
		MTLRenderPassDescriptor			*passDesc = [MTLRenderPassDescriptor renderPassDescriptor];
		MTLRenderPassColorAttachmentDescriptor		*attachDesc = passDesc.colorAttachments[0];
		attachDesc.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
		attachDesc.texture = newTex.texture;
		attachDesc.loadAction = (localCachedObj.hasCustomVertShader) ? MTLLoadActionClear : MTLLoadActionDontCare;
		
		id<MTLRenderCommandEncoder>		renderEncoder = [self.commandBuffer renderCommandEncoderWithDescriptor:passDesc];
		[renderEncoder setViewport:(MTLViewport){ 0.f, 0.f, (double)renderPassTargetInfo.width, (double)renderPassTargetInfo.height, -1.f, 1.f }];
		[renderEncoder setRenderPipelineState:objCRenderPass.pso];
		#if DEBUG
		renderEncoder.label = [NSString stringWithFormat:@"Pass %d named \"%@\"",_passIndex,objCRenderPass.name];
		#endif
		
		//	attach the appropriate quad verts buffer to the render encoder
		NSValue			*resValue = [NSValue valueWithSize:renderPassSize];
		id<VVMTLBuffer>	quadVertsBuffer = [resToQuadVertsDict objectForKey:resValue];
		[renderEncoder
			setVertexBuffer:quadVertsBuffer.buffer
			offset:0
			atIndex:localCachedObj.vtxFuncMaxBufferIndex + 1];
		
		//	iterate across the dicts of index-to-texture mappings, pushing the textures to the RCE
		[vertRCEIndexToTexDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNum, ISFMSLSceneImgRef *objCImgRef, BOOL *stop)	{
			id<VVMTLTextureImage>		tmpImgBuffer = objCImgRef.img;
			id<MTLTexture>		tmpTex = tmpImgBuffer.texture;
			if (tmpTex == nil)
				return;
			[renderEncoder
				useResource:tmpTex
				usage:MTLResourceUsageRead
				stages:MTLRenderStageVertex];
			[renderEncoder
				setVertexTexture:tmpTex
				atIndex:indexNum.intValue];
		}];
		[fragRCEIndexToTexDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNum, ISFMSLSceneImgRef *objCImgRef, BOOL *stop)	{
			id<VVMTLTextureImage>		tmpImgBuffer = objCImgRef.img;
			id<MTLTexture>		tmpTex = tmpImgBuffer.texture;
			if (tmpTex == nil)
				return;
			[renderEncoder
				useResource:tmpTex
				usage:MTLResourceUsageRead
				stages:MTLRenderStageFragment];
			[renderEncoder
				setFragmentTexture:tmpTex
				atIndex:indexNum.intValue];
		}];
		//NSLog(@"\t\t\tfragRCEIndexToTexDict is %@",fragRCEIndexToTexDict);
		
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
		#if DEBUG
		uboMtlBuffer.label = [NSString stringWithFormat:@"Pass %d UBO",_passIndex];
		#endif
		
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
		PrepPassRefImgForRender(renderPassRef);
		
		//	...if this was the last pass, but the scene's render target didn't match the last pass's PSO (ex: one-pass ISF that renders to a persistent float buffer, like "Comet Trail.fs"), so we need to copy from the last pass to the render target
		if (lastPassFlag && !sceneRenderTargetMatchesLastPassPSO)	{
			if (_copierScene == nil)	{
				_copierScene = [[CopierMTLScene alloc] initWithDevice:RenderProperties.global.device];
			}
			[_copierScene
				copyImg:newTex
				toImg:self.renderTarget
				allowScaling:YES
				sizingMode:SizingModeFit
				inCommandBuffer:self.commandBuffer];
		}
		
		++_passIndex;
	}
	
	//	...now that we're done rendering, run back through the doc's render passes, and give null images to all of the non-persistent render passes to free up their textures
	for (const VVISF::ISFPassTargetRef & passTarget : doc->renderPasses())	{
		if (passTarget->persistentFlag())
			continue;
		//id<VVMTLTextureImage>		nilPlaceholder = nil;
		VVISF::ISFImageInfoRef	emptyImg = std::make_shared<ISFImage>((id<VVMTLTextureImage>)nil);
		passTarget->setImage(emptyImg);
	}
	
	//	add the single frame cache array to the completion handler, so we send all the textures we were hanging onto during rendering back to the pool
	[self.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> completed)	{
		//NSDate			*endDate = [NSDate date];
		//NSLog(@"rendering took %0.4f seconds",[startDate timeIntervalSinceDate:endDate]);
		
		NSMutableArray<ISFMSLSceneImgRef*>		*localSingleFrameTexCache = singleFrameTexCache;
		NSMutableDictionary<NSNumber*,ISFMSLSceneImgRef*>	*localVertRCEIndexToTexDict = vertRCEIndexToTexDict;
		NSMutableDictionary<NSNumber*,ISFMSLSceneImgRef*>	*localFragRCEIndexToTexDict = fragRCEIndexToTexDict;
		NSMutableDictionary<NSValue*,id<VVMTLBuffer>>	*localResToQuadVertsDict = resToQuadVertsDict;
		localResToQuadVertsDict = nil;
		localSingleFrameTexCache = nil;
		localVertRCEIndexToTexDict = nil;
		localFragRCEIndexToTexDict = nil;
	}];
	
	
	
	//	don't forget to update the rendered frame index!
	++_renderFrameIndex;
}


#pragma mark - superclass overrides


- (id<VVMTLTextureImage>) createAndRenderToTextureSized:(NSSize)inSize inCommandBuffer:(id<MTLCommandBuffer>)cb	{
	VVMTLPool			*pool = [VVMTLPool global];
	if (pool == nil)
		return nil;
	
	if (doc == nullptr)
		return nil;
	
	id<VVMTLTextureImage>		returnMe = nil;
	//	get the last pass, figure out whether we need a float texture or not
	const auto &		passes = doc->renderPasses();
	const auto &		pass = passes[passes.size()-1];
	if (pass->floatFlag())
		returnMe = [pool rgbaFloatTexSized:inSize];
	else
		returnMe = [pool bgra8TexSized:inSize];
	
	if (returnMe == nil)
		return returnMe;
	
	[self renderToTexture:returnMe inCommandBuffer:cb];
	
	return returnMe;
	
	//id<VVMTLTextureImage>		returnMe = [pool bgra8TexSized:inSize];
	//if (returnMe == nil)
	//	return nil;
	//[self renderToBuffer:returnMe inCommandBuffer:cb];
	//return returnMe;
}
- (id<VVMTLTextureImage>) createAndRenderToTextureSized:(NSSize)inSize atTime:(double)inTimeInSeconds inCommandBuffer:(id<MTLCommandBuffer>)cb	{
	_baseTime = VVISF::Timestamp() - VVISF::Timestamp(inTimeInSeconds);
	return [self createAndRenderToTextureSized:inSize inCommandBuffer:cb];
}
- (void) renderToTexture:(id<VVMTLTextureImage>)n inCommandBuffer:(id<MTLCommandBuffer>)cb	{
	[super renderToTexture:n inCommandBuffer:cb];
}
- (void) renderToTexture:(id<VVMTLTextureImage>)n atTime:(double)inTimeInSeconds inCommandBuffer:(id<MTLCommandBuffer>)cb	{
	_baseTime = VVISF::Timestamp() - VVISF::Timestamp(inTimeInSeconds);
	[self renderToTexture:n inCommandBuffer:cb];
}


#pragma mark - accessors


- (id<ISFMSLScenePassTarget>) passAtIndex:(NSUInteger)n	{
	if (n == NSNotFound)
		return nil;
	if (n <= passes.count)
		return nil;
	
	return [passes objectAtIndex:n];
}
- (id<ISFMSLScenePassTarget>) passNamed:(NSString *)n	{
	if (n == nil)
		return nil;
	if (n.length < 1)
		return nil;
	
	for (id<ISFMSLScenePassTarget> pass in passes)	{
		NSString		*passName = pass.name;
		if (passName != nil && [passName isEqualToString:n])
			return pass;
	}
	
	return nil;
}


- (id<ISFMSLSceneAttrib>) inputNamed:(NSString *)n	{
	if (n == nil)
		return nil;
	if (n.length < 1)
		return nil;
	
	for (id<ISFMSLSceneAttrib> input in inputs)	{
		NSString		*inputName = input.name;
		if (inputName != nil && [inputName isEqualToString:n])
			return input;
	}
	
	return nil;
}
- (NSArray<id<ISFMSLSceneAttrib>> *) inputsOfType:(ISFValType)n	{
	NSMutableArray		*returnMe = [[NSMutableArray alloc] init];
	for (id<ISFMSLSceneAttrib> input in inputs)	{
		if (input.type == n)
			[returnMe addObject:input];
	}
	return returnMe;
}


- (NSArray<id<ISFMSLScenePassTarget>> *) passes	{
	return [NSArray arrayWithArray:passes];
}
- (NSArray<id<ISFMSLSceneAttrib>> *) inputs	{
	return [NSArray arrayWithArray:inputs];
}


- (id<ISFMSLSceneVal>) valueForInputNamed:(NSString *)n	{
	if (n == nil)
		return nil;
	
	std::string			tmpName { n.UTF8String };
	VVISF::ISFAttrRef	tmpAttr = doc->input(tmpName);
	VVISF::ISFVal		tmpVal = (tmpAttr==nullptr) ? VVISF::CreateISFValNull() : tmpAttr->currentVal();
	//VVISF::ISFVal	tmpVal = doc->valueForInputNamed(tmpName);
	return [ISFMSLSceneVal createWithISFVal:tmpVal];
}
- (void) setValue:(id<ISFMSLSceneVal>)inVal forInputNamed:(NSString *)inName	{
	if (inName == nil || inVal == nil)
		return;
	
	id<ISFMSLSceneAttrib>		attr = [self inputNamed:inName];
	attr.currentVal = inVal;
	//attr.currentImageRef = inVal;
}


@end
