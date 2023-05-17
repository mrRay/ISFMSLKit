//
//  ISFMSLBinCacheObject.h
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/18/23.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@class ISFMSLCacheObject;

NS_ASSUME_NONNULL_BEGIN




/*		this class stores objects that are used to render the ISF- id<MTLLibrary> and id<MTLFunction> you need 
		to create the PSO, and a id<MTLBinaryArchive> corresponding to a file on disk that loads the cached PSO.
		- instances of this class are created by ISFMSLCache.  once created, ISFMSLCacheObject stores a strong 
		ref to the instance in its 'binCache' property (it's a private property)
		- on init, an instance of this class will attempt to load a pre-existing binary cache from disk.  if 
		no binary cache exists, it will compile and cache the PSO into a binary archive, which gets written to disk.
*/




@interface ISFMSLBinCacheObject : NSObject

- (instancetype) initWithParent:(ISFMSLCacheObject *)inParent device:(id<MTLDevice>)inDevice;

//	this property is NOT cached by PINCache- it has to be set by the cache that retrieves this object.  setting it populates other properties (which aren't cached)
@property (readwrite,strong) id<MTLDevice> device;

//	these properties are NOT cached by PINCache- they're populated when you set the cache object's device.  we only need these as a fallback, if something goes wrong with the binary archive.
@property (readwrite,strong) id<MTLLibrary> vtxLib;
@property (readwrite,strong) id<MTLLibrary> frgLib;
@property (readwrite,strong) id<MTLFunction> vtxFunc;
@property (readwrite,strong) id<MTLFunction> frgFunc;

//	these properties are cached- but not by PINCache, they're exported to files on disk in a different directory (same filename used by PINCache)
@property (readwrite,strong) id<MTLBinaryArchive> archive;

//	this property isn't cached, it's set by the cache that creates the receiver
@property (weak,readwrite) ISFMSLCacheObject * parentObj;

@end




NS_ASSUME_NONNULL_END
