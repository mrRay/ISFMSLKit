//
//  ISFMSLTranspilerError.h
//  ISFMSLKit
//
//  Created by testadmin on 8/5/24.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@class ISFMSLCacheObject;

NS_ASSUME_NONNULL_BEGIN




@interface ISFMSLTranspilerError : NSObject

+ (instancetype) createWithURL:(NSURL*)u device:(id<MTLDevice>)d;

- (instancetype) initWithURL:(NSURL*)u device:(id<MTLDevice>)d;

@property (readonly) NSURL * url;
@property (readonly) id<MTLDevice> device;

@property (readonly) BOOL vertGLSLErrFlag;	//	err with vert, GLSL -> SPIR-V
@property (readonly) NSString * vertGLSLErrString;

@property (readonly) BOOL vertSPIRVErrFlag;	//	err with vert, SPIR-V -> MSL
@property (readonly) NSString * vertSPIRVErrString;

@property (readonly) BOOL vertMSLErrFlag;	//	err with vert, compiling MSL
@property (readonly) NSString * vertMSLErrString;


@property (readonly) BOOL fragGLSLErrFlag;	//	err with frag, GLSL -> SPIR-V
@property (readonly) NSString * fragGLSLErrString;

@property (readonly) BOOL fragSPIRVErrFlag;	//	err with frag, SPIR-V -> MSL
@property (readonly) NSString * fragSPIRVErrString;

@property (readonly) BOOL fragMSLErrFlag;	//	err with frag, compiling MSL
@property (readonly) NSString * fragMSLErrString;


@property (readonly) NSString * glslVertSrc;
@property (readonly) NSString * glslFragSrc;
@property (readonly) NSString * glslVertSrcWithLineNumbers;
@property (readonly) NSString * glslFragSrcWithLineNumbers;

@property (readonly) NSString * mslVertSrc;
@property (readonly) NSString * mslFragSrc;
@property (readonly) NSString * mslVertSrcWithLineNumbers;
@property (readonly) NSString * mslFragSrcWithLineNumbers;


- (NSString *) generateStringForLogFile;


@end




NS_ASSUME_NONNULL_END
