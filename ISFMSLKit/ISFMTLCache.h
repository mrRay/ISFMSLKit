//
//  ISFMTLCache.h
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/11/23.
//

#import <Foundation/Foundation.h>

#import <PINCache/PINCache.h>
#import "ISFMTLCacheObject.h"
#import "ISFMTLBinCacheObject.h"

NS_ASSUME_NONNULL_BEGIN




//	hints can be applied to both "get" and "set" cache actions
typedef NS_ENUM(NSInteger, ISFMTLCacheHint)	{
	ISFMTLCacheHint_NoHint = 0,	//	basically means "don't check anything, just set/get the stuff i want". note that this may still cause a binary archive to be compiled (if it simply doesn't exist).
	ISFMTLCacheHint_ForceTranspile,	//	forces a transpile (& clears all binary archives)
	ISFMTLCacheHint_TranspileIfDateDelta,	//	checks the mod date of the ISF file, compares it to the date stored in ISFMTLCacheObject, transpiles (& clears binary archives) if different
	ISFMTLCacheHint_TranspileIfContentDelta,	//	checks the content of the GLSL shader, compares it to the hash stored in ISFMTLCacheObject, transpiles (& clears binary archives) if different
};




@interface ISFMTLCache : NSObject

//	class singleton, NULL BY DEFAULT- if you want to use this you need to populate it yourself.  convenience property.
@property (class,strong) ISFMTLCache * primary;

- (instancetype) initWithDirectoryPath:(NSString *)inPath;
- (instancetype) initWithDirectoryURL:(NSURL *)inURL;

- (void) clearCachedISFAtURL:(NSURL *)n;

//	equivalent to passing the hint 'ISFMTLCacheHint_NoHint' (binary archive will be used if it existed and created and saved to disk if it doesn't)
//- (ISFMTLBinCacheObject *) cacheISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice;
//- (ISFMTLBinCacheObject *) cacheISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice hint:(ISFMTLCacheHint)inHint;

//	equivalent to passing the hint 'ISFMTLCacheHint_NoHint' (binary archive that exists will be used, and created and saved to disk if it doesn't)
- (ISFMTLBinCacheObject *) getCachedISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice;
- (ISFMTLBinCacheObject *) getCachedISFAtURL:(NSURL *)n forDevice:(id<MTLDevice>)inDevice hint:(ISFMTLCacheHint)inHint;;

@property (strong,readonly) NSURL * directory;

@property (readonly) NSURL * binaryArchivesDirectory;
@property (readonly) NSArray<NSURL*> * binaryArchiveDirectories;

@end




NS_ASSUME_NONNULL_END
