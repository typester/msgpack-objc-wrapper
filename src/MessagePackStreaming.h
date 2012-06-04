#import <Foundation/Foundation.h>

@interface MessagePackStreaming : NSObject

-(void)feed:(NSData*)data;
-(BOOL)next;
-(id)data;

@end
