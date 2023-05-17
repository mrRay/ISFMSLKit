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




@interface ISFMSLScene : MTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice;

- (void) loadURL:(NSURL *)n;
- (NSURL *) url;

@property (readonly) NSArray<id<ISFMSLScenePassTarget>> * passes;
@property (readonly) NSArray<id<ISFMSLSceneAttrib>> * inputs;

- (id<ISFMSLScenePassTarget>) passAtIndex:(NSUInteger)n;
- (id<ISFMSLScenePassTarget>) passNamed:(NSString *)n;

- (id<ISFMSLSceneAttrib>) inputNamed:(NSString *)n;

- (id<ISFMSLSceneVal>) valueForInputNamed:(NSString *)n;
- (void) setValue:(id<ISFMSLSceneVal>)inVal forInputNamed:(NSString *)inName;

@end




NS_ASSUME_NONNULL_END
