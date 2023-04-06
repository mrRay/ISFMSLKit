### Installation

- Check out a copy of this repo as a submodule in your project
- Add the source directory "ISFMSLKit" to your project.  This directory contains the objective-c classes we'll be using wrap the c++ classes in the ISFGLSLGeneratorLib
- The "extern" directory in this repo contains a number of subdirectories that, in turn, include dylibs and the header files needed to use them (or frameworks).  This is where precompiled resources from external sources are stored.
	- GLSLangValidatorLib converts GLSL to SPIR-V, and is from https://github.com/mrRay/glslang (which is basically a private fork of https://github.com/KhronosGroup/glslang)
	- SPIRVCrossLib converts SPIR-V to MSL, and is from https://github.com/mrRay/SPIRV-Cross (which is basically a private fork of https://github.com/KhronosGroup/SPIRV-Cross)
- The "submodules" directory contains submodules with source code that is by the classes in ISFMSLKit.  Because of this, its contents need to be added to your project.
	- ISFGLSLGeneratorLib provides a programmatic interface to ISF files and generates GLSL source code for them (which can then be converted to SPIR-V and the SPIR-V can then be converted to MSL).