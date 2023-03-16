//
//  ISFMTLSceneImgRef_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

#import "ISFMTLSceneImgRef.h"
#import "VVISF.hpp"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLSceneImgRef : NSObject <ISFMTLSceneImgRef>	{
	VVISF::ISFImageRef		_localImage;
}

+ (instancetype) createWithImgRef:(VVISF::ISFImageRef)n;

- (instancetype) initWithImgRef:(VVISF::ISFImageRef)n;

@property (readonly) VVISF::ISFImageRef isfImageRef;

@end




NS_ASSUME_NONNULL_END
