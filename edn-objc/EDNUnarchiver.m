//
//  EDNUnarchiver.m
//  edn-objc
//
//  Created by Ben Mosher on 7/13/14.
//  Copyright (c) 2014 Ben Mosher. All rights reserved.
//

#import "EDNUnarchiver.h"
#import "EDNKeyword.h"

@interface EDNUnarchiver ()

@property (strong, nonatomic) EDNTaggedElement *data;
@property (strong, nonatomic) NSMutableArray *holdingCells;

@end

@implementation EDNUnarchiver

-(instancetype)initForReadingWithTaggedElement:(EDNTaggedElement *)data {
    if (self = [super init]) {
        _data = data;
        _holdingCells = [NSMutableArray new];
    }
    return self;
}

-(NSData *)decodeDataObject {
    Class rootClass = NSClassFromString(_data.tag.name);
    return [[rootClass alloc] initWithBase64EncodedString:_data.element options:0];
}

-(id)decodeRootObject {
    Class rootClass = NSClassFromString(_data.tag.name);
    return [[rootClass alloc] initWithCoder:self];
}

#pragma mark - NSCoding

-(id)decodeObjectForKey:(NSString *)key {
    EDNKeyword *keyword = [EDNKeyword keywordWithName:key];
    id obj = _data.element[keyword];
    if ([obj isEqual:[NSNull null]]) {
        return nil;
    }
    if ([obj isKindOfClass:[EDNTaggedElement class]]
        && [[[(EDNTaggedElement *)obj tag] ns] isEqualToString:@"edn-objc"]) {
        EDNUnarchiver *deeper = [[EDNUnarchiver alloc] initForReadingWithTaggedElement:obj];
        return [deeper decodeRootObject];
    }
    return obj;
}

-(double)decodeDoubleForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] doubleValue];
}

-(float)decodeFloatForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] floatValue];
}

-(int)decodeIntForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] intValue];
}

-(int32_t)decodeInt32ForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] intValue];
}

-(int64_t)decodeInt64ForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] longLongValue];
}

-(NSInteger)decodeIntegerForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] integerValue];
}

-(BOOL)decodeBoolForKey:(NSString *)key {
    return [[self decodeObjectForKey:key] boolValue];
}

-(const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(NSUInteger *)lengthp {
    NSData *data = [self decodeObjectForKey:key];
    if (data) [_holdingCells addObject:data]; // need to keep this sucker alive for the duration of the decoding
    *lengthp = [data length];
    return [data bytes];
}

@end
