#import "NSObject+MessagePack.h"

#include <msgpack.h>

@interface NSObject (NSObject_MessagePack_Private)

-(BOOL)MPPackWithPacker:(msgpack_packer*)pk;

@end

@implementation NSObject (NSObject_MessagePack)

-(NSData*)MPRepresentation {
    NSData* mp = nil;

    msgpack_sbuffer* buffer = msgpack_sbuffer_new();
    msgpack_packer* pk = msgpack_packer_new(buffer, msgpack_sbuffer_write);

    if ([self MPPackWithPacker:pk]) {
        mp = [NSData dataWithBytes:buffer->data length:buffer->size];
    }

    msgpack_sbuffer_free(buffer);
    msgpack_packer_free(pk);

    return mp;
}

-(BOOL)MPPackWithPacker:(msgpack_packer*)pk {
    if ([self isKindOfClass:[NSDictionary class]]) {
        msgpack_pack_map(pk, [(NSDictionary*)self count]);

        NSArray* keys = [(NSDictionary*)self allKeys];
        for (NSString* key in keys) {
            NSUInteger len = [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            msgpack_pack_raw(pk, len);
            msgpack_pack_raw_body(pk, [key UTF8String], len);
            if (![[(NSDictionary*)self objectForKey:key] MPPackWithPacker:pk]) {
                return NO;
            }
        }
    }
    else if ([self isKindOfClass:[NSArray class]]) {
        msgpack_pack_array(pk, [(NSArray*)self count]);
        for (NSObject* obj in (NSArray*)self) {
            if (![obj MPPackWithPacker:pk]) {
                return NO;
            }
        }
    }
    else if ([self isKindOfClass:[NSString class]]) {
        NSUInteger len = [(NSString*)self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        msgpack_pack_raw(pk, len);
        msgpack_pack_raw_body(pk, [(NSString*)self UTF8String], len);
    }
    else if ([self isKindOfClass:[NSData class]]) {
        NSUInteger len = [(NSData*)self length];
        msgpack_pack_raw(pk, len);
        msgpack_pack_raw_body(pk, [(NSData*)self bytes], len);
    }
    else if ([self isKindOfClass:[NSNumber class]]) {
        if ('c' == *[(NSNumber*)self objCType]) { // steel from SBJsonWriter
            if ([(NSNumber*)self boolValue]) {
                msgpack_pack_true(pk);
            }
            else {
                msgpack_pack_false(pk);
            }
        }
        else {
            // XXX
            msgpack_pack_int64(pk, [(NSNumber*)self longLongValue]);
        }
    }
    else if ([self isKindOfClass:[NSNull class]]) {
        msgpack_pack_nil(pk);
    }
    else {
        NSLog(@"MessagePack serialisation not supported for %@", [self class]);
        return NO;
    }

    return YES;
}

@end
