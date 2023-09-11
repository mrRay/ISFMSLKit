//
//  ISFMSLConstants.h
//  ISFMSLKit
//
//  Created by testadmin on 9/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN




///	so far, there are only two different types of ISF filters- "source" or "filter"
typedef NS_ENUM(NSInteger, ISFMSLProtocol)	{
	ISFMSLProto_None = 0,	//!< all image filters
	ISFMSLProto_Source = 1,	//!< generative sources
	ISFMSLProto_Filter = 2,	//!< image filters
	ISFMSLProto_Transition = 4,	//!< transitions
	ISFMSLProto_All = 7
};




NS_ASSUME_NONNULL_END
