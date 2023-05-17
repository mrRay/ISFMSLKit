//
//  ISFMSLSceneImgRef_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import "ISFMSLSceneImgRef_priv.h"
#import "ISFMSLSceneImgRef.h"
#import "ISFImage.h"
#import "VVISF.hpp"




@implementation ISFMSLSceneImgRef


#pragma mark - class methods


+ (instancetype) createWithImgRef:(ISFImageRef)n	{
	return [[ISFMSLSceneImgRef alloc] initWithImgRef:n];
}
+ (instancetype) createWithMTLImgBuffer:(MTLImgBuffer *)n	{
	return [[ISFMSLSceneImgRef alloc] initWithMTLImgBuffer:n];
}


#pragma mark - init/dealloc


- (instancetype) initWithImgRef:(ISFImageRef)n	{
	self = [super init];
	if (n == nullptr)
		self = nil;
	if (self != nil)	{
		_localImage = n;
	}
	return self;
}
- (instancetype) initWithMTLImgBuffer:(MTLImgBuffer *)n	{
	self = [super init];
	if (n == nil)
		self = nil;
	ISFImageRef		tmpImgRef = std::make_shared<ISFImage>(n);
	if (tmpImgRef == nullptr)	{
		self = nil;
		return self;
	}
	
	if (self != nil)	{
		_localImage = tmpImgRef;
	}
	
	return self;
}


- (NSString *) description	{
	return [NSString stringWithFormat:@"<ISFMSLSceneImgRef %@>",(_localImage==nullptr) ? nil : _localImage->img.texture.label];
}


#pragma mark - key/value


- (ISFImageRef) isfImageRef	{
	return _localImage;
}


#pragma mark - NSObject


- (BOOL) isEqualTo:(id)n	{
	if (n == nil)
		return NO;
	if (self == n)
		return YES;
	
	//	if it's another ISFMSLSceneImgRef...
	if (![n isKindOfClass:[self class]])	{
		return NO;
	}
	
	ISFMSLSceneImgRef		*recast = (ISFMSLSceneImgRef *)n;
	
	//	compare interior objects
	ISFImageRef		remoteImageRef = recast.isfImageRef;
	
	ISFImage		*imagePtr = _localImage.get();
	ISFImage		*remoteImagePtr = remoteImageRef.get();
	
	BOOL			imagePtrMatch = ((imagePtr==nullptr && remoteImagePtr==nullptr)
		|| (imagePtr!=nullptr && remoteImagePtr!=nullptr && *imagePtr==*remoteImagePtr));
	
	return imagePtrMatch;
}
- (BOOL) isEqual:(id)n	{
	return [self isEqualTo:n];
}


#pragma mark - ISFMSLSceneImgRef


- (uint32_t) width	{
	return _localImage->width;
}
- (uint32_t) height	{
	return _localImage->height;
}
- (uint32_t) depth	{
	return _localImage->depth;
}
- (BOOL) cubemap	{
	return (_localImage->cubemap) ? YES : NO;
}
- (NSString *) imagePath	{
	return (_localImage->imagePath==nullptr) ? nil : [NSString stringWithUTF8String:_localImage->imagePath->c_str()];
}
- (NSArray<NSString*> *) cubePaths	{
	if (_localImage->cubePaths == nullptr)
		return nil;
	
	NSMutableArray		*tmpArray = [[NSMutableArray alloc] init];
	for (std::string cubePath : *_localImage->cubePaths)	{
		NSString			*tmpString = [NSString stringWithUTF8String:cubePath.c_str()];
		if (tmpString != nil)
			[tmpArray addObject:tmpString];
	}
	return [NSArray arrayWithArray:tmpArray];
}
- (BOOL) hasValidSize	{
	return _localImage->sizeIsValid();
}


//@synthesize img;


- (MTLImgBuffer *) img	{
	//	if the underlying local image ptr's nil, return nil immediately
	VVISF::ISFImageInfo		*localImagePtr = _localImage.get();
	if (localImagePtr == nullptr)	{
		return nil;
	}
	
	//	if the ref we're storing is our subclass (ISFImage) which stores its own MTLImgBuffer, we can return that
	if (typeid(*localImagePtr) == typeid(ISFImage))	{
		ISFImage		*recast = static_cast<ISFImage*>(localImagePtr);
		return recast->img;
	}
	//else if (typeid(*localImagePtr) == typeid(VVISF::ISFImageInfo))	{
	//}
	
	return nil;
}


@end






id<ISFMSLSceneImgRef> CreateISFMSLSceneImgRefWithMTLImgBuffer(MTLImgBuffer * n)	{
	return [ISFMSLSceneImgRef createWithMTLImgBuffer:n];
}

