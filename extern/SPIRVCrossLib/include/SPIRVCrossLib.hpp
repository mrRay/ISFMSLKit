#ifndef SPIRVCROSSLIB_H
#define SPIRVCROSSLIB_H

void SPIRVCrossLibFunc();

bool ConvertSPIRVToMSL(const std::vector<uint32_t> & inSPIRVData, std::string & outShaderString);

#endif	/*	SPIRVCROSSLIB_H	*/