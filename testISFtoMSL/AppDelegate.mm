//
//  AppDelegate.m
//  testISFtoMSL
//
//  Created by testadmin on 2/12/23.
//

#import "AppDelegate.h"
#include "GLSLangValidatorLib.hpp"
#include "SPIRVCrossLib.hpp"

#include <string>
#include <vector>
#include <iostream>

#include "VVISF.hpp"

using namespace std;
using namespace VVISF;


int ISFxMSL(const std::string & inPath, const std::string & outMSLVS, const std::string & outMSLFS);


@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//GLSLangValidatorLibFunc();
	//SPIRVCrossLibFunc();
	
	//string			tmpString("/Users/testadmin/Documents/VDMX5/VDMX5/supplemental resources/ISF tests+tutorials/Test-Functionality.fs");
	//ISFDocRef		tmpDoc = CreateISFDocRef(tmpString);
	//string			*fragSrc = new std::string();
	//string			*vertSrc = new std::string();
	//tmpDoc->generateShaderSource(fragSrc, vertSrc, GLVersion_4, false);
	//delete fragSrc;
	//fragSrc = nullptr;
	//delete vertSrc;
	//vertSrc = nullptr;
	
	std::shared_ptr<vector<string>>		files = CreateArrayOfDefaultISFs();
	
	for (const auto & file : *files)	{
		cout << "\tfound file " << std::filesystem::path(file).stem() << endl;
		string		outMSLVtxString;
		string		outMSLFrgString;
		int			isfErr = ISFxMSL(file, outMSLVtxString, outMSLFrgString);
		if (isfErr != 0)	{
			NSLog(@"ERR: %d processing file %s",isfErr,std::filesystem::path(file).stem().c_str());
			break;
		}
		break;
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
	return YES;
}

@end




int ISFxMSL(const std::string & inPath, const std::string & outMSLVS, const std::string & outMSLFS)	{
	ISFDocRef		tmpDoc = CreateISFDocRef(inPath);
	std::string		fragSrc;
	std::string		vertSrc;
	tmpDoc->generateShaderSource(&fragSrc, &vertSrc, GLVersion_4, true);
	//cout << "***************************************************************" << endl;
	//cout << vertSrc << endl;
	//cout << "***************************************************************" << endl;
	//cout << fragSrc << endl;
	//cout << "***************************************************************" << endl;
	
	vector<uint32_t>	outSPIRVVtxData;
	vector<uint32_t>	outSPIRVFrgData;
	if (!ConvertGLSLVertShaderToSPIRV(vertSrc, outSPIRVVtxData))	{
		NSLog(@"ERR: unable to convert vert shader for file %s, bailing",std::filesystem::path(inPath).stem().c_str());
		return 1;
	}
	
	//outSPIRVData.clear();
	if (!ConvertGLSLFragShaderToSPIRV(fragSrc, outSPIRVFrgData))	{
		NSLog(@"ERR: unable to convert frag shader for file %s, bailing",std::filesystem::path(inPath).stem().c_str());
		return 2;
	}
	
	string		outMSLVtxString;
	string		outMSLFrgString;
	if (!ConvertSPIRVToMSL(outSPIRVVtxData, outMSLVtxString))	{
		NSLog(@"ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inPath).stem().c_str());
		return 3;
	}
	if (!ConvertSPIRVToMSL(outSPIRVFrgData, outMSLFrgString))	{
		NSLog(@"ERR: unable to convert SPIRV for file %s, bailing",std::filesystem::path(inPath).stem().c_str());
		return 4;
	}
	//cout << "***************************************************************" << endl;
	//cout << outMSLVtxString << endl;
	//cout << "***************************************************************" << endl;
	//cout << outMSLFrgString << endl;
	//cout << "***************************************************************" << endl;
	return 0;
}
