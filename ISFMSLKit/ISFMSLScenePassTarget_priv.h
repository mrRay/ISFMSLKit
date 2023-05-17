//
//  ISFMSLScenePassTarget_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#ifndef ISFMSLScenePass_priv_h
#define ISFMSLScenePass_priv_h

#import "ISFMSLScenePassTarget.h"
#include "VVISF.hpp"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLScenePassTarget : NSObject <ISFMSLScenePassTarget>	{
	VVISF::ISFPassTargetRef		_localPassTarget;
}

+ (instancetype) createWithPassTarget:(VVISF::ISFPassTargetRef)n;

- (instancetype) initWithPassTarget:(VVISF::ISFPassTargetRef)n;

@property (readonly) VVISF::ISFPassTargetRef & passTargetRef;

@end




NS_ASSUME_NONNULL_END

#endif /* ISFMSLScenePass_priv_h */
