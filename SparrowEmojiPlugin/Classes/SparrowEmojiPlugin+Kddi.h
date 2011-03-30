//
//  SparrowEmojiPlugin+Au.h
//  SparrowEmojiPlugin
//
//  Created by SKAhack on 11/03/18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SparrowEmojiPlugin.h"

#import "iconv.h"


@interface SparrowEmojiPlugin (Kddi)

- (NSString *)replaceKddiEmoji:(NSString *)message;
- (int) convertKDDIISO2022JPToUTF8:(iconv_t)con inbuf:(char **)inbuf inbytesleft:(size_t *)inbytesleft outbuf:(char **)outbuf outbytesleft:(size_t *)outbytesleft;
@end
