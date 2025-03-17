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
#import <ISFMSLKit/ISFMSLTranspilerError.h>

NS_ASSUME_NONNULL_BEGIN




///	Hints that can be applied to both "get" and "set" cache actions
typedef NS_ENUM(NSInteger, ISFMSLCacheHint)	{
	ISFMSLCacheHint_NoHint = 0,	///	Basically means "don't check anything, just set/get the stuff i want". Note that this may still cause a binary archive to be compiled (if it simply doesn't exist).
	ISFMSLCacheHint_ForceTranspile,	///	Forces a transpile (& clears all binary archives).
	ISFMSLCacheHint_TranspileIfDateDelta,	///	Checks the mod date of the ISF file, compares it to the date stored in ISFMSLCacheObject, transpiles (& clears binary archives) if different.
	ISFMSLCacheHint_TranspileIfContentDelta,	///	Checks the content of the GLSL shader, compares it to the hash stored in ISFMSLCacheObject, transpiles (& clears binary archives) if different.
};




/**		This class is the primary interface for caching (and retrieving cached) ISF files.  Caching ISF files precompiles their shaders, allowing for faster runtime access.

		#### General usage:
		- alloc/init an instance using the directory at which you want the cache to be stored ("~/Library/Application Support/<yourappname>" is usually a good location)
		- Set the class's 'primary' property to serve as a global singleton, which establishes a strong ref to the primary instance.
		- That's it!  ``ISFMSLScene`` will automatically work with the cache to load cached data that exists and cache shaders that haven't been cached yet.
		- If you want to preload/cache ISF files before use, just call `-[ISFMSLCache getCachedISFAtURL:forDevice:]` on every file you want to preload.
		
		#### Background info:
		- There's a class singleton which is null by default- you should configure this on app launch before you load or cache any ISF docs.
		- Requires a directoryPath or directoryURL, which determines the directory that this cache object will store data in.
			- Uses `PINCache` behind the scenes to manage the cache.  PINCache will use this path to save data (ISFMSLCacheObject instances serialized via NSCoding) in a subdirectory (com.pinterest.PINDiskCache.ISFMSL)
			- ISFMSLBinCacheObject will also serialize id<MTLBinaryArchive> instances to a series of subdirectories in (there's a "BinaryArchives" subdirectory, which contains an "ISFMSL" subdirectory, which in turn contains one subdirectory for each GPU type that has been compiled/cached)
			- The directory will also contain human-readable error logs for ISFs that cannot be compiled for any reason.
		- The "hot" footprint is quite small, the binary archives persist only on disk as per the Metal interface.
		- Vends ``ISFMSLBinCacheObject`` instances, which contain everything necessary to render the ISF (GPU resources and structured data describing how each of the ISF's attributes/render passes map to the shader's input indexes).
		- If you request a cached ISF for a URL that hasn't been cached yet, it will be cached serially- you should front-load this operation in your app workflow.
			- When you request a cached ISF, you can specify a cache hint that will cause the ISF to be re-compiled if its mod date or contents have changed.
		
*/




@interface ISFMSLCache : NSObject

///	Class singleton, NULL BY DEFAULT- if you want to use this you need to populate it yourself.  convenience property.
@property (class,strong) ISFMSLCache * primary;

- (instancetype) initWithDirectoryPath:(NSString *)inPath;
- (instancetype) initWithDirectoryURL:(NSURL *)inURL;

- (void) clearCachedISFAtURL:(NSURL *)n;
///	clears the cache- returns an array of the URLs of the ISFs that were in the cache that have been cleared.
- (NSArray<NSURL*> *) clearCache;

///	Equivalent to passing the hint 'ISFMSLCacheHint_NoHint' (binary archive that exists will be used, and created and saved to disk if it doesn't)
- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice;
///	Attempts to retrieve the cache object corresponding to the ISF at the passed URL with Metal resources for the passed device.  The hint you pass determines if the existing cache object is returned or if it's recompiled (if the mod date of the ISF has changed since it was last compiled, for example).
- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice hint:(ISFMSLCacheHint)inHint logErrorToDisk:(BOOL)inLog;

///	The directory in which the ISF cache exists.  Set only on init.
@property (strong,readonly) NSURL * directory;

///	This directory contains sub-directories, and the sub-directories contain binary archives.
@property (readonly) NSURL * binaryArchivesDirectory;
///	Each directory corresponds to a GPU types, and contains only binaries compiled for it
@property (readonly) NSArray<NSURL*> * binaryArchiveDirectories;

///	This directory contains text files that are logs of compiler errors. the text file names are the last path components of the source files (minus existing extension, plus ".txt")
@property (readonly) NSURL * transpilerErrorLogsDirectory;

@end




NS_ASSUME_NONNULL_END
