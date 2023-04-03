//
//  ISFMTLSceneVal_priv.h
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import <Foundation/Foundation.h>

#import "ISFMTLSceneVal.h"
#include "VVISF.hpp"

//@protocol ISFMTLSceneVal;

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLSceneVal : NSObject <ISFMTLSceneVal>	{
	VVISF::ISFVal			_localVal;
}

+ (instancetype) createWithISFVal:(VVISF::ISFVal &)n;

- (instancetype) initWithISFVal:(VVISF::ISFVal &)n;

@property (readonly) VVISF::ISFVal isfValue;

@end




NS_ASSUME_NONNULL_END
