//
//  ISFMSLScene.h
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import <VVMetalKit/VVMetalKit.h>

#import <ISFMSLKit/ISFMSLSceneVal.h>
#import <ISFMSLKit/ISFMSLSceneAttrib.h>
#import <ISFMSLKit/ISFMSLScenePassTarget.h>

NS_ASSUME_NONNULL_BEGIN




/**		This class is used to render ISFs to Metal textures.
*/




@interface ISFMSLScene : VVMTLScene

///	Returns an instance of this class configured to use the passed Metal device to render.
- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice;

///	Loads the ISF at the passed URL.  The timer used to track the ISF's internal time is automatically reset.
- (void) loadURL:(NSURL * _Nullable)n;
///	Loads the ISF at the passed URL, and optionally resets the timer used to track the ISF's internal time.
- (void) loadURL:(NSURL * _Nullable)n resetTimer:(BOOL)r;

@property (readonly) NSURL * url;
///	Returns a YES if there was an error compiling the URL that is currently loaded.
@property (readonly) BOOL compilerError;
///	The description of the ISF, as provided by the JSON blob in the ISF file.
@property (readonly) NSString * fileDescription;
///	The accredition of the ISF, as provided by the JSON blob in the ISF file.
@property (readonly) NSString * credit;
///	The version of the currently-loaded ISF file, as provided by the JSON blob in the ISF file.
@property (readonly) NSString * vsn;
///	The categories that the ISF file falls within, as provided by the JSON blob in the ISF file.
@property (readonly) NSArray<NSString*> * categoryNames;

@property (readonly) NSArray<id<ISFMSLScenePassTarget>> * passes;
///	This array of attributes describes all of the ISF file's inputs.  If you want to change the value of an ISF file's input, use -[ISFMSLScene setValue:forInputNamed:]
@property (readonly) NSArray<id<ISFMSLSceneAttrib>> * inputs;

///	This is the preferred method for rendering an ISF to a texture
- (id<VVMTLTextureImage>) createAndRenderToTextureSized:(NSSize)inSize inCommandBuffer:(id<MTLCommandBuffer>)cb;
///	This method also renders the ISF to a texture, but allows the user to specify a target time at which the ISF should be rendered- as such, it's useful primary for non-realtime rendering.
- (id<VVMTLTextureImage>) createAndRenderToTextureSized:(NSSize)inSize atTime:(double)inTimeInSeconds inCommandBuffer:(id<MTLCommandBuffer>)cb;

///	This method renders the receiver to the passed texture.
- (void) renderToTexture:(nullable id<VVMTLTextureImage>)n inCommandBuffer:(id<MTLCommandBuffer>)cb;
///	This method renders the receiver to the passed texture, and allows the user to override the ISF's internal time- it's useful primarily for non-realtime rendering.
- (void) renderToTexture:(nullable id<VVMTLTextureImage>)n atTime:(double)inTimeInSeconds inCommandBuffer:(id<MTLCommandBuffer>)cb;

- (id<ISFMSLScenePassTarget>) passAtIndex:(NSUInteger)n;
- (id<ISFMSLScenePassTarget>) passNamed:(NSString *)n;

///	Retrieves the input with the passed name.
- (id<ISFMSLSceneAttrib>) inputNamed:(NSString *)n;
///	Retrieves all of the inputs matching the passed type.
- (NSArray<id<ISFMSLSceneAttrib>> *) inputsOfType:(ISFValType)n;

///	Retrives the current value for the input with the passed name (or nil).
- (id<ISFMSLSceneVal>) valueForInputNamed:(NSString *)n;
///	Updates the input with the passed name with the passed value.  Doesn't do any type-checking- make sure you only pass values of the appropriate type to the scene!
- (void) setValue:(id<ISFMSLSceneVal>)inVal forInputNamed:(NSString *)inName;

@end




NS_ASSUME_NONNULL_END
