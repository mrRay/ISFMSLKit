//
//  ISFMSLFuncSignature.mm
//  ISFMSLKit
//
//  Created by testadmin on 9/16/26.
//

#include "ISFMSLFuncSignature.hpp"

#include <cctype>
#include <filesystem>
#include <regex>

#include "VVISF.hpp"




//	this func finds the passed string (whole-word-match only) in the other passed string, and returns the whole line it's on
static std::string FindNamedMainFuncDeclaration(const std::string & inFuncName, const std::string & inShaderString)	{
	std::regex			regex = std::regex( std::string("\\b") + inFuncName + std::string("\\b") );
	std::smatch			matches;
	if (!std::regex_search(inShaderString, matches, regex))	{
		return std::string("");
	}
	int				line_begin = (int)matches.position();
	int				line_end = line_begin + (int)matches.length();
	//  run from the beginning of the match backward until we find a line-break
	for (auto iter = std::begin(inShaderString)+line_begin; iter != std::begin(inShaderString); --iter) {
		if (*iter == 10 || *iter == 13)
			break;
		--line_begin;
	}
	//  run from the end of the match forward until we find a line-break
	for (auto iter = std::begin(inShaderString)+line_end; iter != std::end(inShaderString); ++iter) {
		//cout << "\tchecking " << *iter << endl;
		if (*iter == 10 || *iter == 13)
			break;
		++line_end;
	}
	return inShaderString.substr(line_begin, line_end - line_begin);
}
//	this func accepts a function declaration, and returns an array of the args passed to it, stripped of enclosing whitespace
static std::vector<std::string> GetFuncStringArgs(const std::string & inFuncLine)	{
	std::vector<std::string>		returnMe;
	//	find the first left parenthesis in inFuncLine using find_first_of
	auto		leftParenIter = inFuncLine.find_first_of('(');
	//	find the last right parenthesis in inFuncLine using find_last_of
	auto		rightParenIter = inFuncLine.find_last_of(')');
	//	make a substring of inFuncLine using the characters between leftParenIter and rightParenIter, non-inclusive
	std::string		inFuncParams = inFuncLine.substr(leftParenIter+1, rightParenIter-leftParenIter-1);
	//	split up inFuncParams using commas as the delimiter
	std::vector<std::string>		inFuncParamsSplit;
	std::regex			regex = std::regex( std::string(",") );
	std::sregex_token_iterator		iter(inFuncParams.begin(), inFuncParams.end(), regex, -1);
	std::sregex_token_iterator		end;
	while (iter != end)	{
		if (iter->length() > 0)
			inFuncParamsSplit.push_back(*iter);
		++iter;
	}
	for (auto iter = std::begin(inFuncParamsSplit); iter != std::end(inFuncParamsSplit); ++iter)	{
		//	trim whitespace from the beginning of the string
		auto		trimBeginIter = iter->find_first_not_of(" \t");
		//	trim whitespace from the end of the string
		auto		trimEndIter = iter->find_last_not_of(" \t");
		//	make a substring of the string using the trimmed indices
		std::string		trimmedString = iter->substr(trimBeginIter, trimEndIter-trimBeginIter+1);
		//	add the trimmed string to the map
		returnMe.push_back(trimmedString);
	}
	return returnMe;
}
//	this func looks through the array of function arguments looking for the passed attribute string (stuff
//	like "buffer(0)") and returns a map of the variable name and the index.  it also inserts "VVISF_UNIFORMS"
//	instead of the var name (which is expected to be an arbitray integer) in the map where appropriate.
static std::map<std::string,int> SearchForMetalAttrInFuncArgs(const std::string & searchAttrName, const std::vector<std::string> & funcArgsToSearch)	{
	//std::cout << "SearchForMetalAttrInFuncArgs()" << std::endl;
	std::map<std::string,int>		returnMe;
	
	for (auto funcArg : funcArgsToSearch)	{
		std::string		regexString = std::string("\\[\\[[\\s]*") + searchAttrName + std::string("\\([\\s]*([0-9]+)[\\s]*\\)[\\s]*\\]\\]");
		std::regex		regex = std::regex(regexString);
		for (auto searchTermIter = std::sregex_iterator(funcArg.begin(), funcArg.end(), regex); searchTermIter != std::sregex_iterator(); ++searchTermIter)	{
			std::smatch		match = *searchTermIter;
			int			parsedBufferIndex = stoi(match[1]);
			
			//	split 'funcArg' up using spaces as the delimiter
			std::vector<std::string>		funcArgWords;
			std::regex			regex = std::regex( std::string(" ") );
			std::sregex_token_iterator		iter(funcArg.begin(), funcArg.end(), regex, -1);
			std::sregex_token_iterator		end;
			while (iter != end)	{
				funcArgWords.push_back(*iter);
				++iter;
			}
			//std::cout << "funcArgWords are: ";
			//bool		first = true;
			//for (auto tmpStr : funcArgWords)	{
			//	if (!first)
			//		std::cout << ", ";
			//	std::cout << tmpStr;
			//	first = false;
			//}
			//std::cout << std::endl;
			
			if (funcArgWords.size() < 2)
				continue;
			
			//	variable name's the second-to-last term in the array!
			std::string		varName = funcArgWords[ funcArgWords.size()-2 ];
			//	if 'funcArgWords' contains a string that is equal to "VVISF_UNIFORMS&", then set 'varName' equal to "VVISF_UNIFORMS&"
			for (auto tmpStr : funcArgWords)	{
				if (tmpStr == "VVISF_UNIFORMS&")	{
					varName = "VVISF_UNIFORMS&";
					break;
				}
			}
			
			returnMe[varName] = parsedBufferIndex;
		}
	}
	
	return returnMe;
}




ISFMSLEntryPointNames ISFMSLEntryPointNamesForPath(const std::string & inPath)	{
	std::string			raw_filename = std::filesystem::path(inPath).stem().string();
	std::string			filename { "" };
	for (auto tmpchar : raw_filename)	{
		if (isalnum(tmpchar))
			filename += tmpchar;
		else
			filename += "_";
	}
	
	//	we have to give the functions explicit names- otherwise they're both just called "main", and we can't link them in a lib with other functions
	ISFMSLEntryPointNames		returnMe;
	returnMe.vert = "VV"+filename+"VertFunc";
	returnMe.frag = "VV"+filename+"FragFunc";
	return returnMe;
}


ISFMSLFuncSignature ISFMSLParseFuncSignature(const std::string & inFuncName, const std::string & inMSLSrc)	{
	//	first look for the line in the shader src that contains the name of the main function- we need to search it, so first we want to make a standalone string with the whole line
	std::string			funcLine = FindNamedMainFuncDeclaration(inFuncName, inMSLSrc);
	std::vector<std::string>		funcArgs = GetFuncStringArgs(funcLine);
	
	//	these maps let you figure out which variable name (eg: "inputImage") a given attribute index (eg: "texture", "0") corresponds to.
	//	we need this data to apply textures/buffers to the metal render command encoder.
	ISFMSLFuncSignature		returnMe;
	returnMe.buffers = SearchForMetalAttrInFuncArgs("buffer", funcArgs);
	returnMe.textures = SearchForMetalAttrInFuncArgs("texture", funcArgs);
	returnMe.samplers = SearchForMetalAttrInFuncArgs("sampler", funcArgs);
	return returnMe;
}


std::vector<ISFMSLUnboundArg> ISFMSLFindUnboundArgs(const ISFMSLFuncSignature & inSig, VVISF::ISFDoc & inDoc)	{
	std::vector<ISFMSLUnboundArg>		returnMe;
	
	//	the render path binds exactly one buffer the shader can see- the uniform block, hard-coded at index 0 in both stages
	for (const auto & [varName, varIndex] : inSig.buffers)	{
		if (varName != std::string("VVISF_UNIFORMS&") || varIndex != 0)
			returnMe.push_back( ISFMSLUnboundArg{ varName, std::string("buffer"), varIndex } );
	}
	
	auto		AttrsContainName = [](std::vector<VVISF::ISFAttrRef> & inAttrs, const std::string & inName) -> bool	{
		for (const VVISF::ISFAttrRef & attr : inAttrs)	{
			if (attr != nullptr && attr->name() == inName)
				return true;
		}
		return false;
	};
	auto		PassesContainName = [](std::vector<VVISF::ISFPassTargetRef> & inPasses, const std::string & inName) -> bool	{
		for (const VVISF::ISFPassTargetRef & pass : inPasses)	{
			if (pass != nullptr && pass->name().length() > 0 && pass->name() == inName)
				return true;
		}
		return false;
	};
	
	//	the render path binds a texture only for a name the doc knows- an input (image or audio), an image import, or a named render pass
	for (const auto & [varName, varIndex] : inSig.textures)	{
		if (AttrsContainName(inDoc.inputs(), varName)
		|| AttrsContainName(inDoc.imageImports(), varName)
		|| PassesContainName(inDoc.renderPasses(), varName))
		{
			continue;
		}
		returnMe.push_back( ISFMSLUnboundArg{ varName, std::string("texture"), varIndex } );
	}
	
	//	samplers need no rule: the render path binds the shared sampler state at every sampler index it finds, and the texture half of an extra sampler is caught above
	
	return returnMe;
}
