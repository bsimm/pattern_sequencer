//
//  Port.h
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

@interface OutputChannel : NSObject <NSCoding> {
    id midiPort;
    int channel;
    int lastProgram;
    int lastBank;
    int lastVolume;
}

+ defaultChannel;

- init;
- (void) dealloc;

- initWithCoder: (NSCoder *) coder;
- (void)encodeWithCoder: (NSCoder *) coder;

- midiPort;
- (int) midiChannel;

- setMidiPort: anId;
- setMidiChannel: (int) anInt;
- changeProgram: (int) anInt;
- changeBank: (int) anInt;
- changeVolume: (int) anInt;
- quiet;

- (int) lastProgram;
- (int) lastBank;
- (int) lastVolume;

- note: (int) anInt at: (unsigned long int) time duration: (unsigned long int) d
    velocity: (int) vel;

- note: (int) n atTime: (Timestamp) time duration: (unsigned long int) d
    velocity: (int) vel;

- sendProgramChange: (int) anInt at: (Timestamp) time;
- sendController: (int) number value: (int) value at: (Timestamp) time;
- sendPitchBend: (int) value at: (Timestamp) time;

- (void) sendParameters;

@end
