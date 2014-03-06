//
//  Pattern.h
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

#import "Part.h"

#define MAX_STEPS 128

@interface SeqPattern : NSObject <NSCoding> {
    Part *part;
    int  length;
    id steps[MAX_STEPS];
    id parameters[MAX_STEPS];
    NSString *name;
    NSLock *lock;
}

+ (void) initialize;

- init;
- (void) dealloc;

- initWithCoder: (NSCoder *) coder;
- (void)encodeWithCoder: (NSCoder *) coder;

- (SeqPattern *) duplicate;

- part;
- (NSString *) name;
- (int) length;

- setPart: (Part *) anId;
- setLength: (int) anInt;
- setName: (NSString *) anId;

- allocateSteps;
- deallocateSteps;

- setNote: aNote atStep: (unsigned long int) step
    multi: (BOOL) aBool;
- clearNote: aNote atStep: (unsigned long int) step;
- (NSArray *) notesAtStep: (unsigned long int) step;
- clearAllNotesAtStep: (unsigned long int) index;
- noteForKey: (int) key atStep: (int) index;
- setParameters: (id) p atStep: (unsigned long int) step;
- parametersAtStep: (unsigned long int) step;

- copyStepsFrom: (SeqPattern *) original;

- (void) print;
+ test;

@end
