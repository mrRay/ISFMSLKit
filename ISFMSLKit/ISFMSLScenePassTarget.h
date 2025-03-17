//
//  ISFMSLScenePassTarget.h
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import <Foundation/Foundation.h>
#import <VVMetalKit/VVMetalKit.h>

#import <ISFMSLKit/ISFMSLSceneImgRef.h>

NS_ASSUME_NONNULL_BEGIN




/*		- Basically a data container class- consumers of ISFMSLKit will probably never need to work with this.
		- ISFs can have multiple passes- an instance of this class represents a render target for one of the passes
*/




@protocol ISFMSLScenePassTarget

@property (readonly) BOOL float32;
@property (readonly) BOOL persistent;
@property (readonly) NSString * name;
@property (readonly) NSSize targetSize;
@property (readonly) id<ISFMSLSceneImgRef> image;	//	if the dimensions of 'target' don't match the dimensions of 'image' then you need to resize 'target' to match 'image'!

@property (strong,nullable) id<MTLRenderPipelineState> pso;	//	retained by this obj-c backend/not part of the VVISF base lib
@property (readwrite) int passIndex;	//	retained by this obj-c backend/not part of the VVISF base lib

@end




NS_ASSUME_NONNULL_END
