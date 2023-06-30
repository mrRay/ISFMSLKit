//
//  ISFMSLSceneImgRef_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

#import "ISFMSLSceneImgRef.h"
//#import "VVISF.hpp"
#import "ISFImage.h"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLSceneImgRef : NSObject <ISFMSLSceneImgRef>	{
	//	may also be 'ISFImageRef'!  really, any std::shared_ptr around a subclass of VVISF::ISFImageInfo should work?
	ISFImageRef		_localImage;
}

+ (instancetype) createWithImgRef:(ISFImageRef)n;
+ (instancetype) createWithVVMTLTextureImage:(id<VVMTLTextureImage>)n;

- (instancetype) initWithImgRef:(ISFImageRef)n;
- (instancetype) initWithVVMTLTextureImage:(id<VVMTLTextureImage>)n;

@property (readonly) ISFImageRef isfImageRef;

@end




NS_ASSUME_NONNULL_END
