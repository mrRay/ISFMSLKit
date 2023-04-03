//
//  ISFMTLScene.h
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import <VVMetalKit/VVMetalKit.h>

#import "ISFMTLSceneImgRef.h"
#import "ISFMTLSceneVal.h"
#import "ISFMTLSceneAttrib.h"
#import "ISFMTLScenePassTarget.h"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLScene : MTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice isfURL:(NSURL *)inURL;

@property (readonly) NSArray<id<ISFMTLScenePassTarget>> * passes;
@property (readonly) NSArray<id<ISFMTLSceneAttrib>> * inputs;

- (id<ISFMTLSceneVal>) valueForInputNamed:(NSString *)n;
- (void) setValue:(id<ISFMTLSceneVal>)inVal forInputNamed:(NSString *)inName;

@end




NS_ASSUME_NONNULL_END
