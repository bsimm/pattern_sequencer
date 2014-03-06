//
//  Port.m
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


#import "OutputChannel.h"

#import "MidiPort.h"

@implementation OutputChannel

+ defaultChannel
{
    id newChannel;
    
    newChannel=[[ self alloc ] init ];
    [ newChannel setMidiPort: [ MidiPort defaultPort ]];
    [ newChannel autorelease ];
    return newChannel;
}

- init
{
    lastProgram=1;
    lastBank=0;
    lastVolume=100;
    return self;
}

- (void) dealloc
{
    [ midiPort release ];
    [ super dealloc ];
}

- initWithCoder: (NSCoder *) coder
{
    if(![ super init ]) return nil;

    [ coder decodeValueOfObjCType: @encode(int) at: &channel ];
    [ coder decodeValueOfObjCType: @encode(int) at: &lastProgram ];
    [ coder decodeValueOfObjCType: @encode(int) at: &lastBank ];
    [ coder decodeValueOfObjCType: @encode(int) at: &lastVolume ];
    return self;
}

- (void)encodeWithCoder: (NSCoder *) coder
{
    // midiPort is not encoded
    
    [ coder encodeValueOfObjCType: @encode(int) at: &channel ];
    [ coder encodeValueOfObjCType: @encode(int) at: &lastProgram ];
    [ coder encodeValueOfObjCType: @encode(int) at: &lastBank ];
    [ coder encodeValueOfObjCType: @encode(int) at: &lastVolume ];
}

- midiPort
{
    return midiPort;
}

- (int) midiChannel
{
    return channel;
}

- (int) lastProgram;
{
    return lastProgram;
}

- (int) lastBank
{
    return lastBank;
}

- (int) lastVolume
{
    return lastVolume;
}

- setMidiPort: (MidiPort *) anId
{
    [ anId retain ];
    [ midiPort release ];
    midiPort=anId;
    [ self sendParameters ];
    return self;
}

- setMidiChannel: (int) anInt
{
    channel=anInt;
    return self;
}

- sendProgramChange: (int) anInt at: (Timestamp) time
{
    if(anInt<1 || anInt>128) return nil;

    [ midiPort selectProgram: anInt-1 on: channel at: time ];
    
    return self;
}

- sendController: (int) number value: (int) value at: (Timestamp) time
{
    if(number<0 || number >127 || value<0 || value>127) return nil;
    
    [ midiPort sendController: number value: value on: channel at: time ];
    
    return self;
}

- sendPitchBend: (int) value at: (Timestamp) time
{
    if(value<0 || value>16383) return nil;
    
    [ midiPort sendPitchBend: value on: channel at: time ];

    return self;
}

- changeProgram: (int) anInt
{
    if(anInt<1 || anInt>128) return nil;

    [ midiPort selectProgram: anInt-1 on: channel at: TIMESTAMP_NOW ];
    
    lastProgram=anInt;
    return self;
}

- changeBank: (int) anInt
{
    if(anInt<0 || anInt>127) return nil;
    
    [ midiPort selectBank: anInt on: channel ];
    [ self changeProgram: lastProgram ];

    lastBank=anInt;
    return self;
}

- changeVolume: (int) anInt
{
    [ midiPort changeVolume: anInt on: channel ];
    lastVolume=anInt;
    return self;
}

- note: (int) n at: (unsigned long int) clock duration: (unsigned long int) d
    velocity: (int) vel
{
    [ midiPort note: n at: clock duration: d velocity: vel on: channel ];
    return self;
}

- note: (int) n atTime: (Timestamp) time duration: (unsigned long int) d
    velocity: (int) vel
{
    [ midiPort note: n atTime: time duration: d velocity: vel on: channel ];
    return self;
}

- (void) sendParameters
{
    [ self changeVolume: lastVolume ];
    [ self changeBank: lastBank ];
    // changeProgram is unnecessary since changeBank must also
    // send a program change to take effect
    // [ self changeProgram: lastProgram ];
}

- quiet
{
    [ midiPort flush ];
    [ midiPort allNotesOffOnChannel: channel ];
    return self;
}

@end
