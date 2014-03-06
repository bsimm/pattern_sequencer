/* Sequencer */
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

#include <CoreMIDI/MIDIServices.h>

#import <Cocoa/Cocoa.h>

#import "OutputChannel.h"
#import "Timestamp.h"
#import "Part.h"
#import "MidiPort.h"
#import "Block.h"

@interface Sequencer : NSObject  <NSCoding>
{
    // id sequencerController;
    NSTimer *timer;
    long int currentStep;
    long int realtimeStep;
    int realtimeResetCounter;
    BOOL isRunning;
    BOOL stepRecording;
    BOOL stopped;
    BOOL songMode;
    BOOL autoRewind;
    BOOL sendRealtime;
    BOOL externalClock;
    NSLock *lock;
    MidiPort *destPort;
    MidiPort *srcPort;
    Timestamp nextTick;
    Timestamp ticksPerStep;
    Timestamp ticksPerClock;
    int clocksPerStep;
    int stepsPerBeat;
    double stepTime;
    int tempo;
    
    NSMutableArray *parts;
    NSMutableArray *blocks;

    NSEnumerator *blocksEnumerator;
    int remainingBlockLength;
    int remainingBeatLength;
    
    Part *editPart;
    Part *deletedPart;
    
    Block *patternSwitch;
}

- init;
- (void) dealloc;

- initWithCoder: (NSCoder *) coder;
- (void)encodeWithCoder: (NSCoder *) coder;

- (long int) currentStep;
- (long int) realtimeStep;
- (BOOL) isRunning;
- (BOOL) isRecording;
- (BOOL) songMode;
- (BOOL) autoRewind;
- (BOOL) externalClock;
- (BOOL) sendRealtime;
- (int) stepsPerBeat;
- (int) tempo;
- (double) stepTime;
- (Timestamp) ticksPerStep;
- (Timestamp) currentTick;
- port;

- (NSArray *) parts;
- (NSArray *) blocks;
- (Block *) blockAtIndex: (int) anInt;
- partAtIndex: (int) anInt;

- setStepsPerBeat: (int) anInt;
- setTempo: (int) anInt;
- setPort: anId;
- setSongMode: (BOOL) aBool;
- setAutoRewind: (BOOL) aBool;
- setExternalClock: (BOOL) aBool;
- setSendRealtime: (BOOL) aBool;
- setStep: (long int) step;

- (Part *) newPart;
- deletePartAtIndex: (int) anInt;
- (BOOL) isValidPartName: (NSString *) n;
- undoDelete;

- (int) newBlock;
- removeBlock: (int)index;
- moveBlockFrom: (int) oldIndex to: (int) newIndex;
- switchToBlockAtIndex: (int) index;

- selectEditPartAtIndex: (int) index;
- start;
- startStepRecordingOnPart: (int) index;
- stop;

- (void) selectPatternsFromBlock: (Block *) block;


- (void) run: anId;
- (void) scheduleMIDIClock;
- (void) scheduleNextStep;
- (void) tick: anId;
- (void) rewind;
- (void) cleanup;
- (void) quietAllChannels;
- (void) portStarted;
- (void) portStopped;
- (void) setTiming;
- (void) nextBlock;

- (void) setPortOnAllParts;
- (void) test;
- (void) firstBlock;
- (void) nextBlock;
- (int) insertNotes: (NSArray *) notes atStep: (int) step length: (unsigned long int) length;

@end
