//
//  ISFMTLCache.h
//  ISFMSLKitTestApp
//
//  Created by testadmin on 4/11/23.
//

#import <Foundation/Foundation.h>

#import <PINCache/PINCache.h>
#import "ISFMTLCacheObject.h"

NS_ASSUME_NONNULL_BEGIN




@interface ISFMTLCache : NSObject

//	NULL BY DEFAULT- if you want to use this you need to populate it yourself.
@property (class,strong) ISFMTLCache * primary;

- (instancetype) initWithDevice:(id<MTLDevice>)inDevice path:(NSString *)inPath;

//	doesn't check anything- immediately begins ops necessary to (transpile and) cache the ISF at the passed URL
- (ISFMTLCacheObject *) cacheISFAtURL:(NSURL *)n;
//	returns the currently cached object for the ISF, or nil if it hasn't been cached yet
- (ISFMTLCacheObject *) getCachedISFAtURL:(NSURL *)n;

@property (strong,readonly) NSString * path;

@end




NS_ASSUME_NONNULL_END
