#ifndef GLSLANGVALIDATORLIB_H
#define GLSLANGVALIDATORLIB_H

#include <vector>
#include <string>

void GLSLangValidatorLibFunc();

//	return a 'true' if the conversion is successful- if it fails, call the accompanying method to get more info
bool ConvertGLSLVertShaderToSPIRV(const std::string & inShaderString, std::vector<uint32_t> & outSPIRVData, std::string & outErrString);

bool ConvertGLSLFragShaderToSPIRV(const std::string & inShaderString, std::vector<uint32_t> & outSPIRVData, std::string & outErrString);


#endif	/*	GLSLANGVALIDATORLIB_H	*/