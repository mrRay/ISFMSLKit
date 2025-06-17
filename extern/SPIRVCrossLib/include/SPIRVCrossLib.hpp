#ifndef SPIRVCROSSLIB_H
#define SPIRVCROSSLIB_H

#include <vector>
#include <string>

void SPIRVCrossLibFunc();

bool ConvertVertSPIRVToMSL(const std::vector<uint32_t> & inSPIRVData, const std::string & inNewMainFuncName, std::string & outShaderString, std::string & outErrString);
bool ConvertFragSPIRVToMSL(const std::vector<uint32_t> & inSPIRVData, const std::string & inNewMainFuncName, std::string & outShaderString, std::string & outErrString);

#endif	/*	SPIRVCROSSLIB_H	*/