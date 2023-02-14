#ifndef ISFStringUtils_hpp
#define ISFStringUtils_hpp

#include <string>
#include <filesystem>
#include <vector>
#include <map>
//#include "VVISF_Base.hpp"




namespace VVISF
{




//	functions for doing some basic path manipulation
//std::vector<std::string> PathComponents(const std::string & n);
//std::string LastPathComponent(const std::string & n);
//std::string StringByDeletingLastPathComponent(const std::string & n);
std::filesystem::path PathByDeletingLastPathComponent(const std::filesystem::path & inPath);
//std::string PathFileExtension(const std::string & n);
//std::string StringByDeletingExtension(const std::string & n);
//std::string StringByDeletingLastAndAddingFirstSlash(const std::string & n);
//std::string StringByDeletingLastSlash(const std::string & n);
//bool CaseInsensitiveCompare(const std::string & a, const std::string & b);
//	this function returns a std::string instance created by passing a c-style format std::string + any number of arguments
std::string FmtString(const char * fmt, ...);
//	this function returns the number of lines in the passed std::string
int NumLines(const std::string & n);




struct ISFVal;
struct Range;


//	this function parses a std::string as a bool val, and returns either an CreateISFValNull (if the std::string couldn't be decisively parsed) or an CreateISFValBool (if it could)
ISFVal ParseStringAsBool(const std::string & n);
//	this function evaluates the passed std::string and returns a null ISFVal (if the std::string couldn't be evaluated) or a float ISFVal (if it could)
ISFVal ISFValByEvaluatingString(const std::string & n, const std::map<std::string, double> & inSymbols=std::map<std::string,double>());
//	this function parses a function call from a std::string, dumping the strings of the function arguments 
//	to the provided array.  returns the size of the function std::string (from first char of function call 
//	to the closing parenthesis of the function call)
Range LexFunctionCall(const std::string & inBaseStr, const Range & inFuncNameRange, std::vector<std::string> & outVarArray);

std::string TrimWhitespace(const std::string & inBaseStr);

void FindAndReplaceInPlace(std::string & inSearch, std::string & inReplace, std::string & inBase);
void FindAndReplaceInPlace(const char * inSearch, const char * inReplace, std::string & inBase);

std::string FullPath(const std::string & inRelativePath);


}


#endif /* ISFStringUtils_hpp */

