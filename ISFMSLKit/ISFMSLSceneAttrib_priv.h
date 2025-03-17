//
//  ISFMSLSceneAttrib_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/14/23.
//

#import <Foundation/Foundation.h>

#import "ISFMSLSceneAttrib.h"
#import "ISFMSLSceneImgRef.h"
#include "VVISF.hpp"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLSceneAttrib : NSObject <ISFMSLSceneAttrib,NSCopying>	{
	VVISF::ISFAttrRef		_localAttr;
}

+ (instancetype) createWithISFAttr:(VVISF::ISFAttrRef)n;

- (instancetype) initWithISFAttr:(VVISF::ISFAttrRef)n;

@property (readonly) VVISF::ISFAttrRef isfAttrRef;

///	Sets/gets the receiver's image buffer as an id<ISFMSLSceneImgRef> instance.
@property (strong) id<ISFMSLSceneImgRef> currentImageRef;

@end




NS_ASSUME_NONNULL_END
