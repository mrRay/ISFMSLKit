//
//  ISFMTLScenePass_priv.m
//  testISFtoMSL
//
//  Created by testadmin on 3/7/23.
//

#import "ISFMTLScenePass_priv.h"
#import "ISFMTLScenePass.h"
#import "ISFMTLSceneImgRef_priv.h"




@implementation ISFMTLScenePass


#pragma mark - class methods


+ (instancetype) createWithPassTarget:(VVISF::ISFPassTargetRef)n	{
	return [[ISFMTLScenePass alloc] initWithPassTarget:n];
}


#pragma mark - init/dealloc


- (instancetype) initWithPassTarget:(VVISF::ISFPassTargetRef)n	{
	self = [super init];
	if (self != nil)	{
		_localPassTarget = n;
	}
	return self;
}


#pragma mark - key/value


- (VVISF::ISFPassTargetRef) passTargetRef	{
	return _localPassTarget;
}


#pragma mark - ISFMTLScenePass protocol


- (BOOL) float32	{
	return (_localPassTarget != nullptr && _localPassTarget->floatFlag()) ? YES : NO;
}
- (BOOL) persistent	{
	return (_localPassTarget != nullptr && _localPassTarget->persistentFlag()) ? YES : NO;
}
- (NSString *) name	{
	return (_localPassTarget==nullptr) ? nil : [NSString stringWithUTF8String:_localPassTarget->name().c_str()];
}
- (id<ISFMTLSceneImgRef>) image	{
	return (_localPassTarget==nullptr) ? nil : [ISFMTLSceneImgRef createWithImgRef:_localPassTarget->image()];
}

@synthesize pso;

@synthesize target;

@synthesize passIndex;



@end
