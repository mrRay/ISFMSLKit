//
//  ISFMTLSceneImgRef_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/8/23.
//

#import "ISFMTLSceneImgRef_priv.h"
#import "ISFMTLSceneImgRef.h"




@implementation ISFMTLSceneImgRef


#pragma mark - class methods


+ (instancetype) createWithImgRef:(VVISF::ISFImageRef)n	{
	return [[ISFMTLSceneImgRef alloc] initWithImgRef:n];
}


#pragma mark - init/dealloc


- (instancetype) initWithImgRef:(VVISF::ISFImageRef)n	{
	self = [super init];
	if (n == nullptr)
		self = nil;
	if (self != nil)	{
		_localImage = n;
	}
	return self;
}


#pragma mark - key/value


- (VVISF::ISFImageRef) isfImageRef	{
	return _localImage;
}


#pragma mark - ISFMTLSceneImgRef


- (uint32_t) width	{
	return _localImage->width;
}
- (uint32_t) height	{
	return _localImage->height;
}
- (uint32_t) depth	{
	return _localImage->depth;
}
- (BOOL) cubemap	{
	return _localImage->cubemap;
}
- (NSString *) imagePath	{
	return (_localImage->imagePath==nullptr) ? nil : [NSString stringWithUTF8String:_localImage->imagePath->c_str()];
}
- (NSArray<NSString*> *) cubePaths	{
	if (_localImage->cubePaths == nullptr)
		return nil;
	
	NSMutableArray		*tmpArray = [[NSMutableArray alloc] init];
	for (std::string cubePath : *_localImage->cubePaths)	{
		NSString		*tmpString = [NSString stringWithUTF8String:cubePath.c_str()];
		if (tmpString != nil)
			[tmpArray addObject:tmpString];
	}
	return [NSArray arrayWithArray:tmpArray];
}
- (BOOL) hasValidSize	{
	return _localImage->sizeIsValid();
}


@end

