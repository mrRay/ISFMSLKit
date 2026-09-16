//
//  ISFMSLFuncSignature.hpp
//  ISFMSLKit
//
//  Created by testadmin on 9/16/26.
//

#ifndef ISFMSLFuncSignature_hpp
#define ISFMSLFuncSignature_hpp

#include <map>
#include <string>
#include <vector>


namespace VVISF	{
	class ISFDoc;
}




//	the MSL entry-point names for the ISF at a path, derived from its sanitized file stem
struct ISFMSLEntryPointNames	{
	std::string		vert;
	std::string		frag;
};
ISFMSLEntryPointNames ISFMSLEntryPointNamesForPath(const std::string & inPath);


//	the entry-point args of one transpiled MSL function, keyed by var name.  the uniform block is keyed "VVISF_UNIFORMS&".
struct ISFMSLFuncSignature	{
	std::map<std::string,int>		buffers;
	std::map<std::string,int>		textures;
	std::map<std::string,int>		samplers;
};
ISFMSLFuncSignature ISFMSLParseFuncSignature(const std::string & inFuncName, const std::string & inMSLSrc);


//	an arg that ISFMSLScene's render path will never bind
struct ISFMSLUnboundArg	{
	std::string		name;
	std::string		kind;	//	"buffer" or "texture"
	int				index;
};
//	returns the args in the passed signature that the render path can't bind: any buffer but the uniform block at index 0, and any texture the doc doesn't name
std::vector<ISFMSLUnboundArg> ISFMSLFindUnboundArgs(const ISFMSLFuncSignature & inSig, VVISF::ISFDoc & inDoc);




#endif /* ISFMSLFuncSignature_hpp */
