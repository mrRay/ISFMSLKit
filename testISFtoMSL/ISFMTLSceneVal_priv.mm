//
//  ISFMTLSceneVal_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import "ISFMTLSceneVal_priv.h"
#import "ISFMTLSceneVal.h"
#import "ISFMTLSceneImgRef_priv.h"




@implementation ISFMTLSceneVal


#pragma mark - class methods


+ (instancetype) createWithISFVal:(VVISF::ISFVal &)n	{
	return [[ISFMTLSceneVal alloc] initWithISFVal:n];
}


//+ (id<ISFMTLSceneVal>) createWithDouble:(double)n	{
//	VVISF::ISFVal		tmpVal = VVISF::CreateISFValFloat(n);
//	return [[ISFMTLSceneVal alloc] initWithISFVal:tmpVal];
//}


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
	return [ISFMTLSceneImgRef createWithImgRef:_localVal.getImageRef()];
}


@end
