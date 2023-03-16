#ifndef ISFBase_h
#define ISFBase_h

#include <vector>

#include <memory>
#include <string>
#include <map>
#include <iostream>
#include <limits>
#include <filesystem>
#include <math.h>
#include <chrono>

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




//	we pass a buffer of data to the vertex + frag shaders that contains info describing the rendering state and param values
//	this struct (ISFRenderInfo) is the first piece of information in the buffer, it's sort of like a header
struct ISFRenderInfo	{
	int				PASSINDEX;
	float			RENDERSIZE[2];
	float			TIME;
	float			TIMEDELTA;
	float			DATE[4];
	uint32_t		FRAMEINDEX;
};
//	this struct describes a cube texture by describing its dimensions, and may be present in the buffer of data passed to vertex + frag shaders
struct ISFCubeInfo	{
	float			size[2];
};
//	this struct describes an image within a texture, and may be present in the buffer of data passed to vertex + frag shaders
struct ISFImgInfo	{
	float			rect[4];	//	the image consists of the pixels in this region of the texture
	float			size[2];	//	the size of the texture asset.  'rect' is necessarily a subset of (0, 0, size[0], size[1])
	uint32_t		flip;	//	whether or not the image in 'rect' is flipped vertically
};




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




//! Struct describing a timevalue as the quotient of two numbers, a value (64-bit unsigned int) and a scale factor (32-bit int).

using RawTSClockType = std::chrono::steady_clock;
using RawTSDuration = std::chrono::microseconds;
using RawTSTime = std::chrono::time_point<RawTSClockType, RawTSDuration>;

using DoubleTimeDuration = std::chrono::duration<double, std::ratio<1>>;
using DoubleTimeTime = std::chrono::time_point<RawTSClockType, DoubleTimeDuration>;

struct Timestamp	{
	
	
	//!	Creates a new Timestamp with the current time
	Timestamp()	{
		rawTime = std::chrono::time_point_cast<RawTSDuration>(RawTSClockType::now());
	}
	//!	Creates a new Timestamp with the passed time as a chrono::time_point< chrono::steady_clock, chrono::microseconds> >
	Timestamp(const RawTSTime & inRawTime)	{
		rawTime = inRawTime;
	}
	//!	Creates a new Timestamp with the passed time as a chrono::microseconds
	Timestamp(const RawTSDuration & inRawDuration)	{
		rawTime = RawTSTime(inRawDuration);
	}
	//!	Creates a new Timestamp with the passed time in seconds as a double
	Timestamp(const double & inTimeInSeconds)	{
		rawTime = std::chrono::time_point_cast<RawTSDuration>( DoubleTimeTime( DoubleTimeDuration(inTimeInSeconds) ) );
	}
	//!	Creates a new Timestamp expressed as the quotient of the two passed numbers (the number of frames divided by the number of seconds in which they occur)
	Timestamp(const int & inFrameCount, const int & inSecondsCount)	{
		if (inSecondsCount == 0)
			rawTime = std::chrono::time_point_cast<RawTSDuration>( DoubleTimeTime( DoubleTimeDuration( double(0.0) ) ) );
		else
			rawTime = std::chrono::time_point_cast<RawTSDuration>( DoubleTimeTime( DoubleTimeDuration( double(inFrameCount)/double(inSecondsCount) ) ) );
	}

	
	//!	Calculates the frame index of the receiver with the passed FPS, expressed as the quotient of two integers.
	inline double frameIndexForFPS(const int & inFrameCount, const int & inSecondsCount)	{
		RawTSTime		tmpTime(RawTSDuration(rawTime.time_since_epoch().count() * inFrameCount / inSecondsCount));
		return std::chrono::time_point_cast<DoubleTimeDuration>(tmpTime).time_since_epoch().count();
	}
	//!	Calculates the frame index of the receiver with the passed FPS.
	inline double frameIndexForFPS(const double & inFPS)	{
		return frameIndexForFPS(int(inFPS * 1000000), 1000000);
	}
	//!	Calls 'frameIndexForFPS()' and then rounds the result before returning it
	inline int64_t nearestFrameIndexForFPS(const int & inFrameCount, const int & inSecondsCount)	{
		return int64_t(round(frameIndexForFPS(inFrameCount, inSecondsCount)));
	}
	//!	Calls 'frameIndexForFPS()' and then rounds the result before returning it
	inline int64_t nearestFrameIndexForFPS(const double & inFPS)	{
		return nearestFrameIndexForFPS(int(inFPS * 1000000), 1000000);
	}
	
	
	//!	Calculates and returns the receivers time in seconds, expressed as a double.
	inline double getTimeInSeconds() const	{
		return std::chrono::time_point_cast<DoubleTimeDuration>(rawTime).time_since_epoch().count();
	}
	
	
	friend inline std::ostream & operator<<(std::ostream & os, const Timestamp & rs)	{
		os << "<Timestamp " << double(rs.getTimeInSeconds()) << ">";
		return os;
	}
	inline Timestamp operator-(const Timestamp & n) const	{
		return Timestamp(RawTSDuration(this->rawTime.time_since_epoch().count() - n.rawTime.time_since_epoch().count()));
	}
	inline Timestamp operator+(const Timestamp & n) const	{
		return Timestamp(RawTSDuration(this->rawTime.time_since_epoch().count() + n.rawTime.time_since_epoch().count()));
	}
	inline bool operator==(const Timestamp & n) const	{
		return (this->rawTime == n.rawTime);
	}
	inline bool operator<(const Timestamp & n) const	{
		return (this->rawTime < n.rawTime);
	}
	inline bool operator>(const Timestamp & n) const	{
		return (this->rawTime > n.rawTime);
	}
	
private:
	RawTSTime		rawTime;
};




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
