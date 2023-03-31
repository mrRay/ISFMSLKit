//
//  ISFMTLSceneAttrib_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/14/23.
//

#import <Foundation/Foundation.h>

#import "ISFMTLSceneAttrib.h"
#include "VVISF.hpp"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLSceneAttrib : NSObject <ISFMTLSceneAttrib,NSCopying>	{
	VVISF::ISFAttrRef		_localAttr;
}

+ (instancetype) createWithISFAttr:(VVISF::ISFAttrRef)n;

- (instancetype) initWithISFAttr:(VVISF::ISFAttrRef)n;

@property (readonly) VVISF::ISFAttrRef isfAttrRef;

@end




NS_ASSUME_NONNULL_END
