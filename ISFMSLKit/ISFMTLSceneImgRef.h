//
//  ISFMTLSceneImgRef.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

@class MTLImgBuffer;

NS_ASSUME_NONNULL_BEGIN




//	under the hood, contains a std::shared_ptr<ISFImage>. ISFImage is a subclass of VVISF::ISFImageInfo that contains an MTLImgBuffer.




@protocol ISFMTLSceneImgRef

@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) uint32_t depth;
@property (readonly) BOOL cubemap;
@property (readonly) NSString * imagePath;
@property (readonly) NSArray<NSString*> * cubePaths;

@property (readonly) BOOL hasValidSize;

@property (readonly) MTLImgBuffer * img;

@end




NS_ASSUME_NONNULL_END
