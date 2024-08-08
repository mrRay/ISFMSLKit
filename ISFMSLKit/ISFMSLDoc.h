//
//  ISFMSLDoc.h
//  ISFMSLKit
//
//  Created by testadmin on 8/6/24.
//

#import <Foundation/Foundation.h>

#import <ISFMSLKit/ISFMSLConstants.h>
#import <ISFMSLKit/ISFMSLSceneAttrib.h>

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLDoc : NSObject

+ (instancetype) createWithURL:(NSURL *)n;

- (instancetype) initWithURL:(NSURL *)n;

@property (readonly) NSString * name;
@property (readonly) NSURL * url;
@property (readonly) NSString * path;

@property (readonly) NSString * isfDescription;
@property (readonly) NSString * credit;
@property (readonly) ISFMSLProtocol type;

@property (readonly) NSArray<NSString*> * categories;

@property (readonly) NSArray<id<ISFMSLSceneAttrib>> * inputs;

@end




NS_ASSUME_NONNULL_END
