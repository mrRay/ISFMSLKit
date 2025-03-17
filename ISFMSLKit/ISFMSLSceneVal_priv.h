//
//  ISFMSLSceneVal_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

#import <ISFMSLKit/ISFMSLSceneImgRef.h>

#import "ISFMSLSceneVal.h"
#include "VVISF.hpp"

//@protocol ISFMSLSceneVal;

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLSceneVal ()	{
	VVISF::ISFVal			_localVal;
}

+ (instancetype) createWithISFVal:(VVISF::ISFVal &)n;

- (instancetype) initWithISFVal:(VVISF::ISFVal &)n;

@property (readonly) VVISF::ISFVal isfValue;

- (id<ISFMSLSceneImgRef>) isfImgValue;

@end




NS_ASSUME_NONNULL_END
