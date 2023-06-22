//
//  ISFMSLSceneVal_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import "ISFMSLSceneVal_priv.h"
#import "ISFMSLSceneVal.h"
#import "ISFMSLSceneImgRef_priv.h"
#import "ISFImage.h"




@implementation ISFMSLSceneVal


#pragma mark - class methods


+ (instancetype) createWithISFVal:(VVISF::ISFVal &)n	{
	return [[ISFMSLSceneVal alloc] initWithISFVal:n];
}


+ (id<ISFMSLSceneVal>) createWithBool:(BOOL)n	{
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValBool(n);
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:tmpVal];
	return returnMe;
}
+ (id<ISFMSLSceneVal>) createWithLong:(int32_t)n	{
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValLong(n);
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:tmpVal];
	return returnMe;
}
+ (id<ISFMSLSceneVal>) createWithFloat:(double)n	{
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValFloat(n);
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:tmpVal];
	return returnMe;
}
+ (id<ISFMSLSceneVal>) createWithPoint2D:(NSPoint)n	{
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValPoint2D(n.x, n.y);
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:tmpVal];
	return returnMe;
}
+ (id<ISFMSLSceneVal>) createWithColor:(NSColor *)n	{
	CGFloat		components[8];
	if (n == nil)	{
		for (int i=0; i<4; ++i)	{
			components[i] = 0.;
		}
	}
	else	{
		[n getComponents:components];
	}
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValColor( components[0], components[1], components[2], components[3] );
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:tmpVal];
	return returnMe;
}
+ (id<ISFMSLSceneVal>) createWithImg:(MTLImgBuffer *)n	{
	if (n == nil)
		return nil;
	ISFImageRef			tmpImgRef = std::make_shared<ISFImage>(n);
	VVISF::ISFVal		tmpVal = VVISF::CreateISFValImage(tmpImgRef);
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:tmpVal];
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
- (NSString *) description	{
	std::string		tmpStr = VVISF::FmtString("<ISFVal %s/%s>", _localVal.getTypeString().c_str(), _localVal.getValString().c_str());
	return [NSString stringWithUTF8String:tmpStr.c_str()];
}


#pragma mark - key/val


- (VVISF::ISFVal) isfValue	{
	return _localVal;
}


#pragma mark - ISFMSLSceneVal protocol


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
- (id<ISFMSLSceneImgRef>) imgValue	{
	VVISF::ISFImageInfoRef		currentImageInfoRef = _localVal.getImageRef();
	VVISF::ISFImageInfo			*currentImageInfoPtr = currentImageInfoRef.get();
	if (currentImageInfoPtr == nullptr)
		return nil;
	
	//	if the attribute only has an ISFImageInfo instance, instead of a full-blown ISFImage instance, bail & return nil
	if (typeid(*currentImageInfoPtr) != typeid(ISFImage))
		return nil;
	
	//	we need to recast the VVISF::ISFImageInfoRef to an ISFImageRef
	ISFImageRef			currentImageRef = std::static_pointer_cast<ISFImage>(currentImageInfoRef);
	return [ISFMSLSceneImgRef createWithImgRef:currentImageRef];
	
	
	
	
	//return [ISFMSLSceneImgRef createWithImgRef:_localVal.getImageRef()];
}


//@synthesize img;


#pragma mark - NSCopying


- (id) copyWithZone:(NSZone *)zone {
	ISFMSLSceneVal		*returnMe = [[ISFMSLSceneVal alloc] initWithISFVal:_localVal];
	//returnMe.img = self.img;
	return returnMe;
}


@end
