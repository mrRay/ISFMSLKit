//
//	ISFMSLCache.m
//	ISFMSLKitTestApp
//
//	Created by testadmin on 4/11/23.
//

#import "ISFMSLCache.h"

//#import <VVCore/VVCore.h>
#import "ISFMSLNSStringAdditions.h"

//#include "GLSLangValidatorLib.hpp"
//#include "SPIRVCrossLib.hpp"

//#include <string>
//#include <vector>
//#include <algorithm>
//#include <iostream>
//#include <regex>
//#include <typeinfo>

#include "VVISF.hpp"




using namespace std;




static ISFMSLCache		*primary = nil;




@interface ISFMSLCache ()

- (void) generalInit;

- (void) _clearCachedISFAtURL:(NSURL *)inURL;

@property (strong) PINCache * isfCache;
@property (strong,readwrite) NSURL * directory;

@end




@implementation ISFMSLCache


+ (void) setPrimary:(ISFMSLCache *)n	{
	primary = n;
}
+ (ISFMSLCache *) primary	{
	return primary;
}


- (instancetype) initWithDirectoryPath:(NSString *)inPath	{
	//NSLog(@"%s ... %@",__func__,inPath);
	self = [super init];
	
	if (inPath == nil)
		self = nil;
	
	if (self != nil)	{
		_directory = [NSURL fileURLWithPath:inPath];
		
		[self generalInit];
	}
	return self;
}
- (instancetype) initWithDirectoryURL:(NSURL *)inURL	{
	//NSLog(@"%s ... %@",__func__,inURL.path);
	self = [super init];
	
	if (inURL == nil)
		self = nil;
	
	if (self != nil)	{
		_directory = inURL;
		
		[self generalInit];
	}
	
	return self;
}


- (void) generalInit	{
	//	first make sure the directory that will contain binary archives exists
	NSError				*nsErr = nil;
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSURL				*binaryArchiveDir = self.directory;
	binaryArchiveDir = [self binaryArchivesDirectory];
	if (![fm fileExistsAtPath:binaryArchiveDir.path isDirectory:nil])	{
		if (![fm createDirectoryAtURL:binaryArchiveDir withIntermediateDirectories:YES attributes:nil error:&nsErr] || nsErr != nil)	{
			NSLog(@"ERR: unable to create binary archives directory (%@), (%@), %s",binaryArchiveDir.path,nsErr,__func__);
		}
	}
	
	//	make the cache
	PINDiskCacheSerializerBlock		serializer = ^NSData*(id<NSCoding> object, NSString* key) {
		return [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:nil];
	};
	PINDiskCacheDeserializerBlock		deserializer = ^id<NSCoding>(NSData* data, NSString* key) {
		NSKeyedUnarchiver		*unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
		unarchiver.requiresSecureCoding = NO;
		ISFMSLCacheObject		*unarchived = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		unarchived.parentCache = self;
		return unarchived;
	};
	
	self.isfCache = [[PINCache alloc]
		initWithName:@"ISFMSL"
		//prefix:@""
		rootPath:_directory.path
		serializer:serializer
		deserializer:deserializer
		keyEncoder:nil
		keyDecoder:nil
		ttlCache:false];
	_isfCache.diskCache.byteLimit = 0;
	_isfCache.diskCache.ageLimit = 0;
	_isfCache.memoryCache.costLimit = 100 * 1024 * 1024;
	_isfCache.memoryCache.ageLimit = 0;
}


- (void) clearCachedISFAtURL:(NSURL *)n	{
	if (n == nil)	{
		return;
	}
	
	@synchronized (self)	{
		[self _clearCachedISFAtURL:n];
	}
}
- (void) _clearCachedISFAtURL:(NSURL *)inURL	{
	
	NSString		*fullPath = [inURL.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath isfMD5String];
	NSError			*nsErr = nil;
	
	NSFileManager	*fm = [NSFileManager defaultManager];
	
	[_isfCache removeObjectForKey:fullPathHash];
	
	for (NSURL * binArchiveDir in self.binaryArchiveDirectories)	{
		NSURL		*binArchiveFile = [binArchiveDir URLByAppendingPathComponent:fullPathHash];
		if ([fm fileExistsAtPath:binArchiveFile.path])	{
			if (![fm trashItemAtURL:binArchiveFile resultingItemURL:nil error:&nsErr] || nsErr != nil)	{
				NSLog(@"ERR: (%@) moving (%@) in %s",nsErr,binArchiveFile.path,__func__);
			}
		}
	}
}


- (NSArray<NSURL*> *) clearCache	{
	@synchronized (self)	{
		return [self _clearCache];
	}
}
- (NSArray<NSURL*> *) _clearCache	{
	PINDiskCache		*dCache = _isfCache.diskCache;
	PINMemoryCache		*mCache = _isfCache.memoryCache;
	
	NSMutableArray<NSString*>	*keys = [NSMutableArray arrayWithCapacity:0];
	NSMutableArray<NSURL*>	*urls = [NSMutableArray arrayWithCapacity:0];
	
	[dCache enumerateObjectsWithBlock:^(NSString *key, NSURL *fileURL, BOOL *stop)	{
		if (![keys containsObject:key])	{
			[keys addObject:key];
		}
	}];
	[mCache enumerateObjectsWithBlock:^(PINCache *cache, NSString *key, id _Nullable object, BOOL *stop)	{
		if (![keys containsObject:key])	{
			[keys addObject:key];
		}
	}];
	
	for (NSString *key in keys)	{
		ISFMSLCacheObject	*cachedObj = [_isfCache objectForKey:key];
		NSString		*cachedPath = cachedObj.path;
		NSURL			*cachedURL = [NSURL fileURLWithPath:cachedPath];
		if (cachedURL != nil)
			[urls addObject:cachedURL];
	}
	
	[_isfCache removeAllObjects];
	
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSURL		*binaryArchivesDir = self.binaryArchivesDirectory;
	NSError		*nsErr = nil;
	if (![fm trashItemAtURL:binaryArchivesDir resultingItemURL:nil error:&nsErr] || nsErr != nil)	{
		NSLog(@"ERR: unable to trash binary archives directory (%@), (%@), %s",binaryArchivesDir.path,nsErr,__func__);
	}
	else	{
		if (![fm createDirectoryAtURL:binaryArchivesDir withIntermediateDirectories:YES attributes:nil error:&nsErr] || nsErr != nil)	{
			NSLog(@"ERR: unable to create binary archives directory (%@), (%@), %s",binaryArchivesDir.path,nsErr,__func__);
		}
	}
	
	return [NSArray arrayWithArray:urls];
}

/*
- (ISFMSLBinCacheObject *) cacheISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice	{
	ISFMSLCacheObject		*returnMe = [self cacheISFAtURL:inURL forDevice:inDevice hint:ISFMSLCacheHint_NoHint];
	return returnMe;
}
- (ISFMSLBinCacheObject *) cacheISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice hint:(ISFMSLCacheHint)inHint	{
	if (inURL == nil || inDevice == nil)
		return nil;
	
	ISFMSLBinCacheObject		*returnMe = nil;
	
	@synchronized (self)	{
		
		ISFMSLCacheObject			*parentObj = nil;
		switch (inHint)	{
		case ISFMSLCacheHint_NoHint:
			parentObj = [self _getCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_ForceTranspile:
			[self _clearCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_TranspileIfDateDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj modDateChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		case ISFMSLCacheHint_TranspileIfContentDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj fragShaderHashChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		}
		
		if (parentObj == nil)	{
			parentObj = [self _cacheISFAtURL:inURL];
		}
		
		returnMe = [parentObj binCacheForDevice:inDevice];
	}
	return returnMe;
}
*/

- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice	{
	return [self getCachedISFAtURL:inURL forDevice:inDevice hint:ISFMSLCacheHint_NoHint];
}
- (ISFMSLBinCacheObject *) getCachedISFAtURL:(NSURL *)inURL forDevice:(id<MTLDevice>)inDevice hint:(ISFMSLCacheHint)inHint	{
	if (inURL == nil || inDevice == nil)
		return nil;
	
	ISFMSLBinCacheObject		*returnMe = nil;
	
	@synchronized (self)	{
		
		ISFMSLCacheObject			*parentObj = nil;
		switch (inHint)	{
		case ISFMSLCacheHint_NoHint:
			parentObj = [self _getCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_ForceTranspile:
			[self _clearCachedISFAtURL:inURL];
			break;
		case ISFMSLCacheHint_TranspileIfDateDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj modDateChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		case ISFMSLCacheHint_TranspileIfContentDelta:
			parentObj = [self _getCachedISFAtURL:inURL];
			if (![parentObj fragShaderHashChecksum])	{
				[self _clearCachedISFAtURL:inURL];
				parentObj = nil;
			}
			break;
		}
		
		if (parentObj == nil)	{
			parentObj = [self _cacheISFAtURL:inURL];
		}
		
		returnMe = [parentObj binCacheForDevice:inDevice];
	}
	
	return returnMe;
}


- (ISFMSLCacheObject *) _getCachedISFAtURL:(NSURL *)inURL	{
	if (inURL == nil)
		return nil;
	NSString		*fullPath = [inURL.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath isfMD5String];
	ISFMSLCacheObject		*returnMe = [_isfCache objectForKey:fullPathHash];
	return returnMe;
}


- (void) _pushCacheObjectToCache:(ISFMSLCacheObject *)n	{
	if (n == nil)
		return;
	
	NSString		*fullPath = [n.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath isfMD5String];
	[_isfCache setObject:n forKey:fullPathHash];
}


- (ISFMSLCacheObject *) _cacheISFAtURL:(NSURL *)inURL	{
	if (inURL == nil)
		return nil;
	
	ISFMSLCacheObject		*returnMe = [ISFMSLCacheObject createWithCache:self url:inURL];
	NSString		*fullPath = [inURL.path stringByExpandingTildeInPath];
	NSString		*fullPathHash = [fullPath isfMD5String];
	if (returnMe != nil && fullPathHash != nil)	{
		[_isfCache setObject:returnMe forKey:fullPathHash];
	}
	
	return returnMe;
}


- (NSURL *) binaryArchivesDirectory	{
	return [[self.directory URLByAppendingPathComponent:@"BinaryArchives"] URLByAppendingPathComponent:@"ISFMSL"];
}
- (NSArray<NSURL*> *) binaryArchiveDirectories	{
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSError				*nsErr = nil;
	NSArray<NSURL*>		*returnMe = [fm
		contentsOfDirectoryAtURL:self.binaryArchivesDirectory
		includingPropertiesForKeys:@[ NSURLIsDirectoryKey ]
		options:NSDirectoryEnumerationSkipsHiddenFiles
		error:&nsErr];
	return returnMe;
}


@end
