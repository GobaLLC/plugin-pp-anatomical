//
//  NSDictionary+Addition.m
//  Hello
//
//  Created by Grayson Sharpe on 1/27/17.
//
//

#import "NSDictionary+Addition.h"

@implementation NSDictionary (Addition)

- (id)objectForKey:(id)aKey or:(id)ifNull
{
    id o = [self objectForKey: aKey];
    if ((o == nil) || ([o isKindOfClass: [NSNull class]]))
        return ifNull;
    return o;
}

@end
