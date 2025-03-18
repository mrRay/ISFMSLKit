//
//  ISFMSLSceneVal.h
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import <Foundation/Foundation.h>

#import <VVMetalKit/VVMetalKit.h>

NS_ASSUME_NONNULL_BEGIN




///	ISFValType enumerates the different possible "types" of values that are recognized by the ISF ecosystem
typedef NS_ENUM(NSInteger, ISFValType)	{
	ISFValType_None,	///	No data/unknown value type.
	ISFValType_Event,	///	No data, just an event.  sends a 1 the next render after the event is received, a 0 any other time it's rendered
	ISFValType_Bool,	///	A boolean choice, sends 1 or 0 to the shader
	ISFValType_Long,	///	Sends a long
	ISFValType_Float,	///	Sends a float
	ISFValType_Point2D,	///	Sends a 2 element vector
	ISFValType_Color,	///	Sends a 4 element vector representing an RGBA color
	ISFValType_Cube,	///	Sends a long- the texture number (like GL_TEXTURE0) of a cubemap texture to pass to the shader
	ISFValType_Image,	///	Sends a long- the texture number (like GL_TEXTURE0) to pass to the shader
	ISFValType_Audio,	///	Sends a long- the texture number (like GL_TEXTURE0) to pass to the shader
	ISFValType_AudioFFT	///	Sends a long- the texture number (like GL_TEXTURE0) to pass to the shader
};




/**	ISFMSLSceneVal describes a value- ISF inputs (`ISFMSLSceneAttrib` instances) have values which are passed to the shaders at runtime, affecting their visual output.  Basically a thing wrapper around `VVISF::ISFVal`
*/




@protocol ISFMSLSceneVal <NSCopying>

///	The type of the ISF value
@property (readonly) ISFValType type;
///	The value of the ISFMSLSceneVal instance as represented by a double.  If the receiver isn't a match for this value type, a best-guess approximation will be returned- this method works and returns a value no matter the type of the receiver.
@property (readonly) double doubleValue;
///	The value of the ISFMSLSceneVal instance as represented by a bool.  If the receiver isn't a match for this value type, a best-guess approximation will be returned- this method works and returns a value no matter the type of the receiver.
@property (readonly) BOOL boolValue;
///	The value of the ISFMSLSceneVal instance as represented by a 32-bit integer.  If the receiver isn't a match for this value type, a best-guess approximation will be returned- this method works and returns a value no matter the type of the receiver.
@property (readonly) int32_t longValue;

///	The value of the receiver as represented by a ptr to two doubles (representing a 2D point).  Returns nil if the receiver's type isn't ISFValType_Point2D.
@property (readonly) double * pointValuePointer;
///	If the receiver is an ISFValType_Point2D, this will fetch one of the point's values (by index).
- (double) pointValueByIndex:(int)n;
///	Returns an NSPoint describing the receiver's value as a 2D point.
@property (readonly) NSPoint point2DVal;

///	The value of the receiver as represented by a ptr to four doubles (representing a color).  Returns a nil if the receiver's type isn't ISFValType_Color.
@property (readonly) double * colorValuePointer;
///	If the receiver is an ISFValType_Color, this will fetch one element of the four values that comprise the receiver's color.
- (double) colorValueByIndex:(int)n;

///	Returns the value of the receiver as an `id<VVMTLTextureImage>` instance.
- (id<VVMTLTextureImage>) imgValue;
///	Returns the value of the receiver as an `id<MTLTexture>` instance.
- (id<MTLTexture>) textureValue;

@end




@interface ISFMSLSceneVal : NSObject <ISFMSLSceneVal>

///	Creates a boolean-type value
+ (id<ISFMSLSceneVal>) createWithBool:(BOOL)n;
///	Creates a long-type value
+ (id<ISFMSLSceneVal>) createWithLong:(int32_t)n;
///	Creates a float-type value
+ (id<ISFMSLSceneVal>) createWithFloat:(double)n;
///	Creates a value with a two-dimensional point
+ (id<ISFMSLSceneVal>) createWithPoint2D:(NSPoint)n;
///	Creates a color-type value
+ (id<ISFMSLSceneVal>) createWithColor:(NSColor *)n;
///	Creates a color-type value
+ (id<ISFMSLSceneVal>) createWithColorVals:(double*)n;
///	Creates an event-type value
+ (id<ISFMSLSceneVal>) createWithEvent;
///	Creates an image-type value with an `id<VVMTLTextureImage>`
+ (id<ISFMSLSceneVal>) createWithTextureImage:(id<VVMTLTextureImage>)n;
///	Creates an image-type value with an `id<MTLTexture>`
+ (id<ISFMSLSceneVal>) createWithTexture:(id<MTLTexture>)n;


@end




NS_ASSUME_NONNULL_END
