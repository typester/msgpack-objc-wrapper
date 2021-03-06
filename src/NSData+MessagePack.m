#import "NSData+MessagePack.h"

#include <msgpack.h>

@interface NSData (NSData_MessagePack_Private)
-(id)MPDecodeMsgpackObject:(msgpack_object*)obj;
@end

@implementation NSData (NSData_MessagePack)

-(id)MPValue {
    msgpack_unpacked m;
    msgpack_unpacked_init(&m);

    id res = nil;

    BOOL success = msgpack_unpack_next(&m, [self bytes], [self length], NULL);
    if (success) {
        res = [self MPDecodeMsgpackObject:&(m.data)];
    }

    msgpack_unpacked_destroy(&m);

    return res;
}

-(NSString*)MPStringValue {
    NSString* s = [[NSString alloc] initWithBytes:[self bytes]
                                           length:[self length]
                                         encoding:NSUTF8StringEncoding];
    return [s autorelease];
}

-(id)MPDecodeMsgpackObject:(msgpack_object*)obj {
    id res = nil;

    switch (obj->type) {
        case MSGPACK_OBJECT_NIL:
            res = [NSNull null];
            break;
        case MSGPACK_OBJECT_BOOLEAN:
            res = [NSNumber numberWithBool:obj->via.boolean];
            break;
        case MSGPACK_OBJECT_POSITIVE_INTEGER:
            res = [NSNumber numberWithUnsignedLongLong:obj->via.u64];
            break;
        case MSGPACK_OBJECT_NEGATIVE_INTEGER:
            res = [NSNumber numberWithLongLong:obj->via.i64];
            break;
        case MSGPACK_OBJECT_DOUBLE:
            res = [NSNumber numberWithDouble:obj->via.dec];
            break;
        case MSGPACK_OBJECT_RAW:
            res = [NSData dataWithBytes:obj->via.raw.ptr length:obj->via.raw.size];
            break;
        case MSGPACK_OBJECT_ARRAY: {
            NSMutableArray* array = [NSMutableArray arrayWithCapacity:obj->via.array.size];
            msgpack_object* o = obj->via.array.ptr;

            for (int i = 0; i < obj->via.array.size; ++i) {
                [array addObject:[self MPDecodeMsgpackObject:o + i]];
            }

            res = [NSArray arrayWithArray:array];
            break;
        }
        case MSGPACK_OBJECT_MAP: {
            NSMutableDictionary* map =
                [NSMutableDictionary dictionaryWithCapacity:obj->via.map.size];
            msgpack_object_kv* kv = obj->via.map.ptr;

            for (int i = 0; i < obj->via.map.size; ++i) {
                NSData* key = [self MPDecodeMsgpackObject:&((kv + i)->key)];
                NSAssert([key isKindOfClass:[NSData class]], nil);

                id value = [self MPDecodeMsgpackObject:&((kv + i)->val)];
                [map setObject:value forKey:[key MPStringValue]];
            }

            res = [NSDictionary dictionaryWithDictionary:map];
            break;
        }
        default:
            NSLog(@"Unsupported msgpack type: %d", obj->type);
            break;
    }

    return res;
}

@end
