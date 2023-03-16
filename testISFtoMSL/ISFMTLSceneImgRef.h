//
//  ISFMTLSceneImgRef.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



@protocol ISFMTLSceneImgRef

@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) uint32_t depth;
@property (readonly) BOOL cubemap;
@property (readonly) NSString * imagePath;
@property (readonly) NSArray<NSString*> * cubePaths;

@property (readonly) BOOL hasValidSize;

@end




NS_ASSUME_NONNULL_END
