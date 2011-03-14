//
//  SparrowEmojiPlugin.m
//  SparrowEmojiPlugin
//
//  Created by SKAhack on 11/03/10.
//  Copyright 2011 All rights reserved.
//

#import "SparrowEmojiPlugin.h"
#import "JRSwizzle.h"
#import <objc/runtime.h>

#import "SparrowEmojiPlugin+Docomo.h"
#import "SparrowEmojiPlugin+Softbank.h"

@implementation SparrowEmojiPlugin

+ (void)load {
    Class class = objc_getClass("LEPAbstractMessage");
    Class class1 = objc_getClass("NSData");
    
    [class jr_swizzleMethod:@selector(mmBodyHTMLRenderingWithAccount:withWebView:hideQuoted:enableActivity:)
                  withMethod:@selector(my_mmBodyHTMLRenderingWithAccount:withWebView:hideQuoted:enableActivity:) error:NULL];
    
    [class1 jr_swizzleMethod:@selector(lepStringWithCharset:)
                 withMethod:@selector(my_lepStringWithCharset:) error:NULL];

}

#pragma mark -
#pragma mark Instantiations

+ (SparrowEmojiPlugin *)sharedInstance {
    static id sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -

- (BOOL)isEmojiAddress:(NSString *)address {
    if ([self isDoCoMoAddress:address] ||
        [self isSoftbankAddress:address]) {
        return YES;
    }
    return NO;
}

- (BOOL)isDoCoMoAddress:(NSString *)address {
    if ([address hasSuffix:@"docomo.ne.jp"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isSoftbankAddress:(NSString *)address {
    if ([address hasSuffix:@"softbank.ne.jp"] ||
        [address hasSuffix:@"i.softbank.jp"] ||
        [address hasSuffix:@"disney.ne.jp"] ||
        [address hasSuffix:@"vodafone.ne.jp"]) {
        return YES;
    }
    return NO;
}

- (NSString *)replaceEmojiString:(NSString *)message sender:(NSString *)address {

    NSString *str;
    if ([self isDoCoMoAddress:address]) {
        str = [self replaceDocomoEmoji:message];
    } else if ([self isSoftbankAddress:address]) {
        str = [self replaceSoftbankEmoji:message];
    }
    
    return str;
}

@end

@implementation NSObject(SparrowEmojiPlugin)

- (NSString *)my_mmBodyHTMLRenderingWithAccount:(id)arg1 withWebView:(id)arg2 hideQuoted:(BOOL)arg3 enableActivity:(BOOL)arg4 {

    NSString *str = [self my_mmBodyHTMLRenderingWithAccount:arg1 withWebView:arg2 hideQuoted:arg3 enableActivity:arg4];
    NSString *address = [[[self performSelector:@selector(header)] performSelector:@selector(from)] performSelector:@selector(mailbox)];

    SparrowEmojiPlugin *sep = [SparrowEmojiPlugin sharedInstance];
    if ([sep isEmojiAddress:address]) {
        return [sep replaceEmojiString:str sender:address];
    }
    
    return str;
}

- (NSString *)my_lepStringWithCharset:(NSString *)charset {

    NSString *result;
    if ([charset isEqualToString:@"SHIFT_JIS"]) {
        NSString *s = [NSString stringWithCString:(char *)[self performSelector:@selector(bytes)] encoding:NSShiftJISStringEncoding];
        NSString *c = @"utf-8";
        NSUInteger l = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        unsigned char *buffer[l];
        
        [s getBytes:buffer maxLength:l usedLength:NULL
           encoding:NSUTF8StringEncoding
            options:NSStringEncodingConversionExternalRepresentation
              range:NSMakeRange(0, l)
     remainingRange:NULL];
        
        NSData *data = [[NSData alloc] initWithBytes:buffer length:l];
        
        result = [data my_lepStringWithCharset:c];
        
    } else {
        result = [self my_lepStringWithCharset:charset];
    }
    
    return result;
}

@end
