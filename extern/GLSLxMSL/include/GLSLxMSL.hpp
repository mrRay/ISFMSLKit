#ifndef LIB_H
#define LIB_H

#include <string>
#include <vector>

namespace GLSLxMSL	{
	void GLSLxMSLTestFunc();
	
	bool ConvertGLSLVertShaderToSPIRV(const std::string & inShaderString, std::vector<uint32_t> & outSPIRVData);
	bool ConvertGLSLFragShaderToSPIRV(const std::string & inShaderString, std::vector<uint32_t> & outSPIRVData);
	
	bool ConvertSPIRVToMSL(const std::vector<uint32_t> & inSPIRVData, std::string & outShaderString);
}

#endif	/*	LIB_H	*/