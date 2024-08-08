//
//  ISFMSLDoc.m
//  ISFMSLKit
//
//  Created by testadmin on 8/6/24.
//

#import "ISFMSLDoc.h"

#include "VVISF.hpp"

#import "ISFMSLSceneAttrib_priv.h"




@interface ISFMSLDoc ()	{
	VVISF::ISFDocRef		doc;
}
@property (strong,readwrite) NSString * name;
@property (strong,readwrite) NSString * path;
@property (strong,readwrite) NSURL * url;

@property (strong,readwrite) NSString * isfDescription;
@property (strong,readwrite) NSString * credit;
@property (readwrite) ISFMSLProtocol type;

@property (strong,readwrite) NSArray<NSString*> * categories;

@property (strong,readwrite) NSArray<id<ISFMSLSceneAttrib>> * inputs;
@end




@implementation ISFMSLDoc

+ (instancetype) createWithURL:(NSURL *)n	{
	return [[ISFMSLDoc alloc] initWithURL:n];
}

- (instancetype) initWithURL:(NSURL *)n	{
	self = [super init];
	
	if (n == nil)	{
		self = nil;
	}
	
	NSFileManager		*fm = NSFileManager.defaultManager;
	if (![fm fileExistsAtPath:n.path])	{
		self = nil;
	}
	
	if (self != nil)	{
		doc = VVISF::CreateISFDocRef(n.path.UTF8String, false);
		if (doc == nullptr)	{
			self = nil;
			return self;
		}
		
		_name = [NSString stringWithUTF8String:doc->name().c_str()];
		_path = [NSString stringWithUTF8String:doc->path().c_str()];
		_url = [NSURL fileURLWithPath:_path];
		_isfDescription = [NSString stringWithUTF8String:doc->description().c_str()];
		_credit = [NSString stringWithUTF8String:doc->credit().c_str()];
		switch (doc->type())	{
			case VVISF::ISFFileType_None:		_type = ISFMSLProto_None; break;
			case VVISF::ISFFileType_Source:		_type = ISFMSLProto_Source; break;
			case VVISF::ISFFileType_Filter:		_type = ISFMSLProto_Filter; break;
			case VVISF::ISFFileType_Transition:	_type = ISFMSLProto_Transition; break;
			case VVISF::ISFFileType_All:		_type = ISFMSLProto_All; break;
		}
		
		NSMutableArray		*tmpArray = [NSMutableArray arrayWithCapacity:0];
		for (const std::string & category : doc->categories())	{
			NSString		*catString = [NSString stringWithUTF8String:category.c_str()];
			if (catString == nil || catString.length < 1)
				continue;
			[tmpArray addObject:catString];
		}
		_categories = [NSArray arrayWithArray:tmpArray];
		
		tmpArray = [NSMutableArray arrayWithCapacity:0];
		for (VVISF::ISFAttrRef attr_cpp : doc->inputs())	{
			//	make the attr and add it to our local array of attrs immediately
			id<ISFMSLSceneAttrib>		attr = [ISFMSLSceneAttrib createWithISFAttr:attr_cpp];
			if (attr == nil)
				continue;
			[tmpArray addObject:attr];
		}
		_inputs = [NSArray arrayWithArray:tmpArray];
	}
	
	return self;
}

@end
