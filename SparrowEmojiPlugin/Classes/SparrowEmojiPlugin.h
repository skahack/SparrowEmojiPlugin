//
//  SparrowEmojiPlugin.h
//  SparrowEmojiPlugin
//
//  Created by SKAhack on 11/03/10.
//  Copyright 2011 All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SparrowEmojiPlugin : NSObject {
@private
    NSString *currentAddress;
}

+ (SparrowEmojiPlugin *)sharedInstance;
- (id)init;
- (void)dealloc;

+(void)load;
- (BOOL)isEmojiAddress:(NSString *)address;
- (BOOL)isDoCoMoAddress:(NSString *)address;
- (BOOL)isSoftbankAddress:(NSString *)address;
- (BOOL)isKddiAddress:(NSString *)address;
- (NSString *)replaceEmojiString:(NSString *)message sender:(NSString *)address;

@property (nonatomic, retain) NSString *currentAddress;
@end
