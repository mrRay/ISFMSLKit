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
#import "ISFMTLScenePass.h"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLScene : MTLScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice isfURL:(NSURL *)inURL;

@property (readonly) NSArray<id<ISFMTLScenePass>> * passes;
@property (readonly) NSArray<id<ISFMTLSceneAttrib>> * inputs;

@end




NS_ASSUME_NONNULL_END
