//
//  ISFMSLTranspilerError.m
//  ISFMSLKit
//
//  Created by testadmin on 8/5/24.
//

#import "ISFMSLTranspilerError.h"

#import "ISFMSLCacheObject.h"

#include "VVISF.hpp"

#include "GLSLangValidatorLib.hpp"
#include "SPIRVCrossLib.hpp"




@interface ISFMSLTranspilerError ()

@property (strong) NSURL * url;
//@property (weak,readwrite) ISFMSLCacheObject * parent;
@property (strong) id<MTLDevice> device;


@property (readwrite) BOOL vertGLSLErrFlag;
@property (strong) NSString * vertGLSLErrString;

@property (readwrite) BOOL vertSPIRVErrFlag;
@property (strong) NSString * vertSPIRVErrString;

@property (readwrite) BOOL vertMSLErrFlag;
@property (strong) NSString * vertMSLErrString;


@property (readwrite) BOOL fragGLSLErrFlag;
@property (strong) NSString * fragGLSLErrString;

@property (readwrite) BOOL fragSPIRVErrFlag;
@property (strong) NSString * fragSPIRVErrString;

@property (readwrite) BOOL fragMSLErrFlag;
@property (strong) NSString * fragMSLErrString;


@property (strong) NSString * glslVertSrc;
@property (strong) NSString * glslFragSrc;
@property (strong) NSString * glslVertSrcWithLineNumbers;
@property (strong) NSString * glslFragSrcWithLineNumbers;

@property (strong) NSString * mslVertSrc;
@property (strong) NSString * mslFragSrc;
@property (strong) NSString * mslVertSrcWithLineNumbers;
@property (strong) NSString * mslFragSrcWithLineNumbers;

@end




@implementation ISFMSLTranspilerError

+ (instancetype) createWithURL:(NSURL*)u device:(id<MTLDevice>)d	{
	return [[ISFMSLTranspilerError alloc] initWithURL:u device:d];
}

- (instancetype) initWithURL:(NSURL*)u device:(id<MTLDevice>)d
{
	self = [super init];
	
	if (u == nil || d == nil)
		self = nil;
	
	if (self != nil)	{
		self.url = u;
		self.device = d;
		
		_vertGLSLErrFlag = NO;
		_vertGLSLErrString = nil;
		_vertSPIRVErrFlag = NO;
		_vertSPIRVErrString = nil;
		_vertMSLErrFlag = NO;
		_vertMSLErrString = nil;
		
		_fragGLSLErrFlag = NO;
		_fragGLSLErrString = nil;
		_fragSPIRVErrFlag = NO;
		_fragSPIRVErrString = nil;
		_fragMSLErrFlag = NO;
		_fragMSLErrString = nil;
		
		_glslVertSrc = nil;
		_glslFragSrc = nil;
		_glslVertSrcWithLineNumbers = nil;
		_glslFragSrcWithLineNumbers = nil;
		
		_mslVertSrc = nil;
		_mslFragSrc = nil;
		_mslVertSrcWithLineNumbers = nil;
		_mslFragSrcWithLineNumbers = nil;
		
		NSString		*fullPath = self.url.path;
		const char		*inURLPathCStr = fullPath.UTF8String;
		#if DEBUG
		VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, true);
		#else
		VVISF::ISFDocRef		doc = VVISF::CreateISFDocRef(inURLPathCStr, false);
		#endif
		
		NSError			*nsErr = nil;
		std::string		tmpErrString = std::string("");
		std::string		glslFragSrc;
		std::string		glslVertSrc;
		
		//	generate GLSL for the ISF, store local obj-c copies of it
		//doc->generateShaderSource(&glslFragSrc, &glslVertSrc, GLVersion_2, false);
		doc->generateShaderSource(&glslFragSrc, &glslVertSrc, VVISF::GLVersion_4, true);
		
		{
			_glslVertSrc = [NSString stringWithUTF8String:glslVertSrc.c_str()];
			_glslFragSrc = [NSString stringWithUTF8String:glslFragSrc.c_str()];
			
			__block int			tmpCount = 1;
			__block NSMutableString		*tmpMutString = nil;
			
			tmpCount = 1;
			tmpMutString = [[NSMutableString alloc] init];
			[_glslVertSrc enumerateLinesUsingBlock:^(NSString *tmpLine, BOOL *stop)	{
				if (tmpCount < 1000)
					[tmpMutString appendFormat:@"%d\t:\t%@\n",tmpCount,tmpLine];
				else
					[tmpMutString appendFormat:@"%d:\t%@\n",tmpCount,tmpLine];
				++tmpCount;
			}];
			_glslVertSrcWithLineNumbers = [NSString stringWithString:tmpMutString];
			
			tmpCount = 1;
			tmpMutString = [[NSMutableString alloc] init];
			[_glslFragSrc enumerateLinesUsingBlock:^(NSString *tmpLine, BOOL *stop)	{
				if (tmpCount < 1000)
					[tmpMutString appendFormat:@"%d\t:\t%@\n",tmpCount,tmpLine];
				else
					[tmpMutString appendFormat:@"%d:\t%@\n",tmpCount,tmpLine];
				++tmpCount;
			}];
			_glslFragSrcWithLineNumbers = [NSString stringWithString:tmpMutString];
		}
		
		//	convert the GLSL to SPIR-V (or try to, anyway)
		std::vector<uint32_t>	spirvVtxData;
		std::vector<uint32_t>	spirvFrgData;
		
		tmpErrString = std::string("");
		self.vertGLSLErrFlag = !ConvertGLSLVertShaderToSPIRV(glslVertSrc, spirvVtxData, tmpErrString);
		if (self.vertGLSLErrFlag)	{
			NSString		*tmpString = [NSString stringWithUTF8String:tmpErrString.c_str()];
			self.vertGLSLErrString = [tmpString
				stringByReplacingOccurrencesOfString:@"ERROR: stdin:"
				withString:@"ERR: "];
			//self.vertGLSLErrString = [NSString stringWithUTF8String:tmpErrString.c_str()];
		}
		
		tmpErrString = std::string("");
		self.fragGLSLErrFlag = !ConvertGLSLFragShaderToSPIRV(glslFragSrc, spirvFrgData, tmpErrString);
		if (self.fragGLSLErrFlag)	{
			NSString		*tmpString = [NSString stringWithUTF8String:tmpErrString.c_str()];
			self.fragGLSLErrString = [tmpString
				stringByReplacingOccurrencesOfString:@"ERROR: stdin:"
				withString:@"ERR: "];
			//self.fragGLSLErrString = [NSString stringWithUTF8String:tmpErrString.c_str()];
		}
		
		//	if we don't have any GLSL errors, proceed with converting the SPIR-V to MSL
		if (!self.vertGLSLErrFlag && !self.fragGLSLErrFlag)	{
			std::string		mslVertSrc;
			std::string		mslFragSrc;
			
			tmpErrString = std::string("");
			self.vertSPIRVErrFlag = !ConvertVertSPIRVToMSL(spirvVtxData, std::string("main"), mslVertSrc, tmpErrString);
			if (self.vertSPIRVErrFlag)	{
				self.vertSPIRVErrString = [NSString stringWithUTF8String:tmpErrString.c_str()];
			}
			
			tmpErrString = std::string("");
			self.fragSPIRVErrFlag = !ConvertFragSPIRVToMSL(spirvFrgData, std::string("main"), mslFragSrc, tmpErrString);
			if (self.fragSPIRVErrFlag)	{
				self.fragSPIRVErrString = [NSString stringWithUTF8String:tmpErrString.c_str()];
			}
			
			//	if we don't have any SPIRV errors, proceed with compiling the MSL source code
			if (!self.vertSPIRVErrFlag && !self.fragSPIRVErrFlag)	{
				_mslVertSrc = [NSString stringWithUTF8String:mslVertSrc.c_str()];
				_mslFragSrc = [NSString stringWithUTF8String:mslFragSrc.c_str()];
				
				__block int			tmpCount = 1;
				__block NSMutableString		*tmpMutString = nil;
				
				tmpCount = 1;
				tmpMutString = [[NSMutableString alloc] init];
				[_mslVertSrc enumerateLinesUsingBlock:^(NSString *tmpLine, BOOL *stop)	{
					if (tmpCount < 1000)
						[tmpMutString appendFormat:@"%d\t:\t%@\n",tmpCount,tmpLine];
					else
						[tmpMutString appendFormat:@"%d:\t%@\n",tmpCount,tmpLine];
					++tmpCount;
				}];
				_mslVertSrcWithLineNumbers = [NSString stringWithString:tmpMutString];
				
				tmpCount = 1;
				tmpMutString = [[NSMutableString alloc] init];
				[_mslFragSrc enumerateLinesUsingBlock:^(NSString *tmpLine, BOOL *stop)	{
					if (tmpCount < 1000)
						[tmpMutString appendFormat:@"%d\t:\t%@\n",tmpCount,tmpLine];
					else
						[tmpMutString appendFormat:@"%d:\t%@\n",tmpCount,tmpLine];
					++tmpCount;
				}];
				_mslFragSrcWithLineNumbers = [NSString stringWithString:tmpMutString];
				
				nsErr = nil;
				id<MTLLibrary>		vertLib = [self.device newLibraryWithSource:_mslVertSrc options:nil error:&nsErr];
				self.vertMSLErrFlag = (vertLib == nil || nsErr != nil);
				if (self.vertMSLErrFlag)	{
					self.vertMSLErrString = (nsErr==nil) ? @"" : nsErr.localizedDescription;
				}
				vertLib = nil;
				
				nsErr = nil;
				id<MTLLibrary>		fragLib = [self.device newLibraryWithSource:_mslFragSrc options:nil error:&nsErr];
				self.fragMSLErrFlag = (fragLib == nil || nsErr != nil);
				if (self.fragMSLErrFlag)	{
					self.fragMSLErrString = (nsErr==nil) ? @"" : nsErr.localizedDescription;
				}
				fragLib = nil;
			}
		}
		
		//	if there aren't any error flags, everything checked out: clear myself and return nil!
		if (!_vertGLSLErrFlag
		&& !_vertSPIRVErrFlag
		&& !_vertMSLErrFlag
		&& !_fragGLSLErrFlag
		&& !_fragSPIRVErrFlag
		&& !_fragMSLErrFlag)
		{
			self = nil;
			return self;
		}
		
	}
	
	return self;
}

- (NSString *) description	{
	return [NSString stringWithFormat:@"<ISFMSLTranspilerError %@, %d/%d, %d/%d, %d/%d>",self.url.lastPathComponent,_vertGLSLErrFlag,_fragGLSLErrFlag,_vertSPIRVErrFlag,_fragSPIRVErrFlag,_vertMSLErrFlag,_fragMSLErrFlag];
}

- (NSString *) generateStringForLogFile	{
	NSMutableString		*mut = [[NSMutableString alloc] init];
	
	//NSString		*div = @"----    ----    ----    ----    ----    ----    ----";
	NSString		*div = @"********************************\n";
	
	[mut appendFormat:@"FILE: %@\n",self.url.lastPathComponent];
	[mut appendFormat:@"PATH: %@\n",self.url.path];
	
	//	if there aren't any error flags, log as such and return immediately
	if (!_vertGLSLErrFlag && !_fragGLSLErrFlag
	&& !_vertSPIRVErrFlag && !_fragSPIRVErrFlag
	&& !_vertMSLErrFlag && !_fragMSLErrFlag)	{
		[mut appendString:@"No errors detected\n"];
		return [NSString stringWithString:mut];
	}
	
	//	if there's a GLSL error flag (an error compiling the GLSL to SPIR-V), add it to the string
	if (_vertGLSLErrFlag || _fragGLSLErrFlag)	{
		[mut appendString:div];
		if (_vertGLSLErrString != nil)	{
			[mut appendString:@"Error Compiling GLSL Vertex Shader to SPIR-V:\n"];
			[mut appendFormat:@"%@\n",_vertGLSLErrString];
		}
		if (_fragGLSLErrString != nil)	{
			[mut appendString:@"Error Compiling GLSL Fragment Shader to SPIR-V:\n"];
			[mut appendFormat:@"%@\n",_fragGLSLErrString];
		}
		
		[mut appendString:div];
		
		//	add the GLSL source code to the string
		[mut appendFormat:@"GLSL Vertex Shader:\n%@\n",_glslVertSrcWithLineNumbers];
		[mut appendFormat:@"GLSL Fragment Shader:\n%@\n",_glslFragSrcWithLineNumbers];
	}
	//	if there's a GLSL error flag, we're done now and can return
	if (_vertGLSLErrFlag || _fragGLSLErrFlag)	{
		return [NSString stringWithString:mut];
	}
	
	//	if there's a SPIR-V error flag (an error converting SPIR-V to MSL), add it to the string
	if (_vertSPIRVErrFlag || _fragSPIRVErrFlag)	{
		[mut appendString:div];
		if (_vertSPIRVErrString != nil)	{
			[mut appendString:@"Error converting Vertex Shader SPIR-V to MSL:\n"];
			[mut appendFormat:@"%@\n",_vertSPIRVErrString];
		}
		if (_fragSPIRVErrString != nil)	{
			[mut appendString:@"Error converting Fragment Shader SPIR-V to MSL:\n"];
			[mut appendFormat:@"%@\n",_fragSPIRVErrString];
		}
		//	we're done now and can return
		return [NSString stringWithString:mut];
	}
	
	//	if there's a MSL error flag (an error compiling the MSL to run on the device), add it to the string
	if (_vertMSLErrFlag || _fragMSLErrFlag)	{
		[mut appendString:div];
		if (_vertMSLErrString != nil)	{
			[mut appendString:@"Error compiling MSL Vertex shader:\n"];
			[mut appendFormat:@"%@\n",_vertMSLErrString];
		}
		if (_fragMSLErrString != nil)	{
			[mut appendString:@"Error compiling MSL Fragment shader:\n"];
			[mut appendFormat:@"%@\n",_fragMSLErrString];
		}
		
		[mut appendString:div];
		
		//	add the MSL source code to the string
		[mut appendFormat:@"MSL Vertex Shader:\n%@\n",_mslVertSrcWithLineNumbers];
		[mut appendFormat:@"MSL Fragment Shader:\n%@\n",_mslFragSrcWithLineNumbers];
		
		[mut appendString:div];
		
		//	add the GLSL source code to the string
		[mut appendFormat:@"GLSL Vertex Shader:\n%@\n",_glslVertSrcWithLineNumbers];
		[mut appendFormat:@"GLSL Fragment Shader:\n%@\n",_glslFragSrcWithLineNumbers];
	}
	
	return [NSString stringWithString:mut];
}

@end
