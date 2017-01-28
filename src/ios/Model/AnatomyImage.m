//
//  AnatomyImage.m
//  Hello
//
//  Created by Grayson Sharpe on 1/27/17.
//
//

#import "AnatomyImage.h"
#import "NSDictionary+Addition.h"

@implementation AnatomyImage

@synthesize sourceObj = _sourceObj;
@synthesize folderPath = _folderPath;
@synthesize layerLevel = _layerLevel;
@synthesize angleNumber = _angleNumber;

- (id)initWithDictionary:(NSDictionary *)obj folderPath:(NSString*)folderPath layerLevel:(int)layerLevel angleNumber:(int)angleNumber
{
    assert(obj);
    if ((self = [super init])) {
        _sourceObj = obj;
        _folderPath = folderPath;
        _layerLevel = layerLevel;
        _angleNumber = angleNumber;
    }
    
    return self;
}

- (void)dealloc
{
    _sourceObj = nil;
    _folderPath = nil;
}

- (NSString*)sourceUrl{
    return [self.sourceObj objectForKey:@"sUrl" or:@""];
}


- (NSString*)size{
    return [self.sourceObj objectForKey:@"nB" or:@""];
}

- (float)height
{
    return [[self.sourceObj objectForKey:@"nH" or:nil] floatValue];
}

- (float)width
{
    return [[self.sourceObj objectForKey:@"nW" or:nil] floatValue];
}


@end
