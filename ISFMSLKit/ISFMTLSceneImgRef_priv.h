//
//  ISFMTLSceneImgRef_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

#import "ISFMTLSceneImgRef.h"
//#import "VVISF.hpp"
#import "ISFImage.h"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLSceneImgRef : NSObject <ISFMTLSceneImgRef>	{
	//	may also be 'ISFImageRef'!  really, any std::shared_ptr around a subclass of VVISF::ISFImageInfo should work?
	ISFImageRef		_localImage;
}

+ (instancetype) createWithImgRef:(ISFImageRef)n;
+ (instancetype) createWithMTLImgBuffer:(MTLImgBuffer *)n;

- (instancetype) initWithImgRef:(ISFImageRef)n;
- (instancetype) initWithMTLImgBuffer:(MTLImgBuffer *)n;

@property (readonly) ISFImageRef isfImageRef;

@end




NS_ASSUME_NONNULL_END
