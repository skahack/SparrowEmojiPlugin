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

@implementation SparrowEmojiPlugin

+ (void)load {
    Class class = objc_getClass("LEPAbstractMessage");
    
    [class jr_swizzleMethod:@selector(mmBodyHTMLRenderingWithAccount:withWebView:hideQuoted:enableActivity:)
                  withMethod:@selector(my_mmBodyHTMLRenderingWithAccount:withWebView:hideQuoted:enableActivity:) error:NULL];

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
    if ([self isDoCoMoAddress:address]) {
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

- (NSString *)replaceEmojiString:(NSString *)message sender:(NSString *)address {
    NSString *str;
    if ([self isDoCoMoAddress:address]) {
        str = [self replaceDocomoEmoji:message];
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


@end
