//
//  Block.h
//  PatternSequencer
//
//  Created by Sebastian Lederer on Sun Nov 02 2003.
//

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

#define MAX_PARTS 16

@interface Block : NSObject <NSCoding> {
    int partsCount;
    int length;
    NSString *name;
    int patternIndex[MAX_PARTS];
}

- init;
- (void) dealloc;
- initWithCoder: (NSCoder *) coder;
- (void) encodeWithCoder: (NSCoder *) coder;

- (int) length;
- (int) patternForPart: (int) anInt;
- (NSString *) name;

- setLength: (int) anInt;
- setPattern: (int) patternIndex forPart: (int) partIndex;
- setPartsCount: (int) anInt;
- setName: (NSString *) aStr;
- removePart: (int) partIndex;

@end
