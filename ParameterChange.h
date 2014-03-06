//
//  ParameterChange.h
//  PatternSequencer
//
//  Created by Sebastian Lederer on 09.09.04.
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


#import "OutputChannel.h"
#import "Timestamp.h"

#import <Foundation/NSObject.h>

@interface ParameterChange : NSObject <NSCoding> {
    int programNumber;
    int ccNumber;
    int ccValue;
    int ccNextValue;
    BOOL ccEnabled;
    BOOL programEnabled;
    BOOL smooth;
    BOOL pitchEnabled;
    int pitchStart;
    int pitchEnd;
    int spare;
    int spare1;
    id spare2;
    id spare3;
}

- init;
- initWithCoder: (NSCoder *) coder;
- initWith: (ParameterChange *) o;
- (void)encodeWithCoder: (NSCoder *) coder;

- (int) programNumber;
- (void) setProgramNumber:(int)newProgramNumber;
- (int) ccNumber;
- (void) setCcNumber:(int)newCcNumber;
- (int) ccValue;
- (void) setCcValue:(int)newCcValue;
- (void) setCcNextValue: (int) anInt;
- (int) ccNextValue;
- (void) setSmooth: (BOOL) aBool;
- (void) setPitchBend: (BOOL) aBool;
- (void) setPitchStart: (int) anInt;
- (void) setPitchEnd: (int) anInt;
- (int) pitchStart;
- (int) pitchEnd;
- (BOOL) pitchBend;
- (BOOL) smooth;

- (BOOL) ccEnabled;
- (BOOL) programEnabled;
- (BOOL) enabled;

- sendTo: (OutputChannel *) output at: (Timestamp) time interval: (Timestamp) ticks;
- (void) updateFlags;

@end
