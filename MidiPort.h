//
//  MidiPort.h
//  PatternSequencer
//
//  Created by Sebastian Lederer on Tue Aug 12 2003.
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

@class MidiPort;

#import "InputBuffer.h"
#import "Sequencer.h"

#include <CoreMIDI/MIDIServices.h>

#import <Foundation/Foundation.h>


#define QUEUE_SIZE 1024
#define NUMBER_OF_QUEUES 64

struct MIDIPacketQueue
{
    int clock;
    MIDIPacketList *packetList;
    MIDIPacket *packet;
};

typedef enum { RealtimeStart, RealtimeStop, RealtimeContinue } realtime_t;

@interface MidiPort : NSObject {
    MIDIPortRef		outPort;
    MIDIPortRef         inPort;
    MIDIEndpointRef	dest,src;
    struct MIDIPacketQueue queues[NUMBER_OF_QUEUES];
    int nextQueueSlot;
    int activeQueues;
    Sequencer *sequencer;
    InputBuffer *inputBuffer;
    int clocksPerStep;
    int currentClock;
    BOOL started;
    NSLock *lock;
    BOOL externalClock;
    BOOL sendClocks;
    BOOL midiThru;
}

+ defaultPort;
+ (NSArray *) availablePorts;
+ (NSArray *) availableInputPorts;

+ port: (int) index;
+ inputPort: (int) index;

- openPort: (int) index;
- openInputPort: (int) index;
- closeInputPort;

- (void) dealloc;

- setSequencer: (Sequencer *) s;
- setInputBuffer: (InputBuffer *) newInputBuffer;
- setExternalClock: (BOOL) aBool;
- setSendClocks: (BOOL) aBool;
- setMIDIThru: (BOOL) aBool;

- (Sequencer *) sequencer;
- (InputBuffer *) inputBuffer;

- note: (int) anInt at: (unsigned long int) clock duration: (unsigned long int) length
    velocity: (int) vel on: (int) channel;

- note: (int) anInt atTime: (MIDITimeStamp) time duration: (unsigned long int) length
    velocity: (int) vel on: (int) channel;

- selectProgram: (int) prog on: (int) channel at: (MIDITimeStamp) time;
- selectBank: (int) bank on: (int) channel;
- changeVolume: (int) volume on: (int) channel;
- allNotesOffOnChannel: (int) channel;
- clockTick;
- (void) realtimeReceived: (realtime_t) msg;
- (void) packetReceived: (MIDIPacket *) packet;
- realtimeControl: (realtime_t) msg;
- sendPitchBend: (int) value on: (int) channel at: (MIDITimeStamp) time;
- sendController: (int) cc value: (int) value on: (int) channel at: (MIDITimeStamp) time;
- sendMIDIClocks: (int) amount at: (MIDITimeStamp) time tickLength: (unsigned long int) length;
- sendRealtimeStartAt: (MIDITimeStamp) time;
- sendRealtimeStopAt: (MIDITimeStamp) time;
- sendRealtimeContinueAt: (MIDITimeStamp) time;
- sendSongPosition: (int) position at: (MIDITimeStamp) time;
- queueMIDIEvent: (Byte *) bytes size: (int) sz at: (MIDITimeStamp) time;
- queueEvent: (Byte*) event size: (int) size atClock: (int) clock;
- flush;

- (void) flushQueues;
@end
