#ifndef GLSLANGVALIDATORLIB_H
#define GLSLANGVALIDATORLIB_H

#include <string>


void GLSLangValidatorLibFunc();

bool ConvertGLSLVertShaderToSPIRV(const std::string & inShaderString, std::vector<uint32_t> & outSPIRVData);
bool ConvertGLSLFragShaderToSPIRV(const std::string & inShaderString, std::vector<uint32_t> & outSPIRVData);


#endif	/*	GLSLANGVALIDATORLIB_H	*/