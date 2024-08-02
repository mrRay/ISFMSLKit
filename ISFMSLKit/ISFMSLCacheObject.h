//
//  ISFMSLCacheObject.h
//  VVMetalKit-SimplePlayback
//
//  Created by testadmin on 4/12/23.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>

#import <ISFMSLKit/ISFMSLBinCacheObject.h>

@class ISFMSLCache;

NS_ASSUME_NONNULL_BEGIN




/*		data object, used to store values.  instances of this object are stored and retrieved by ISFMSLCache via PINCache under the hood via NSCoding.
		- doesn't do anything GPU-related directly, really just stores data we generate about the ISF file (including 
		frag & vert shader source, and info describing how to map the ISF's inputs/attributes to the render encoder)
		- will generate a bin cache object (ISFMSLBinCacheObject) on request, which is how PSOs are pre-compiled/cached, 
		which is required for rendering and a CPU-intensive task
*/




@interface ISFMSLCacheObject : NSObject <NSCoding>

+ (instancetype) createWithCache:(ISFMSLCache *)inParent url:(NSURL *)inURL;

- (instancetype) initWithCache:(ISFMSLCache *)inParent url:(NSURL *)inURL;

//	these properties are all cached via PINCache
@property (strong) NSString * name;
@property (strong) NSString * path;
@property (strong) NSString * glslFragShaderHash;	//	checksum used to ensure that the cached values are an accurate reflection of the contents of the ISF currently found on disk
@property (strong) NSDate * modDate;	//	checksum used to ensure that the cached values are an accurate reflection of the contents of the ISF currently found on disk
@property (strong,nullable) NSString * mslVertShader;
@property (strong) NSString * vertFuncName;
@property (strong,nullable) NSString * mslFragShader;
@property (strong) NSString * fragFuncName;
@property (strong) NSDictionary<NSString*,NSNumber*> * vertBufferVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * vertTextureVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * vertSamplerVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * fragBufferVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * fragTextureVarIndexDict;
@property (strong) NSDictionary<NSString*,NSNumber*> * fragSamplerVarIndexDict;
@property (readwrite) uint32_t maxUBOSize;
@property (readwrite) uint32_t vtxFuncMaxBufferIndex;

//	NOT cached by PINCache...but ISFMSLBinCacheObject instances serialize id<MTLBinaryCache> data to disk, so this is a form of caching, technically...
- (ISFMSLBinCacheObject *) binCacheForDevice:(id<MTLDevice>)inDevice;

//	this property is NOT cached, it's set by the cache that creates the receiver
@property (weak,readwrite) ISFMSLCache * parentCache;

//	re-caches the receiver in its parentCache, updating any properties that you want to persist
- (void) updateInParentCache;

//	these methods check the various checksums to determine if the receiver is an accurate representation of the ISF file on disk (YES) or not.
- (BOOL) modDateChecksum;
- (BOOL) fragShaderHashChecksum;

//	generate a MTLVertexDescriptor for the cached ISF
- (MTLVertexDescriptor *) generateVertexDescriptor;

@end




NS_ASSUME_NONNULL_END
