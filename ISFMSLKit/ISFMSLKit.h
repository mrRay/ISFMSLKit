//
//  ISFMSLKit.h
//  ISFMSLKit
//
//  Created by testadmin on 4/3/23.
//

#import <Foundation/Foundation.h>

//! Project version number for ISFMSLKit.
FOUNDATION_EXPORT double ISFMSLKitVersionNumber;

//! Project version string for ISFMSLKit.
FOUNDATION_EXPORT const unsigned char ISFMSLKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ISFMSLKit/PublicHeader.h>
#import <ISFMSLKit/ISFMSLConstants.h>
#import <ISFMSLKit/ISFMSLScene.h>
#import <ISFMSLKit/ISFMSLSceneAttrib.h>
#import <ISFMSLKit/ISFMSLSceneImgRef.h>
#import <ISFMSLKit/ISFMSLScenePassTarget.h>
#import <ISFMSLKit/ISFMSLSceneVal.h>
#import <ISFMSLKit/ISFMSLCacheObject.h>
#import <ISFMSLKit/ISFMSLCache.h>
#import <ISFMSLKit/ISFMSLTranspilerError.h>
#import <ISFMSLKit/ISFMSLNSStringAdditions.h>
#import <ISFMSLKit/ISFMSLDoc.h>




#if defined __cplusplus
extern "C"	{
#endif
	
	NSArray<NSString*> * GetArrayOfDefaultISFs( ISFMSLProtocol inProtocol );
	
	NSArray<NSString*> * GetISFsInDirectory(NSString * inDirPath, BOOL inRecursive, ISFMSLProtocol inProtocol);
	
#if defined __cplusplus
}
#endif

