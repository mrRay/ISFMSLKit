//
//  ISFMTLSceneAttrib.h
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import <Foundation/Foundation.h>

#import <ISFMSLKit/ISFMTLSceneVal.h>
#import <ISFMSLKit/ISFMTLSceneImgRef.h>

#import <VVMetalKit/VVMetalKit.h>

NS_ASSUME_NONNULL_BEGIN




@protocol ISFMTLSceneAttrib <NSCopying>


//!	Returns the attribute's name, or null
@property (readonly) NSString * name;
//!	Returns the attribute's description, or null
@property (readonly) NSString * description;
//!	Returns the attribute's label, or null
@property (readonly) NSString * label;
//!	Returns the attribute's value type.
@property (readonly) ISFValType type;
//!	Sets/gets the attribute's current value.
@property (strong) id<ISFMTLSceneVal> currentVal;
//	updates this attribute's eval variable with the double val of "_currentVal", and returns a ptr to the eval variable
- (double) updateAndGetEvalVariable;
//!	Returns a true if this attribute's value is expressed with an image buffer
@property (readonly) BOOL shouldHaveImageBuffer;
//!	Sets/gets the receiver's image buffer
@property (strong) id<ISFMTLSceneImgRef> currentImageRef;
//!	Gets the attribute's min val
@property (readonly) id<ISFMTLSceneVal> minVal;
//!	Gets the attribute's max val
@property (readonly) id<ISFMTLSceneVal> maxVal;
//!	Gets the attribute's default val (the value which will be assigned to the attribute when it is first created and used for rendering)
@property (readonly) id<ISFMTLSceneVal> defaultVal;
//!	Gets the attribute's identity val (the value at which this attribute's effects are indistinguishable from its raw input).
@property (readonly) id<ISFMTLSceneVal> identityVal;
//!	Gets the attribute's labels as a std::vector of std::string values.  Only used if the attribute is a 'long'.
@property (readonly) NSArray<NSString*> * labelArray;
//!	Gets the attribute's values as a std::vector of int values.  Only used if the attribute is a 'long'.
@property (readonly) NSArray<NSNumber*> * valArray;

//!	Gets the offset (in bytes) at which this attribute's value is stored in the buffer that is sent to the GPU.  Convenience method- it is not populated by this class!
@property (readwrite) uint32_t offsetInBuffer;

//!	Returns a true if this attribute is used to send the input image to the filter.
@property (readonly) BOOL isFilterInputImage;
//!	Returns a true if this attribute is used to send the start image to the transition
@property (readonly) BOOL isTransStartImage;
//!	Returns a true if this attribute is used to send the end image to the transition
@property (readonly) BOOL isTransEndImage;
//!	Returns a true if this attribute is used to send the progress value to the transition
@property (readonly) BOOL isTransProgressFloat;


@end




NS_ASSUME_NONNULL_END
