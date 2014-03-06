//
//  Part.h
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

#include "Timestamp.h"

@class Port;
@class Sequencer;
@class OutputChannel;
@class SeqPattern;

@interface Part : NSObject <NSCoding> {
    NSMutableArray 	*patterns;
    OutputChannel	*port;
    id			currentPattern;
    int 		currentPatternIndex;
    id                  editPattern;
    int                 editPatternIndex;
    int			patternLength;
    BOOL                mute;
    int                 spare1;
    int                 spare2;
    double              spare3;
    Sequencer		*sequencer;
    NSString		*name;
    
    SeqPattern 		*deletedPattern;
}

- init;
- (void) dealloc;

- initWithCoder: (NSCoder *) coder;
- (void)encodeWithCoder: (NSCoder *) coder;

- (int) newPattern;
- (int) addPattern: (SeqPattern *) new;
- removePatternAtIndex: (int) index;
- undoRemove;
- (int) duplicateEditPattern;

- (SeqPattern *) selectPattern: (int) index;
- (SeqPattern *) selectEditPattern: (int) index;
- (SeqPattern *) findPatternByName: (NSString *) name;

- (NSArray *) patterns;

- (int) countPatterns;
- (int) patternLength;
- (SeqPattern *) currentPattern;
- (SeqPattern *) editPattern;
- (int) editPatternIndex;
- (int) currentPatternIndex;
- outputChannel;
- sequencer;
- (NSString *) name;
- (BOOL) mute;


- setSequencer: anId;
- setName: (NSString *)anId;
- setOutputChannel: aPort;
- setPatternLength: (int) anInt;
- setMute: (BOOL) aBool;
- playStep: (unsigned long int) step at: (Timestamp) time;
- auditionStep: (unsigned long int) step duration: (float) duration;

@end
