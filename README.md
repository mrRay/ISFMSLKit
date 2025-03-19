### Orientation

ISFMSLKit is a Mac framework for working with [ISF](https://github.com/mrRay/ISF_Spec/?tab=readme-ov-file) files (and the GLSL source code they contain) in a tech stack that uses Metal to render content.  At runtime, it transpiles GLSL to MSL, caches the compiled binaries to disk for rapid access, and uses Metal to render content to textures.

This project contains a test app that demonstrates using a "generator" ISF to render an image which is processed through a "filter" ISF and then displayed- the test app has a couple ISF's "baked in", and also lets you use any ISFs installed on your system (if you don't have any installed, this repo includes `Vidvox ISF resources.pkg`, which can be used to install all the ISF files from [the ISF-Files repo](https://github.com/Vidvox/ISF-Files)).  To build the test app, open "ISFMSLKit.xcworkspace" and build "ISFMSLKitTestApp".

### Installation/Using ISFMSLKit in your project

Generally speaking, you're going to want to mimic the configuration of ISFMSLKitTestApp.  Specifically:
- Check out a copy of this repo as a submodule in your project- make sure that this project's submodules are also checked out and available, too.
- Add "ISFMSLKit.xcodeproj", "VVMetalKit.xcodeproj", "PINCache.xcodeproj", and "PINOperation.xcodeproj" to your project's workspace.
- In the "General" settings for your project, add "ISFMSLKit.framework", "VVMetalKit.framework", "PINCache.framework", and "PINOperation.framework" to your project's "Frameworks, Libraries, and Embedded Content".  Make sure they're configured to "Embed & Sign"!
- That's it, you're done!

### Dependencies (included)

- ISFMSLKit has a couple dependencies loaded as submodules- you won't have to work with these in any significant capacity while using ISFMSLKit, but if you start modifying or porting the project you'll bump into them in short order:
	- "PINCache" is used to cache information about ISF files as well as precompiled Metal shaders that can be used at runtime to load ISF files rapidly.
	- "VVMetalKit" is a framework that offers a number of basic Metal utilities- it's used by ISFMSLKit primarily to pool textures/buffers.
	- "ISFGLSLGenerator" is a cross-platform c++ lib for loading and working with ISF files- it provides a programmatic interface for exploring the attributes and parameters of ISF files, and generates GLSL source code for them.  If you want to build something akin to ISFMSLKit for another platform you will want to use this lib to generate the GLSL to be transpiled.  If you're familiar with [VVISF-GL](https://github.com/mrRay/VVISF-GL) then this should be very familiar, as it's basically a subset of that lib.

- ISFMSLKit has a couple dependencies loaded as precompiled binaries, located in the "extern" subdirectory- you won't have to work with these directly while using ISFMSLKit, and they're provided as precompiled binaries only to reduce compilation times (source is also available if you'd rather build your own):
	- "GLSLangValidatorLib" converts GLSL to SPIR-V, and is from the "GLSLangValidaborLib" branch of [https://github.com/mrRay/glslang](https://github.com/mrRay/glslang) (which is basically a private fork of [https://github.com/KhronosGroup/glslang](https://github.com/KhronosGroup/glslang)).  This is a very crude and simplistic fork of the glslang project- it compiles the CLI as a lib and provides two high-level functions (`ConvertGLSLVertShaderToSPIRV()` and `ConvertGLSLFragShaderToSPIRV()`) that pass values to the CLI's `main()` function.  If you're interested in porting this framework to another platform, you will with any luck be able to use this lib as-is.
	- "SPIRVCrossLib" converts SPIR-V to MSL, and is from the "SPIRVCrossLib" branch of [https://github.com/mrRay/SPIRV-Cross/tree/SPIRVCrossLib](https://github.com/mrRay/SPIRV-Cross/tree/SPIRVCrossLib) (which is basically a private fork of [https://github.com/KhronosGroup/SPIRV-Cross](https://github.com/KhronosGroup/SPIRV-Cross)).  This is also a very basic fork of the SPIRV-Cross project that compiles the CLI as a lib and provides two high-level functions (`ConvertVertSPIRVToMSL()` and `ConvertFragSPIRVToMSL()`) that pass values to the CLI's `main()` function.  If you're interested in porting this framework to another platform, you'll want to modify this lib to transpile the SPIR-V to your language of choice- and given the crude nature of it, this will probably be very easy.

### Quick examples (also see the included test app)

Create the render properties, pool, and cache:
```objc
//	Create and initializes the global RenderProperties with default values
RenderProperties.global;
//	Create and initializes the global metal pool
VVMTLPool.global = [[VVMTLPool alloc] initWithDevice:RenderProperties.global.device];
//	Create the ISF cache
ISFMSLCache.global = [[ISFMSLCache alloc] initWithDirectoryPath:[@"~/Library/Application Support/my_app_name" stringByExpandingTildeInPath]];
```

Examining and ISF file (without touching the render stack):
```objc
ISFMSLDoc *myDoc = [ISFMSLDoc createWithURL:url_of_my_doc];
```

Creating an ISF scene and using it to render a frame to a texture:
```objc
ISFMSLScene *myScene = [[ISFMSLScene alloc] initWithDevice:RenderProperties.global.device];
[myScene loadURL:url_to_isf_file];
id<MTLCommandBuffer> cmdBuffer = [RenderProperties.global.renderQueue commandBuffer];
id<VVMTLTextureImage> newFrame = [myScene createAndRenderToTextureSized:NSMakeSize(1920,1080) inCommandBuffer:cmdBuffer];
[cmdBuffer commit];
[cmdBuffer waitUntilCompleted];
id<MTLTexture> rawMetalTexture = newFrame.texture;
```

Passing images (textures) to the ISF scene:
```objc
id<MTLTexture> rawMetalTexture = populated_from_your_app;
[myScene setValue:[ISFMSLSceneVal createWithTexture:rawMetalTexture] forInputNamed:@"myInputName"];

id<VVMTLTextureImage> aDifferentTextureImage = also_populated_from_your_app;
[myScene setValue:[ISFMSLSceneVal createWithTextureImage:aDifferentTextureImage] forInputNamed:@"anotherInputName"];
```

Compiling/caching ISF files before they're used:
```objc
for (NSString * isfPath in GetArrayOfDefaultISFs(ISFMSLProto_All))	{
	//	This will compile the ISF file (or recompile it if it has changed since it was initially 
	//	compiled) and store the compiled shader to disk for reuse:
	[ISFMSLCache.global
		getCachedISFAtURL:[NSURL fileURLWithPath:isfPath]
		forDevice:RenderProperties.global.device
		hint:ISFMSLCacheHint_TranspileIfDateDelta];
}
```

