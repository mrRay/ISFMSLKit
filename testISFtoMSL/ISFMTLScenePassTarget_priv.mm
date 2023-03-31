//
//  ISFMTLScenePassTarget_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import "ISFMTLScenePassTarget_priv.h"
#import "ISFMTLScenePassTarget.h"
#import "ISFMTLSceneImgRef_priv.h"




@implementation ISFMTLScenePassTarget


#pragma mark - class methods


+ (instancetype) createWithPassTarget:(VVISF::ISFPassTargetRef)n	{
	return [[ISFMTLScenePassTarget alloc] initWithPassTarget:n];
}


#pragma mark - init/dealloc


- (instancetype) initWithPassTarget:(VVISF::ISFPassTargetRef)n	{
	self = [super init];
	if (self != nil)	{
		_localPassTarget = n;
	}
	return self;
}


#pragma mark - key/value


- (VVISF::ISFPassTargetRef &) passTargetRef	{
	return _localPassTarget;
}


#pragma mark - ISFMTLScenePassTarget protocol


- (BOOL) float32	{
	return (_localPassTarget != nullptr && _localPassTarget->floatFlag()) ? YES : NO;
}
- (BOOL) persistent	{
	return (_localPassTarget != nullptr && _localPassTarget->persistentFlag()) ? YES : NO;
}
- (NSString *) name	{
	return (_localPassTarget==nullptr) ? nil : [NSString stringWithUTF8String:_localPassTarget->name().c_str()];
}
- (NSSize) targetSize	{
	NSSize		returnMe = NSMakeSize(1,1);
	VVISF::ISFImageInfo		targetImgInfo = _localPassTarget->targetImageInfo();
	if (targetImgInfo.width != std::numeric_limits<uint32_t>::max())
		returnMe.width = targetImgInfo.width;
	if (targetImgInfo.height != std::numeric_limits<uint32_t>::max())
		returnMe.height = targetImgInfo.height;
	return returnMe;
}
- (id<ISFMTLSceneImgRef>) image	{
	VVISF::ISFImageInfoRef		currentImageInfoRef = _localPassTarget->image();
	VVISF::ISFImageInfo			*currentImageInfoPtr = currentImageInfoRef.get();
	if (currentImageInfoPtr == nullptr)
		return nil;
	
	//	if the attribute only has an ISFImageInfo instance, instead of a full-blown ISFImage instance, bail & return nil
	if (typeid(*currentImageInfoPtr) != typeid(ISFImage))
		return nil;
	
	//	we need to recast the VVISF::ISFImageInfoRef to an ISFImageRef
	ISFImageRef			currentImageRef = std::static_pointer_cast<ISFImage>(currentImageInfoRef);
	return [ISFMTLSceneImgRef createWithImgRef:currentImageRef];
	
	
	
	
	
	//return (_localPassTarget==nullptr) ? nil : [ISFMTLSceneImgRef createWithImgRef:_localPassTarget->image()];
}


@synthesize pso;

//@synthesize vertexData;

//@synthesize target;

@synthesize passIndex;


@end
