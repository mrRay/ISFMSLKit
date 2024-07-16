//
//  ISFMSLCache_priv.h
//  ISFMSLKit
//
//  Created by testadmin on 7/16/24.
//

#ifndef ISFMSLCache_priv_h
#define ISFMSLCache_priv_h


@interface ISFMSLCache ()

//	doesn't check anything- immediately begins ops necessary to transpile the ISF to MSL.  ALSO KILLS ANY BINARY ARCHIVES!
- (ISFMSLCacheObject *) _cacheISFAtURL:(NSURL *)inURL;
- (ISFMSLCacheObject *) _getCachedISFAtURL:(NSURL *)inURL;

- (void) _pushCacheObjectToCache:(ISFMSLCacheObject *)n;

@end


#endif /* ISFMSLCache_priv_h */
