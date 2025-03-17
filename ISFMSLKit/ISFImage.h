//
//  ISFImage.h
//  testISFtoMSL
//
//  Created by testadmin on 3/22/23.
//

#ifndef ISFMSLSceneImg_h
#define ISFMSLSceneImg_h

#include <memory>

#include <VVISF.hpp>

#import <VVMetalKit/VVMetalKit.h>




/*		This class exists to combine the VVISF GLSL generator lib (c++) with the VVMetalKit framework (obj-c).  
The GLSL generator has c++ classes that describe an ISF document, as well as its passes, attributes, and their 
respective values (including image values).

In particular, image values are described by VVISF::ISFImageInfoRef, which is really a 
std::shared_ptr<VVISF::ISFImageInfo>.  ISFImageInfo describes an image's dimensions and some basic info about it, but 
it doesn't contain any actual image data.  The goal of this subclass of ISFImageInfo is to make it to retain 
an instance of id<VVMTLTextureImage>, making it contain image data.  The VVISF backend will then retain and handle the image
data transparently for use in your implementation.				*/




class ISFImage : public VVISF::ISFImageInfo	{
	public:
		id<VVMTLTextureImage>		img;
	public:
		ISFImage(id<VVMTLTextureImage> inBuffer) : VVISF::ISFImageInfo(inBuffer.srcRect.size.width, inBuffer.srcRect.size.height), img(inBuffer)	{}
		ISFImage(const uint32_t & inWidth, const uint32_t & inHeight) : VVISF::ISFImageInfo(inWidth, inHeight), img(nil) {}
		
		virtual ~ISFImage()	{
			img = nil;
		}
		
		ISFImage & operator=(const ISFImage & n)	{
			if (&n == this)
				return *this;
			VVISF::ISFImageInfo::operator=(n);
			img = n.img;
			return *this;
		}
		
		bool operator==(const ISFImage & other) const	{
			bool		baseClassMatch = VVISF::ISFImageInfo::operator==(other);
			bool		localImgMatch = ((img == nil && other.img == nil)
				|| (img != nil && other.img != nil && [(VVMTLTextureImage*)img isEqual:other.img]));
			return baseClassMatch && localImgMatch;
		}
};
using ISFImageRef = std::shared_ptr<ISFImage>;




#endif /* ISFMSLSceneImg_h */
