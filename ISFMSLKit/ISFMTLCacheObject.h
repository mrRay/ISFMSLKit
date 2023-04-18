//
//  ISFMTLCacheObject.h
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>

#import "ISFMTLBinCacheObject.h"

@class ISFMTLCache;

NS_ASSUME_NONNULL_BEGIN




/*		data object, used to store values.  instances of this object are stored and retrieved by ISFMTLCache.
*/




@interface ISFMTLCacheObject : NSObject <NSCoding>

- (instancetype) init;

//	these properties are all cached via PINCache
@property (strong) NSString * name;
@property (strong) NSString * path;
@property (strong) NSString * glslFragShaderHash;	//	checksum used to ensure that the cached values are an accurate reflection of the contents of the ISF currently found on disk
@property (strong) NSDate * modDate;	//	checksum used to ensure that the cached values are an accurate reflection of the contents of the ISF currently found on disk
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

//	NOT cached by PINCache...but ISFMTLBinCacheObject instances serialize id<MTLBinaryCache> data to disk, so this is a form of caching, technically...
- (ISFMTLBinCacheObject *) binCacheForDevice:(id<MTLDevice>)inDevice;

//	this property is NOT cached, it's set by the cache that creates the receiver
@property (weak,readwrite) ISFMTLCache * parentCache;

//	these methods check the various checksums to determine if the receiver is an accurate representation of the ISF file on disk (YES) or not.
- (BOOL) modDateChecksum;
- (BOOL) fragShaderHashChecksum;

@end




NS_ASSUME_NONNULL_END
