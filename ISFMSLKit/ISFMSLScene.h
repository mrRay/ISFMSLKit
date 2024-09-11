//
//  ISFMSLScene.h
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import <VVMetalKit/VVMetalKit.h>

#import <ISFMSLKit/ISFMSLSceneImgRef.h>
#import <ISFMSLKit/ISFMSLSceneVal.h>
#import <ISFMSLKit/ISFMSLSceneAttrib.h>
#import <ISFMSLKit/ISFMSLScenePassTarget.h>

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLScene : VVMTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice;

- (void) loadURL:(NSURL * _Nullable)n;
- (void) loadURL:(NSURL * _Nullable)n resetTimer:(BOOL)r;
@property (readonly) NSURL * url;
@property (readonly) BOOL compilerError;
@property (readonly) NSString * fileDescription;
@property (readonly) NSString * credit;
@property (readonly) NSString * vsn;
@property (readonly) NSArray<NSString*> * categoryNames;

@property (readonly) NSArray<id<ISFMSLScenePassTarget>> * passes;
@property (readonly) NSArray<id<ISFMSLSceneAttrib>> * inputs;

- (id<VVMTLTextureImage>) createAndRenderToTextureSized:(NSSize)inSize inCommandBuffer:(id<MTLCommandBuffer>)cb;
- (id<VVMTLTextureImage>) createAndRenderToTextureSized:(NSSize)inSize atTime:(double)inTimeInSeconds inCommandBuffer:(id<MTLCommandBuffer>)cb;
- (void) renderToTexture:(id<VVMTLTextureImage>)n inCommandBuffer:(id<MTLCommandBuffer>)cb;
- (void) renderToTexture:(id<VVMTLTextureImage>)n atTime:(double)inTimeInSeconds inCommandBuffer:(id<MTLCommandBuffer>)cb;

- (id<ISFMSLScenePassTarget>) passAtIndex:(NSUInteger)n;
- (id<ISFMSLScenePassTarget>) passNamed:(NSString *)n;

- (id<ISFMSLSceneAttrib>) inputNamed:(NSString *)n;
- (NSArray<id<ISFMSLSceneAttrib>> *) inputsOfType:(ISFValType)n;

- (id<ISFMSLSceneVal>) valueForInputNamed:(NSString *)n;
- (void) setValue:(id<ISFMSLSceneVal>)inVal forInputNamed:(NSString *)inName;

@end




NS_ASSUME_NONNULL_END
