//
//  ISFMTLScenePass.h
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import <Foundation/Foundation.h>
#import <VVMetalKit/VVMetalKit.h>

#import "ISFMTLSceneImgRef.h"

NS_ASSUME_NONNULL_BEGIN




@protocol ISFMTLScenePass

@property (readonly) BOOL float32;
@property (readonly) BOOL persistent;
@property (readonly) NSString * name;
@property (readonly) id<ISFMTLSceneImgRef> image;

@property (strong,nullable) id<MTLRenderPipelineState> pso;	//	retained by this obj-c backend/not part of the VVISF base class
@property (strong,nullable) MTLImgBuffer * target;	//	retained by this obj-c backend/not part of the VVISF base class
@property (readwrite) int passIndex;	//	retained by this obj-c backend/not part of the VVISF base class

@end




NS_ASSUME_NONNULL_END
