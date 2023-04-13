//
//  ISFMTLCacheObject.h
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN




/*		data object, used to store values.  instances of this object are stored and retrieved by ISFMTLCache.
*/




@interface ISFMTLCacheObject : NSObject <NSCoding>

//	these properties are all cached
@property (strong) NSString * name;
@property (strong) NSURL * path;
@property (strong) NSString * glslShaderHash;
@property (strong) NSDate * modDate;
@property (strong) NSString * mslVertShader;
@property (strong) NSString * vertFuncName;
@property (strong) NSString * mslFragShader;
@property (strong) NSString * fragFuncName;
@property (strong) NSDictionary<NSString*,NSNumber*> * vertBufferVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * vertTextureVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * vertSamplerVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * fragBufferVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * fragTextureVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * fragSamplerVarIndexDict;
@property (readwrite) uint32_t maxUBOSize;
@property (readwrite) uint32_t vtxFuncMaxBufferIndex;

//	this property is NOT cached- it has to be set by the cache that retrieves this object.  setting it populates other properties (which aren't cached)
@property (readwrite,strong) id<MTLDevice> device;

//	these properties are NOT cached- they're populated when you set the cache object's device
@property (readwrite,strong) id<MTLLibrary> vtxLib;
@property (readwrite,strong) id<MTLLibrary> frgLib;
@property (readwrite,strong) id<MTLFunction> vtxFunc;
@property (readwrite,strong) id<MTLFunction> frgFunc;

@end




NS_ASSUME_NONNULL_END
