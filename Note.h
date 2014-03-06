//
//  Note.h
//  PatternSequencer
//
//  Created by Sebastian Lederer on Thu Aug 14 2003.
/*
 Copyright (c) 2003-2010 Sebastian Lederer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <Foundation/Foundation.h>


@interface Note : NSObject <NSCoding> {
    int key;
    unsigned long int duration;
    int velocity;
    int release;
    double shuffle;
    
    int spare1;
    double spare2;
}

+ key: (int) k duration: (unsigned long int) d velocity: (int) v;
+ keyNumber: (int) k;
+ (NSString *) nameForKeyNumber: (int) k;

- initWithCoder: (NSCoder *) coder;
- (void)encodeWithCoder: (NSCoder *) coder;

- initWithKey: (int) k duration: (unsigned long int) d velocity: (int) v;

- (BOOL) equals: (Note *) aNote;

- (int) keyNumber;
- (NSString *) keyName;
- setKeyNumber: (int) anInt;
- (unsigned long int) duration;
- setDuration: (unsigned long int) anInt;
- (int) velocity;
- setVelocity: (int) anInt;
@end
