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
#import "iconv.h"
#include <errno.h>

#import "SparrowEmojiPlugin+Docomo.h"
#import "SparrowEmojiPlugin+Softbank.h"
#import "SparrowEmojiPlugin+Kddi.h"

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
        [self isSoftbankAddress:address] ||
        [self isKddiAddress:address]) {
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

- (BOOL)isKddiAddress:(NSString *)address {
    if ([address hasSuffix:@"ezweb.ne.jp"]) {
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
    } else if ([self isKddiAddress:address]) {
        str = [self replaceKddiEmoji:message];
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
    NSString *uppercaseCharset = [charset uppercaseString];
    if ([uppercaseCharset isEqualToString:@"SHIFT_JIS"]) {
        
        int encoding = 0;
        if ([uppercaseCharset isEqualToString:@"SHIFT_JIS"]) {
            encoding = NSShiftJISStringEncoding;
        }
        
        NSString *s = [NSString stringWithCString:(char *)[self performSelector:@selector(bytes)] encoding:encoding];
        NSUInteger len = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        unsigned char *buffer[len];
        
        [s getBytes:buffer maxLength:len usedLength:NULL
           encoding:NSUTF8StringEncoding
            options:NSStringEncodingConversionExternalRepresentation
              range:NSMakeRange(0, len)
     remainingRange:NULL];
        
        NSData *data = [[NSData alloc] initWithBytes:buffer length:len];
        
        result = [data my_lepStringWithCharset:@"utf-8"];
        [data release];
        
    } else if ([uppercaseCharset isEqualToString:@"ISO-2022-JP"]) {
        
        SparrowEmojiPlugin *sep = [SparrowEmojiPlugin sharedInstance];
        
        size_t inbytesleft = (size_t)[self performSelector:@selector(length)];
        size_t outbytesleft = inbytesleft * 4;
        char *inbuf = (char *)[self performSelector:@selector(bytes)];
        char *outbuf = malloc(outbytesleft + 1);
        char *old_outbuf = outbuf;
        
        iconv_t con = iconv_open("UTF-8", "ISO-2022-JP");
        if (con == (iconv_t) - 1) {
            return [self my_lepStringWithCharset:charset];
        }
        for (;;) {
            int convertResult = 0;
            size_t size = iconv(con, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
            if (size == (size_t) - 1) {
                if (errno == EILSEQ) {
                    convertResult = [sep convertKDDIISO2022JPToUTF8:con inbuf:&inbuf inbytesleft:&inbytesleft outbuf:&outbuf outbytesleft:&outbytesleft];
                }
                if (errno != EILSEQ || convertResult == 0) {
                    result = [self my_lepStringWithCharset:charset];
                    break;
                }
            } else {
                *outbuf = '\0';
                result = [NSString stringWithCString:old_outbuf encoding:NSUTF8StringEncoding];
                break;
            }
        }
        iconv_close(con);
        
    } else {
        result = [self my_lepStringWithCharset:charset];
    }
    
    return result;
}

@end
