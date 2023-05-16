//
//  ISFMTLScene.h
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import <VVMetalKit/VVMetalKit.h>

#import <ISFMSLKit/ISFMTLSceneImgRef.h>
#import <ISFMSLKit/ISFMTLSceneVal.h>
#import <ISFMSLKit/ISFMTLSceneAttrib.h>
#import <ISFMSLKit/ISFMTLScenePassTarget.h>

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLScene : MTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice;

- (void) loadURL:(NSURL *)n;
- (NSURL *) url;

@property (readonly) NSArray<id<ISFMTLScenePassTarget>> * passes;
@property (readonly) NSArray<id<ISFMTLSceneAttrib>> * inputs;

- (id<ISFMTLScenePassTarget>) passAtIndex:(NSUInteger)n;
- (id<ISFMTLScenePassTarget>) passNamed:(NSString *)n;

- (id<ISFMTLSceneAttrib>) inputNamed:(NSString *)n;

- (id<ISFMTLSceneVal>) valueForInputNamed:(NSString *)n;
- (void) setValue:(id<ISFMTLSceneVal>)inVal forInputNamed:(NSString *)inName;

@end




NS_ASSUME_NONNULL_END
