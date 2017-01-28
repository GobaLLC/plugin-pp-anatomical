//
//  AnatomyImage.h
//  Hello
//
//  Created by Grayson Sharpe on 1/27/17.
//
//

#import <Foundation/Foundation.h>

@interface AnatomyImage : NSObject {
@private
    NSDictionary		*_sourceObj;
    NSString		*_folderPath;
    int _layerLevel;
    int _angleNumber;
}

@property(nonatomic, readonly) NSDictionary *sourceObj;
@property(nonatomic, readonly) NSString *folderPath;
@property(nonatomic, readonly) float height;
@property(nonatomic, readonly) float width;
@property(nonatomic, readonly) int layerLevel;
@property(nonatomic, readonly) int angleNumber;
@property(nonatomic, readonly) NSString *size;
@property(nonatomic, readonly) NSString *sourceUrl;

- (id)initWithDictionary:(NSDictionary *)obj folderPath:(NSString*)folderPath layerLevel:(int)layerLevel angleNumber:(int)angleNumber;

@end
