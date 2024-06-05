//
//  ISFMSLCache.h
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/11/23.
//

#import <Foundation/Foundation.h>

#import <PINCache/PINCache.h>
#import <ISFMSLKit/ISFMSLCacheObject.h>
#import <ISFMSLKit/ISFMSLBinCacheObject.h>

NS_ASSUME_NONNULL_BEGIN




//	hints can be applied to both "get" and "set" cache actions
typedef NS_ENUM(NSInteger, ISFMSLCacheHint)	{
	ISFMSLCacheHint_NoHint = 0,	//	basically means "don't check anything, just set/get the stuff i want". note that this may still cause a binary archive to be compiled (if it simply doesn't exist).
	ISFMSLCacheHint_ForceTranspile,	//	forces a transpile (& clears all binary archives)
	ISFMSLCacheHint_TranspileIfDateDelta,	//	checks the mod date of the ISF file, compares it to the date stored in ISFMSLCacheObject, transpiles (& clears binary archives) if different
	ISFMSLCacheHint_TranspileIfContentDelta,	//	checks the content of the GLSL shader, compares it to the hash stored in ISFMSLCacheObject, transpiles (& clears binary archives) if different
};




/*		this class is the primary interface for retrieving ISFMSLBinCacheObject instances, which provides cached GPU resources required to render the ISF
		- there's a class singleton which is null by default, if you want to use it then you need to set it
		- requires a directoryPath or directoryURL, which determines the directory that this cache object will store data in.
			- first of all, PINCache will use to save data (ISFMSLCacheObject instances serialized via NSCoding) in a subdirectory (com.pinterest.PINDiskCache.ISFMSL)
			- ISFMSLBinCacheObject will also serialize id<MTLBinaryArchive> instances to a series of subdirectories in (there's a "BinaryArchives" subdirectory, which contains an "ISFMSL" subdirectory, which in turn contains one subdirectory for each GPU type that has been compiled/cached)
		- if you request a cached ISF for a URL that hasn't been cached yet, it will be cached serially, so front-load that operation
			- when you request a cached ISF, you can specify a cache hint that will cause the ISF to be re-compiled if its mod date or contents have changed
		
		general usage:
		- alloc/init an instance with a directory
		- set the class's 'primary' property, which establishes a strong ref to the primary instance
		- on app load, request every ISF you intend to load from the cache.  the "hot" footprint is quite small, the binary archives persist only on disk as per the Metal interface.
		- during runtime, request ISFMSLBinCacheObject instances as needed, they contain everything necessary to render the ISF (GPU resources and structured data describing how each of the ISF's attributes/render passes map to the shader's input indexes)
*/




@interface ISFMSLCache : NSObject

//	class singleton, NULL BY DEFAULT- if you want to use this you need to populate it yourself.  convenience property.
@property (class,strong) ISFMSLCache * primary;

- (instancetype) initWithDirectoryPath:(NSString *)inPath;
- (instancetype) initWithDirectoryURL:(NSURL *)inURL;

- (void) clearCachedISFAtURL:(NSURL *)n;
//	clears the cache- returns an array of the URLs of the ISFs that were in the cache that have been cleared
- (NSArray<NSURL*> *) clearCache;

//	equivalent to passing the hint 'ISFMSLCacheHint_NoHint' (binary archive that exists will be used, and created and saved to disk if it doesn't)
- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice;
- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice hint:(ISFMSLCacheHint)inHint;;

@property (strong,readonly) NSURL * directory;

//	this directory contains sub-directories, and the sub-directories contain binary archives
@property (readonly) NSURL * binaryArchivesDirectory;
//	each directory corresponds to a GPU types, and contains only binaries compiled for it
@property (readonly) NSArray<NSURL*> * binaryArchiveDirectories;

@end




NS_ASSUME_NONNULL_END
