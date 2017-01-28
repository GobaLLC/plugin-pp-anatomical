//
//  NSOperationQueue+Completion.m
//  QueueTest
//
//  Created by Artem Stepanenko on 23.11.13.
//  Copyright (c) 2013 Artem Stepanenko. All rights reserved.
//

#import "NSOperationQueue+Completion.h"

@implementation NSOperationQueue (Completion)

- (void)setCompletion:(NSOperationQueueCompletion)completion
{
    NSOperationQueueCompletion copiedCompletion = [completion copy];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self waitUntilAllOperationsAreFinished];

        dispatch_async(dispatch_get_main_queue(), ^{
            copiedCompletion();
        });
    });
}

@end
