//
//  ISFMSLSceneVal.h
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import <Foundation/Foundation.h>

#import <ISFMSLKit/ISFMSLSceneImgRef.h>

#import <VVMetalKit/VVMetalKit.h>

NS_ASSUME_NONNULL_BEGIN




typedef NS_ENUM(NSInteger, ISFValType)	{
	ISFValType_None,	//!<	No data/unknown value type.
	ISFValType_Event,	//!<	No data, just an event.  sends a 1 the next render after the event is received, a 0 any other time it's rendered
	ISFValType_Bool,	//!<	A boolean choice, sends 1 or 0 to the shader
	ISFValType_Long,	//!<	Sends a long
	ISFValType_Float,	//!<	Sends a float
	ISFValType_Point2D,	//!<	Sends a 2 element vector
	ISFValType_Color,	//!<	Sends a 4 element vector representing an RGBA color
	ISFValType_Cube,	//!<	Sends a long- the texture number (like GL_TEXTURE0) of a cubemap texture to pass to the shader
	ISFValType_Image,	//!<	Sends a long- the texture number (like GL_TEXTURE0) to pass to the shader
	ISFValType_Audio,	//!<	Sends a long- the texture number (like GL_TEXTURE0) to pass to the shader
	ISFValType_AudioFFT	//!<	Sends a long- the texture number (like GL_TEXTURE0) to pass to the shader
};




@protocol ISFMSLSceneVal <NSCopying>

+ (id<ISFMSLSceneVal>) createWithBool:(BOOL)n;
+ (id<ISFMSLSceneVal>) createWithLong:(int32_t)n;
+ (id<ISFMSLSceneVal>) createWithFloat:(double)n;
+ (id<ISFMSLSceneVal>) createWithPoint2D:(NSPoint)n;
+ (id<ISFMSLSceneVal>) createWithColor:(NSColor *)n;
+ (id<ISFMSLSceneVal>) createWithImg:(MTLImgBuffer *)n;

@property (readonly) ISFValType type;
@property (readonly) double doubleValue;
@property (readonly) BOOL boolValue;
@property (readonly) int32_t longValue;
@property (readonly) double * pointValuePointer;
- (double) pointValueByIndex:(int)n;
@property (readonly) double * colorValuePointer;
- (double) colorValueByIndex:(int)n;
- (id<ISFMSLSceneImgRef>) imgValue;

//@property (strong,nullable) MTLImgBuffer * img;	//	retained by this obj-c backend/not part of the VVISF base lib

@end




NS_ASSUME_NONNULL_END
