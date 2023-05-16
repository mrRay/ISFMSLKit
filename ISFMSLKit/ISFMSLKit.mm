//
//  ISFMSLKit.m
//  ISFMSLKit
//
//  Created by testadmin on 5/16/23.
//

#include "ISFMSLKit.h"
#include "VVISF.hpp"







NSArray<NSString*> * CreateArrayOfDefaultISFs()	{
	NSMutableArray	*returnMe = [[NSMutableArray alloc] init];
	auto			defaultISFPaths = VVISF::CreateArrayOfDefaultISFs();
	for (const auto & defaultISFPath : *defaultISFPaths)	{
		NSString		*tmpPath = [NSString stringWithUTF8String:defaultISFPath.c_str()];
		if (tmpPath == nil)
			continue;
		[returnMe addObject:tmpPath];
	}
	return returnMe;
}
