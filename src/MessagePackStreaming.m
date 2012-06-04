#import "MessagePackStreaming.h"

#include <msgpack.h>
#include <string.h>

@implementation MessagePackStreaming {
    msgpack_unpacker* _unpacker;
    msgpack_unpacked _result;
}

-(id)init {
    self = [super init];
    if (self) {
        self->_unpacker = msgpack_unpacker_new(MSGPACK_UNPACKER_INIT_BUFFER_SIZE);
        msgpack_unpacked_init(&self->_result);
    }
    return self;
}

-(void)dealloc {
    msgpack_unpacker_free(self->_unpacker);
    msgpack_unpacked_destroy(&self->_result);

    [super dealloc];
}

-(void)feed:(NSData*)data {
    msgpack_unpacker_reserve_buffer(self->_unpacker, [data length]);
    memcpy(msgpack_unpacker_buffer(self->_unpacker), [data bytes], [data length]);
    msgpack_unpacker_buffer_consumed(self->_unpacker, [data length]);
}

-(BOOL)next {
    return msgpack_unpacker_next(self->_unpacker, &self->_result);
}

static id decode_msgpack_object(msgpack_object* obj) {
    id res = nil;
    uint8_t* flag;

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
            flag = (uint8_t*)obj->via.raw.ptr;
            if (0xff == *flag) {
                // data
                res = [NSData dataWithBytes:obj->via.raw.ptr + 1
                                     length:obj->via.raw.size - 1];
            }
            else {
                // utf-8
                res = [[[NSString alloc] initWithBytes:obj->via.raw.ptr
                                                length:obj->via.raw.size
                                              encoding:NSUTF8StringEncoding] autorelease];
            }

            break;
        case MSGPACK_OBJECT_ARRAY: {
            NSMutableArray* array = [NSMutableArray arrayWithCapacity:obj->via.array.size];
            msgpack_object* o = obj->via.array.ptr;

            for (int i = 0; i < obj->via.array.size; ++i) {
                [array addObject:decode_msgpack_object(o + i)];
            }

            res = [NSArray arrayWithArray:array];
            break;
        }
        case MSGPACK_OBJECT_MAP: {
            NSMutableDictionary* map =
                [NSMutableDictionary dictionaryWithCapacity:obj->via.map.size];
            msgpack_object_kv* kv = obj->via.map.ptr;

            for (int i = 0; i < obj->via.map.size; ++i) {
                NSString* key = decode_msgpack_object(&((kv + i)->key));
                NSAssert([key isKindOfClass:[NSString class]], nil);

                id value = decode_msgpack_object(&((kv + i)->val));
                [map setObject:value forKey:key];
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

-(id)data {
    return decode_msgpack_object(&self->_result.data);
}

@end
