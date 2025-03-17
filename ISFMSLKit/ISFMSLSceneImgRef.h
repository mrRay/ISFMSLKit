//
//  ISFMSLSceneImgRef.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

@protocol MTLTexture;
@protocol VVMTLTextureImage;

NS_ASSUME_NONNULL_BEGIN




/**	This class is used internally- you can interact with ``ISFMSLSceneVal`` and ``ISFMSLSceneAttrib`` by using `id<VVMTLTextureImage>` and `id<MTLTexture>` instead.  This protocol/class describes an "ISF image" as represented by a Metal texture vended by the `VVMetalKit` framework (specifically, as an instance of `VVMTLTextureImage`).
- This protocol/class depends on VVMetalKit because I wanted a simple buffer/texture pool, and using an existing framework was easier than re-inventing the wheel and writing a custom buffer pool just for the ``ISFMSLKit`` framework.
- Under the hood, this class is basically a thin objective-c wrapper around the c++ class `ISFImage`, which is in turn just a thin wrapper around `VVISF::ISFImageInfo` that exists solely to allow the c++ class `VVISF::ISFImageInfo` to retain an instance of `VVMTLTextureImage`.
*/




@protocol ISFMSLSceneImgRef

@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) uint32_t depth;
@property (readonly) BOOL cubemap;
@property (readonly) NSString * imagePath;
@property (readonly) NSArray<NSString*> * cubePaths;

@property (readonly) BOOL hasValidSize;

@property (readonly) id<VVMTLTextureImage> img;

@property (readonly) id<MTLTexture> texture;

@end




NS_ASSUME_NONNULL_END
