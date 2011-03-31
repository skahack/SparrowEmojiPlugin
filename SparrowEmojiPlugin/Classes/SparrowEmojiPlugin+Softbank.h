//
//  SparrowEmojiPlugin+Softbank.h
//  SparrowEmojiPlugin
//
//  Created by SKAhack on 11/03/12.
//  Copyright 2011 All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SparrowEmojiPlugin.h"

#import "iconv.h"

@interface SparrowEmojiPlugin (Softbank)

- (NSString *)replaceSoftbankEmoji:(NSString *)message;
- (size_t)convertSoftBankSJISToUTF8:(iconv_t)con inbuf:(char **)inbuf inbytesleft:(size_t *)inbytesleft outbuf:(char **)outbuf outbytesleft:(size_t *)outbytesleft;

@end
