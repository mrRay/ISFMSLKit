#ifndef ISFBase_h
#define ISFBase_h

#include <vector>

#include <memory>
#include <string>
#include <map>
#include <iostream>
#include <limits>
#include <filesystem>

#include "VVISF_StringUtils.hpp"

/*!
\file
*/




namespace VVISF
{




//	some forward declarations used in this header
class ISFPassTarget;
class ISFImage;
//struct ISFVal;
class ISFDoc;
class ISFAttr;




/*!
\brief ISFImageRef is a shared pointer around an ISFImage instance.
\relates VVISF::ISFVal
*/
using ISFImageRef = std::shared_ptr<ISFImage>;
/*!
\brief ISFPassTargetRef is a shared pointer around an ISFPassTarget instance.
\relates VVISF::ISFPassTarget
*/
using ISFPassTargetRef = std::shared_ptr<ISFPassTarget>;
//! ISFDocRef is a shared pointer around an ISFDoc instance.
/*!
\relates VVISF::ISFDoc
ISFDocRef is the preferred means of working with ISFDoc instances, which can be extremely simple with no overhead or can potentially contain a variety of data values including GL resources (texture, buffers, etc).
*/
using ISFDocRef = std::shared_ptr<ISFDoc>;
/*!
\brief ISFAttrRef is a shared pointer around an ISFAttr instance.
\relates VVISF::ISFAttr
*/
using ISFAttrRef = std::shared_ptr<ISFAttr>;




/*!
The basic functionality offered by the ISF file loaded by an ISFDoc instance can be described by one or more of these enums (it's a bitmask)
*/
enum ISFFileType	{
	ISFFileType_None = 0,	//!<	No or unrecognized file type
	ISFFileType_Source = 1,	//!<	The file is a "source"- it generates images
	ISFFileType_Filter = 2,	//!<	The file is a "filter"- it defines an image-type input under the name "inputImage", which it modifies.
	ISFFileType_Transition = 4,	//!<	The file is a "transition"- it defines two image-type inputs ("startImage" and "endImage") in addition to a normalized float-type input ("progress"), which is used to "mix" from the start image to the end image.
	ISFFileType_All = 7	//!<	Convenience enumeration, should always evaluate to "all types simultaneously".
};
//!	Returns a std::string describing the passed ISFFileType
std::string ISFFileTypeString(const ISFFileType & n);




/*!
This enum is used to describe the GL environment that you want to generate shader source code for
*/
enum GLVersion	{
	GLVersion_Unknown,
	GLVersion_2,
	GLVersion_ES,
	GLVersion_ES2,
	GLVersion_ES3,
	GLVersion_33,
	GLVersion_4
};
/*!
Returns a std::string describing the passed GLVersion.
*/
inline const std::string GLVersionToString(const GLVersion & v)	{ switch (v) { case GLVersion_Unknown: return std::string("Unknown"); case GLVersion_2: return std::string("2"); case GLVersion_ES: return std::string("ES"); case GLVersion_ES2: return std::string("ES2"); case GLVersion_ES3: return std::string("ES3"); case GLVersion_33: return std::string("3.3"); case GLVersion_4: return std::string("4"); } return std::string("err"); }




/*!
Describes an integer range using a value (loc) and size (len).
*/
struct Range	{
	uint64_t		loc { std::numeric_limits<uint64_t>::max() };
	uint64_t		len { 0 };
	
	Range() {}
	Range(const uint64_t & inLoc, const uint64_t & inLen) : loc(inLoc), len(inLen) {}
	Range(const Range & n) : loc(n.loc), len(n.len) {}
	
	//!	Returns the max value of the range
	inline uint64_t max() const { return loc+len; }
	//!	Returns the min value of the range
	inline uint64_t min() const { return loc; }
	inline bool contains(const uint64_t & n)	{ return (n >= min() && n <= max()); }
	//!	Returns a true if the receiver intersects the passed range
	inline bool intersects(const Range & n) const	{
		uint64_t		receiverMin = min();
		uint64_t		receiverMax = max();
		uint64_t		passedMin = n.min();
		uint64_t		passedMax = n.max();
		//	if the receiver contains the min of the passed range
		if (passedMin>=receiverMin && passedMin<=receiverMax)	{
			return true;
		}
		//	else if the receiver contains the max of the passed range
		else if (passedMax>=receiverMin && passedMax<=receiverMax)	{
			return true;
		}
		//	else if the receiver encompasses the passed range
		else if (receiverMin < passedMin && receiverMax > passedMax)	{
			return true;
		}
		return false;
	}
	//!	Returns the range
	Range intersection(const Range & n) const	{
		//	same logic as intersects(), we just populate and return a Range struct instead
		uint64_t		receiverMin = min();
		uint64_t		receiverMax = max();
		uint64_t		passedMin = n.min();
		uint64_t		passedMax = n.max();
		uint64_t		tmpMin = std::numeric_limits<uint64_t>::max();
		uint64_t		tmpMax = std::numeric_limits<uint64_t>::max();
		//	if the receiver contains the min of the passed range
		if (passedMin>=receiverMin && passedMin<=receiverMax)	{
			tmpMin = passedMin;
			tmpMax = std::min(passedMax, receiverMax);
		}
		//	else if the receiver contains the max of the passed range
		else if (passedMax>=receiverMin && passedMax<=receiverMax)	{
			tmpMin = std::max(passedMin, receiverMin);
			tmpMax = passedMax;
		}
		//	else if the receiver encompasses the passed range
		else if (receiverMin < passedMin && receiverMax > passedMax)	{
			tmpMin = passedMin;
			tmpMax = passedMax;
		}
		
		return Range(tmpMin, tmpMax-tmpMin);
	}
	
	Range & operator=(const Range & n) { loc=n.loc; len=n.len; return *this; }
	bool operator==(const Range & n) const { return (loc==n.loc && len==n.len); }
	friend std::ostream & operator<<(std::ostream & os, const Range & n) { os << "{" << n.loc << ":" << n.len << "}"; return os; }
};




std::filesystem::path GetHomeDirectory();
std::filesystem::path PathByExpandingTildeInPath(const std::filesystem::path & inPath);

/*!
\brief Scans the passed path for valid ISF files, returns an array of strings/paths to the detected files.
\param inFolderPath The path of the directory to scan.
\param inType The type of ISFs to scan for.  Set to 0 or ISFFileType_All to return all valid ISFs in the passed folder- anything else will only return ISFs that match the passed type.
\param inRecursive Whether or not the scan should be recursive.
*/
std::shared_ptr<std::vector<std::string>> CreateArrayOfISFsForPath(const std::string & inFolderPath, const ISFFileType & inType=ISFFileType_None, const bool & inRecursive=true);
/*!
\brief Returns an array of strings/paths to the default ISF files.
\param inType The type of ISFs to scan for.  Set to 0 or ISFFileType_All to return all valid ISFs in the passed folder- anything else will only return ISFs that match the passed type.
*/
std::shared_ptr<std::vector<std::string>> CreateArrayOfDefaultISFs(const ISFFileType & inType=ISFFileType_None);
/*!
Returns 'true' if there is a file at the passed path, and that file appears to contain a valid ISF file.
*/
bool FileIsProbablyAnISF(const std::string & pathToFile);




}




#include "VVISF_Constants.hpp"
#include "VVISF_Err.hpp"
#include "ISFImage.hpp"
#include "ISFVal.hpp"




#endif /* ISFBase_h */
