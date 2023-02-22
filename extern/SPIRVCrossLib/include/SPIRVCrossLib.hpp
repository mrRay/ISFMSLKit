#ifndef SPIRVCROSSLIB_H
#define SPIRVCROSSLIB_H

void SPIRVCrossLibFunc();

bool ConvertVertSPIRVToMSL(const std::vector<uint32_t> & inSPIRVData, const std::string & inNewMainFuncName, std::string & outShaderString);
bool ConvertFragSPIRVToMSL(const std::vector<uint32_t> & inSPIRVData, const std::string & inNewMainFuncName, std::string & outShaderString);

#endif	/*	SPIRVCROSSLIB_H	*/