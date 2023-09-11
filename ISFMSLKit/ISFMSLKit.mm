//
//  ISFMSLKit.m
//  ISFMSLKit
//
//  Created by testadmin on 5/16/23.
//

#include "ISFMSLKit.h"
#include "VVISF.hpp"

#include <string>




#define A_HAS_B(a,b) (((a)&(b))==(b))




using namespace VVISF;

VVISF::ISFFileType ISFFileTypeFromISFMSLProtocol(ISFMSLProtocol inProtocol);




NSArray<NSString*> * GetArrayOfDefaultISFs( ISFMSLProtocol inProtocol )	{
	NSMutableArray	*returnMe = [[NSMutableArray alloc] init];
	
	ISFFileType		targetFileType = ISFFileTypeFromISFMSLProtocol( inProtocol );
	auto			defaultISFPaths = VVISF::CreateArrayOfDefaultISFs( targetFileType );
	for (const auto & defaultISFPath : *defaultISFPaths)	{
		NSString		*tmpPath = [NSString stringWithUTF8String:defaultISFPath.c_str()];
		if (tmpPath == nil)
			continue;
		[returnMe addObject:tmpPath];
	}
	return returnMe;
}


NSArray<NSString*> * GetISFsInDirectory(NSString * inDirPath, BOOL inRecursive, ISFMSLProtocol inProtocol)	{
	if (inDirPath == nil)
		return nil;
	if (![[NSFileManager defaultManager] fileExistsAtPath:inDirPath])
		return nil;
	
	ISFFileType			targetFileType = ISFFileTypeFromISFMSLProtocol( inProtocol );
	
	std::string		parentDirPath( inDirPath.UTF8String );
	NSMutableArray		*returnMe = [[NSMutableArray alloc] init];
	for (const auto & tmpPath : *CreateArrayOfISFsForPath(parentDirPath, targetFileType, ((inRecursive)?true:false)) )	{
		NSString		*tmpStr = [NSString stringWithUTF8String:tmpPath.c_str()];
		if (tmpStr != nil)
			[returnMe addObject:tmpStr];
	}
	
	return returnMe;
}





VVISF::ISFFileType ISFFileTypeFromISFMSLProtocol(ISFMSLProtocol inProtocol)	{
	using namespace VVISF;
	
	ISFFileType			targetFileType = ISFFileType_None;
	
	if (A_HAS_B(inProtocol, ISFMSLProto_Source))
		targetFileType = static_cast<ISFFileType>(targetFileType | ISFFileType_Source);
	if (A_HAS_B(inProtocol, ISFMSLProto_Filter))
		targetFileType = static_cast<ISFFileType>(targetFileType | ISFFileType_Filter);
	if (A_HAS_B(inProtocol, ISFMSLProto_Transition))
		targetFileType = static_cast<ISFFileType>(targetFileType | ISFFileType_Transition);
	
	return targetFileType;
}
