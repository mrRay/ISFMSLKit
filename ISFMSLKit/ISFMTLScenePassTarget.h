//
//  ISFMTLScenePassTarget.h
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import <Foundation/Foundation.h>
#import <VVMetalKit/VVMetalKit.h>

#import "ISFMTLSceneImgRef.h"

NS_ASSUME_NONNULL_BEGIN




@protocol ISFMTLScenePassTarget

@property (readonly) BOOL float32;
@property (readonly) BOOL persistent;
@property (readonly) NSString * name;
@property (readonly) NSSize targetSize;
@property (readonly) id<ISFMTLSceneImgRef> image;	//	if the dimensions of 'target' don't match the dimensions of 'image' then you need to resize 'target' to match 'image'!

@property (strong,nullable) id<MTLRenderPipelineState> pso;	//	retained by this obj-c backend/not part of the VVISF base lib
//@property (strong,nullable) id<MTLBuffer> vertexData;	//	retained by this obj-c backend/not part of the VVISF base lib.  stores vertex data needed to draw this render pass.
//@property (strong,nullable) MTLImgBuffer * target;	//	retained by this obj-c backend/not part of the VVISF base lib
@property (readwrite) int passIndex;	//	retained by this obj-c backend/not part of the VVISF base lib

@end




NS_ASSUME_NONNULL_END
