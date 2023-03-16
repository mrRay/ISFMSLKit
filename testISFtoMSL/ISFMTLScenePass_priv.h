//
//  ISFMTLScenePass_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#ifndef ISFMTLScenePass_priv_h
#define ISFMTLScenePass_priv_h

#import "ISFMTLScenePass.h"
#include "VVISF.hpp"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLScenePass : NSObject <ISFMTLScenePass>	{
	VVISF::ISFPassTargetRef		_localPassTarget;
}

+ (instancetype) createWithPassTarget:(VVISF::ISFPassTargetRef)n;

- (instancetype) initWithPassTarget:(VVISF::ISFPassTargetRef)n;

@property (readonly) VVISF::ISFPassTargetRef passTargetRef;

@end




NS_ASSUME_NONNULL_END

#endif /* ISFMTLScenePass_priv_h */
