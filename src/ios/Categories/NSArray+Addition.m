//
//  NSArray+Addition.m
//  Hello
//
//  Created by Grayson Sharpe on 1/27/17.
//
//

#import "NSArray+Addition.h"

@implementation NSArray (Addition)

- (id)objectAtIndex:(NSUInteger)index or:(id)ifNullOrOutOfBounds
{
    if  (index >= [self count])
        return ifNullOrOutOfBounds;
        
    id o = [self objectAtIndex: index];
    if ([o isKindOfClass: [NSNull class]])
        return ifNullOrOutOfBounds;

    return o;
}

@end
