//
//  ISFMSLDoc.h
//  ISFMSLKit
//
//  Created by testadmin on 8/6/24.
//

#import <Foundation/Foundation.h>

#import <ISFMSLKit/ISFMSLConstants.h>
#import <ISFMSLKit/ISFMSLSceneAttrib.h>

NS_ASSUME_NONNULL_BEGIN




/**		This class is a programmatic representation of an ISF document, and can be created either from the path to an ISF document or by passing it strings containing the ISF document's shaders.
It performs basic validation, and parses the ISF's contents on init, allowing you to examine the ISF file's attributes.  Behind the scenes, this class is bascally a wrapper around VVISF::ISFDoc from the ISFGLSLGenerator lib.
*/




@interface ISFMSLDoc : NSObject

+ (instancetype) createWithURL:(NSURL *)n;
+ (instancetype) createWithFragShader:(NSString *)inFragShader baseDir:(NSURL *)inBaseDir vertShader:(nullable NSString *)inVertShader;

///	Creates an ISFMSLDoc instance from a file on disk.
- (instancetype) initWithURL:(NSURL *)n;
///	Creates an ISFMSLDoc from a couple strings describing the fragment and vertex shader strings, along with a base directory that would contain any other resources required of the shader (such as still images).
- (instancetype) initWithFragShader:(NSString *)inFragShader baseDir:(NSURL *)inBaseDir vertShader:(nullable NSString *)inVertShader;

///	The name of the ISF document.
@property (readonly) NSString * name;
///	The path of the ISF document, expressed as an NSURL.
@property (readonly) NSURL * url;
///	The path of the ISF document, expressed as a string.
@property (readonly) NSString * path;

///	The description of the ISF document, as pulled from the JSON blob at the beginning of the document.
@property (readonly) NSString * isfDescription;
///	The 'credit' of the ISF document, as pulled from the JSON blob at the beginning of the document.
@property (readonly) NSString * credit;
///	The type of the ISF document, as determined by its content.
@property (readonly) ISFMSLProtocol type;

///	The array of categories used to describe the ISF document.
@property (readonly) NSArray<NSString*> * categories;
///	An ISF doc's inputs define parameters that can be changed at runtime to alter the visual content of the ISF's rendered frames.  These are represented programmatically by instances of ``ISFMSLSceneAttrib``, which describe the type, range, and value of each input/attribute.
@property (readonly) NSArray<id<ISFMSLSceneAttrib>> * inputs;

@end




NS_ASSUME_NONNULL_END
