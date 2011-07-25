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

@synthesize currentAddress;

+ (void)load {
    Class class = objc_getClass("LEPAbstractMessage");
    Class class1 = objc_getClass("NSData");
    
    [class jr_swizzleMethod:@selector(mmBodyHTMLRenderingWithAccount:withWebView:hideQuoted:enableActivity:printing:)
                 withMethod:@selector(my_mmBodyHTMLRenderingWithAccount:withWebView:hideQuoted:enableActivity:printing:) error:NULL];
    
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
    } else {
        str = [self replaceSoftbankEmoji:message];
    }
    
    return str;
}

@end

@implementation NSObject(SparrowEmojiPlugin)

- (NSString *)my_mmBodyHTMLRenderingWithAccount:(id)arg1 withWebView:(id)arg2 hideQuoted:(BOOL)arg3 enableActivity:(BOOL)arg4 printing:(BOOL)arg5 {

    SparrowEmojiPlugin *sep = [SparrowEmojiPlugin sharedInstance];
    
    NSString *address = [[[self performSelector:@selector(header)] performSelector:@selector(from)] performSelector:@selector(mailbox)];
    sep.currentAddress = address;
    
    NSString *str = [self my_mmBodyHTMLRenderingWithAccount:arg1 withWebView:arg2 hideQuoted:arg3 enableActivity:arg4 printing:arg5];

    return [sep replaceEmojiString:str sender:address];
    
    return str;
}

- (NSString *)my_lepStringWithCharset:(NSString *)charset {

    SparrowEmojiPlugin *sep = [SparrowEmojiPlugin sharedInstance];
    
    NSString *result;
    NSString *uppercaseCharset = [charset uppercaseString];
    if ([uppercaseCharset isEqualToString:@"SHIFT_JIS"] &&
        ![sep isDoCoMoAddress:sep.currentAddress] &&
        ![sep isKddiAddress:sep.currentAddress]) {
        
        size_t inbytesleft = (size_t)[self performSelector:@selector(length)];
        size_t outbytesleft = inbytesleft * 4;
        char *inbuf = (char *)[self performSelector:@selector(bytes)];
        char *outbuf = malloc(outbytesleft + 1);
        char *old_outbuf = outbuf;
        
        iconv_t con = iconv_open("UTF-8", "SHIFT_JIS");
        if (con == (iconv_t) - 1) {
            return [self my_lepStringWithCharset:charset];
        }
        for (;;) {
            unsigned char first = inbuf[0];
            size_t temp_inbytesleft;
            size_t convertResult;
            
            if (first < 0x80) {
                temp_inbytesleft = 1;
                convertResult = iconv(con, &inbuf, &temp_inbytesleft, &outbuf, &outbytesleft);
                temp_inbytesleft = 1;
            } else {
                temp_inbytesleft = 2;
                if (first == 0xF7 || first == 0xF9 || first == 0xFB) {
                    convertResult = [sep convertSoftBankSJISToUTF8:con
                                                             inbuf:&inbuf
                                                       inbytesleft:&temp_inbytesleft
                                                            outbuf:&outbuf
                                                      outbytesleft:&outbytesleft];
                } else {
                    convertResult = iconv(con, &inbuf, &temp_inbytesleft, &outbuf, &outbytesleft);
                }
                temp_inbytesleft = 2;
            }

            if (convertResult == (size_t) - 1) {
                result = [self my_lepStringWithCharset:charset];
                break;
            } else {
                inbytesleft -= temp_inbytesleft;
            }
            
            if (inbytesleft <= 0) {
                *outbuf = '\0';
                result = [NSString stringWithCString:old_outbuf encoding:NSUTF8StringEncoding];
                break;
            }
        }
        iconv_close(con);
        
    } else if ([uppercaseCharset isEqualToString:@"ISO-2022-JP"]) {
        
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
    
    sep.currentAddress = @"";
    
    return result;
}

@end
