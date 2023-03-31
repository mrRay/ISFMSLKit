//
//  ISFMTLSceneVal_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import "ISFMTLSceneVal_priv.h"
#import "ISFMTLSceneVal.h"
#import "ISFMTLSceneImgRef_priv.h"
#import "ISFImage.h"




@implementation ISFMTLSceneVal


#pragma mark - class methods


+ (instancetype) createWithISFVal:(VVISF::ISFVal &)n	{
	return [[ISFMTLSceneVal alloc] initWithISFVal:n];
}


//+ (id<ISFMTLSceneVal>) createWithDouble:(double)n	{
//	VVISF::ISFVal		tmpVal = VVISF::CreateISFValFloat(n);
//	return [[ISFMTLSceneVal alloc] initWithISFVal:tmpVal];
//}
+ (id<ISFMTLSceneVal>) createWithImg:(MTLImgBuffer *)n	{
	if (n == nil)
		return nil;
	
	ISFImageRef			tmpImgRef = std::make_shared<ISFImage>(n);
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValImage(tmpImgRef);
	
	//VVISF::ISFImageInfoRef	tmpImageRef = std::make_shared<VVISF::ISFImageInfo>(n.width, n.height);
	//VVISF::ISFVal		tmpVal = VVISF::CreateISFValImage(tmpImageRef);
	
	ISFMTLSceneVal		*returnMe = [[ISFMTLSceneVal alloc] initWithISFVal:tmpVal];
	//returnMe.img = n;
	return returnMe;
}


#pragma mark - init/dealloc


- (instancetype) initWithISFVal:(VVISF::ISFVal &)n	{
	self = [super init];
	if (self != nil)	{
		_localVal = n;
	}
	return self;
}


#pragma mark - key/val


- (VVISF::ISFVal) isfValue	{
	return _localVal;
}


#pragma mark - ISFMTLSceneVal protocol


- (ISFValType) type	{
	switch (_localVal.type())	{
	case VVISF::ISFValType_None:
		return ISFValType_None;
	case VVISF::ISFValType_Event:
		return ISFValType_Event;
	case VVISF::ISFValType_Bool:
		return ISFValType_Bool;
	case VVISF::ISFValType_Long:
		return ISFValType_Long;
	case VVISF::ISFValType_Float:
		return ISFValType_Float;
	case VVISF::ISFValType_Point2D:
		return ISFValType_Point2D;
	case VVISF::ISFValType_Color:
		return ISFValType_Color;
	case VVISF::ISFValType_Cube:
		return ISFValType_Cube;
	case VVISF::ISFValType_Image:
		return ISFValType_Image;
	case VVISF::ISFValType_Audio:
		return ISFValType_Audio;
	case VVISF::ISFValType_AudioFFT:
		return ISFValType_AudioFFT;
	}
	
}
- (double) doubleValue	{
	return _localVal.getDoubleVal();
}
- (BOOL) boolValue	{
	return (_localVal.getBoolVal()) ? YES : NO;
}
- (int32_t) longValue	{
	return _localVal.getLongVal();
}
- (double *) pointValuePointer	{
	return _localVal.getPointValPtr();
}
- (double) pointValueByIndex:(int)n	{
	return _localVal.getPointValByIndex(n);
}
- (double *) colorValuePointer	{
	return _localVal.getColorValPtr();
}
- (double) colorValueByIndex:(int)n	{
	return _localVal.getColorValByChannel(n);
}
- (id<ISFMTLSceneImgRef>) imgValue	{
	VVISF::ISFImageInfoRef		currentImageInfoRef = _localVal.getImageRef();
	VVISF::ISFImageInfo			*currentImageInfoPtr = currentImageInfoRef.get();
	if (currentImageInfoPtr == nullptr)
		return nil;
	
	//	if the attribute only has an ISFImageInfo instance, instead of a full-blown ISFImage instance, bail & return nil
	if (typeid(*currentImageInfoPtr) != typeid(ISFImage))
		return nil;
	
	//	we need to recast the VVISF::ISFImageInfoRef to an ISFImageRef
	ISFImageRef			currentImageRef = std::static_pointer_cast<ISFImage>(currentImageInfoRef);
	return [ISFMTLSceneImgRef createWithImgRef:currentImageRef];
	
	
	
	
	//return [ISFMTLSceneImgRef createWithImgRef:_localVal.getImageRef()];
}


//@synthesize img;


#pragma mark - NSCopying


- (id) copyWithZone:(NSZone *)zone {
	ISFMTLSceneVal		*returnMe = [[ISFMTLSceneVal alloc] initWithISFVal:_localVal];
	//returnMe.img = self.img;
	return returnMe;
}


@end
