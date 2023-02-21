//
//  ISFMTLScene.h
//  testISFtoMSL
//
//  Created by testadmin on 2/20/23.
//

#import <VVMetalKit/VVMetalKit.h>

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLScene : MTLRenderScene

- (nullable instancetype) initWithDevice:(id<MTLDevice>)inDevice isfURL:(NSURL *)inURL;

@end




NS_ASSUME_NONNULL_END
