//
//  ISFMTLSceneAttrib_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/14/23.
//

#import "ISFMTLSceneAttrib_priv.h"
#import "ISFMTLSceneAttrib.h"
#import "ISFMTLSceneVal.h"
#import "ISFMTLSceneVal_priv.h"
#import "ISFMTLSceneImgRef_priv.h"




//@interface ISFMTLSceneAttrib ()	{
//}




@implementation ISFMTLSceneAttrib


#pragma mark - class methods


+ (instancetype) createWithISFAttr:(VVISF::ISFAttrRef)n	{
	return [[ISFMTLSceneAttrib alloc] initWithISFAttr:n];
}


#pragma mark - init/dealloc


- (instancetype) initWithISFAttr:(VVISF::ISFAttrRef)n	{
	self = [super init];
	if (n == nullptr)
		self = nil;
	if (self != nil)	{
		_localAttr = n;
	}
	return self;
}


#pragma mark - key/value


- (VVISF::ISFAttrRef) isfAttrRef	{
	return _localAttr;
}


#pragma mark - ISFMTLSceneAttrib


//!	Returns the attribute's name, or null
- (NSString *) name	{
	return [NSString stringWithUTF8String:_localAttr->name().c_str()];
}
//!	Returns the attribute's description, or null
- (NSString *) description	{
	return [NSString stringWithUTF8String:_localAttr->getAttrDescription().c_str()];
}
//!	Returns the attribute's label, or null
- (NSString *) label	{
	return [NSString stringWithUTF8String:_localAttr->label().c_str()];
}
//!	Returns the attribute's value type.
- (ISFValType) type	{
	switch (_localAttr->type())	{
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
//!	Sets/gets the attribute's current value.
- (void) setCurrentVal:(id<ISFMTLSceneVal>)n	{
	if (n == nil)	{
		_localAttr->setCurrentVal(VVISF::CreateISFValNull());
		return;
	}
	ISFMTLSceneVal		*recast = (ISFMTLSceneVal*)n;
	_localAttr->setCurrentVal(recast.isfValue);
}
- (id<ISFMTLSceneVal>) currentVal	{
	return [ISFMTLSceneVal createWithISFVal:_localAttr->currentVal()];
}
//	updates this attribute's eval variable with the double val of "_currentVal", and returns a ptr to the eval variable
- (double) updateAndGetEvalVariable	{
	double			*valPtr = _localAttr->updateAndGetEvalVariable();
	if (valPtr == nullptr)
		return 0.0;
	return *valPtr;
}
//!	Returns a true if this attribute's value is expressed with an image buffer
- (BOOL) shouldHaveImageBuffer	{
	return (_localAttr->shouldHaveImageBuffer()) ? YES : NO;
}
//!	Sets/gets the receiver's image buffer
- (void) setCurrentImageRef:(id<ISFMTLSceneImgRef>)n	{
	if (n == nullptr)
		return;
	ISFMTLSceneImgRef		*recast = (ISFMTLSceneImgRef *)n;
	_localAttr->setCurrentImageRef(recast.isfImageRef);
}
- (id<ISFMTLSceneImgRef>) currentImageRef	{
	return [ISFMTLSceneImgRef createWithImgRef:_localAttr->getCurrentImageRef()];
}
//!	Gets the attribute's min val
- (id<ISFMTLSceneVal>) minVal	{
	return [ISFMTLSceneVal createWithISFVal:_localAttr->minVal()];
}
//!	Gets the attribute's max val
- (id<ISFMTLSceneVal>) maxVal	{
	return [ISFMTLSceneVal createWithISFVal:_localAttr->maxVal()];
}
//!	Gets the attribute's default val (the value which will be assigned to the attribute when it is first created and used for rendering)
- (id<ISFMTLSceneVal>) defaultVal	{
	return [ISFMTLSceneVal createWithISFVal:_localAttr->defaultVal()];
}
//!	Gets the attribute's identity val (the value at which this attribute's effects are indistinguishable from its raw input).
- (id<ISFMTLSceneVal>) identityVal	{
	return [ISFMTLSceneVal createWithISFVal:_localAttr->identityVal()];
}
//!	Gets the attribute's labels as a std::vector of std::string values.  Only used if the attribute is a 'long'.
- (NSArray<NSString*> *) labelArray	{
	NSMutableArray		*tmpArray = [NSMutableArray arrayWithCapacity:0];
	for (std::string label : _localAttr->labelArray())	{
		NSString		*tmpString = [NSString stringWithUTF8String:label.c_str()];
		if (tmpString != nil)
			[tmpArray addObject:tmpString];
	}
	return [NSArray arrayWithArray:tmpArray];
}
//!	Gets the attribute's values as a std::vector of int values.  Only used if the attribute is a 'long'.
- (NSArray<NSNumber*> *) valArray	{
	NSMutableArray		*tmpArray = [NSMutableArray arrayWithCapacity:0];
	for (int32_t val : _localAttr->valArray())	{
		NSNumber		*tmpNum = [NSNumber numberWithLong:val];
		if (tmpNum != nil)
			[tmpArray addObject:tmpNum];
	}
	return [NSArray arrayWithArray:tmpArray];
}

//!	Gets the offset (in bytes) at which this attribute's value is stored in the buffer that is sent to the GPU.  Convenience method- it is not populated by this class!
@synthesize offsetInBuffer;

//!	Returns a true if this attribute is used to send the input image to the filter.
- (BOOL) isFilterInputImage	{
	return (_localAttr->isFilterInputImage()) ? YES : NO;
}
//!	Returns a true if this attribute is used to send the start image to the transition
- (BOOL) isTransStartImage	{
	return (_localAttr->isTransStartImage()) ? YES : NO;
}
//!	Returns a true if this attribute is used to send the end image to the transition
- (BOOL) isTransEndImage	{
	return (_localAttr->isTransEndImage()) ? YES : NO;
}
//!	Returns a true if this attribute is used to send the progress value to the transition
- (BOOL) isTransProgressFloat	{
	return (_localAttr->isTransProgressFloat()) ? YES : NO;
}


@end
