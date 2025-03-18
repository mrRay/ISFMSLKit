# ``ISFMSLKit``

<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->

## Overview

ISFMSLKit provides an objective-c interface for rendering and working with ISF files in a tech stack that uses Metal to perform rendering.  It works by transpiling the GLSL contents of ISF files to Metal shader language, compiling and running the ISF files natively as Metal shaders.

#### Quick orientation:

These are the public-facing classes you'll be working with:

- ``ISFValType`` enumerates the different types of values recognized by ISF.
- ``ISFMSLSceneVal-protocol`` describes an ISF value.
- ``ISFMSLDoc`` represents an "ISF file", created either from an ISF file on disk or with the contents of the ISF as a string.
- ``ISFMSLSceneAttrib`` describes an ISF file's "inputs", including its range and current value.
- ``ISFMSLScene`` renders ISF files to textures, and is the interface for updating the value of the ISF's inputs.
- ``ISFMSLCache`` compiles and caches ISF files.

#### How to use this framework:

Create the render properties, pool, and cache:
```objc
//	Create and initializes the global RenderProperties with default values
RenderProperties.global;
//	Create and initializes the global metal pool
VVMTLPool.global = [[VVMTLPool alloc] initWithDevice:RenderProperties.global.device];
//	Create the ISF cache
ISFMSLCache.global = [[ISFMSLCache alloc] initWithDirectoryPath:[@"~/Library/Application Support/my_app_name" stringByExpandingTildeInPath]];
```

##### Examining an ISF file (without rendering):

```objc
ISFMSLDoc *myDoc = [ISFMSLDoc createWithURL:url_of_my_doc];
```

##### Rendering ISF files to textures

```objc
ISFMSLScene *myScene = [[ISFMSLScene alloc] initWithDevice:RenderProperties.global.device];
[myScene loadURL:url_to_isf_file];
id<MTLCommandBuffer> cmdBuffer = [RenderProperties.global.renderQueue commandBuffer];
id<VVMTLTextureImage> newFrame = [myScene createAndRenderToTextureSized:NSMakeSize(1920,1080) inCommandBuffer:cmdBuffer];
[cmdBuffer commit];
[cmdBuffer waitUntilCompleted];
id<MTLTexture> rawMetalTexture = newFrame.texture;
```

##### Passing image values to ISF scenes

```objc
id<MTLTexture> rawMetalTexture = populated_from_your_app;
[myScene setValue:[ISFMSLSceneVal createWithTexture:rawMetalTextureInput] forInputNamed:@"myInputName"];

id<VVMTLTextureImage> aDifferentTextureImage = also_populated_from_your_app;
[myScene setValue:[ISFMSLSceneVal createWithTextureImage:aDifferentTextureImage] forInputNamed:@"anotherInputName"];
```

##### Caching an ISF file

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

<!--@START_MENU_TOKEN@-->Text<!--@END_MENU_TOKEN@-->

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
