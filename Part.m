//
//  Part.m
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


#import "Part.h"
#import "SeqPattern.h"
#import "Note.h"
#import "Sequencer.h"
#import "OutputChannel.h"
#import "ParameterChange.h"
#include "debug.h"

@implementation Part

- init
{
    patterns=[[ NSMutableArray alloc ] initWithCapacity: 4 ];
    patternLength=32;
    return self;
}

- (void) dealloc
{
    [ patterns release ];
    [ name release ];
    [ port release ];
    [ super dealloc ];
}

- initWithCoder: (NSCoder *) coder
{
    if(![super init]) return nil;
    
    patterns=[ coder decodeObject ];
    port=[ coder decodeObject ];
    [ coder decodeValueOfObjCType: @encode(int) at: &currentPatternIndex ];
    [ coder decodeValueOfObjCType: @encode(int) at: &editPatternIndex ];
    [ coder decodeValueOfObjCType: @encode(int) at: &patternLength ];
    [ coder decodeValueOfObjCType: @encode(BOOL) at: &mute ];
    [ coder decodeValueOfObjCType: @encode(int) at: &spare1 ];
    [ coder decodeValueOfObjCType: @encode(int) at: &spare2 ];
    [ coder decodeValueOfObjCType: @encode(double) at: &spare3 ];

    sequencer=[ coder decodeObject ];
    name=[ coder decodeObject ];
    
    [ patterns retain ];
    [ port retain ];
    [ name retain ];

    currentPattern=[ patterns objectAtIndex: currentPatternIndex ];
    editPattern=[ patterns objectAtIndex: editPatternIndex ];
    dbgprintf("Part unarchived: %s patternLength %d\n", [ name cString ],patternLength);
    
    return self;
}

- (void)encodeWithCoder: (NSCoder *) coder
{
    // outputChannel is not encoded
    [ coder encodeObject: patterns ];
    [ coder encodeObject: port ];
    [ coder encodeValueOfObjCType: @encode(int) at: &currentPatternIndex ];
    [ coder encodeValueOfObjCType: @encode(int) at: &editPatternIndex ];
    [ coder encodeValueOfObjCType: @encode(int) at: &patternLength ];
    [ coder encodeValueOfObjCType: @encode(BOOL) at: &mute ];
    [ coder encodeValueOfObjCType: @encode(int) at: &spare1 ];
    [ coder encodeValueOfObjCType: @encode(int) at: &spare2 ];
    [ coder encodeValueOfObjCType: @encode(double) at: &spare3 ];

    [ coder encodeConditionalObject: sequencer ];
    [ coder encodeObject: name ];
    
    dbgprintf("saved pattern length %d\n",patternLength);
}


- (SeqPattern *) findPatternByName: (NSString *) n
{
    id e;
    SeqPattern *p;
    
    e=[ patterns objectEnumerator ];
    
    while(p=[ e nextObject ])
    {
        if([[ p name ] isEqualToString: n ]==YES)
            return p;
    }
    return nil;
}

- (NSString *) uniquePatternName
{
    NSString *n;
    int num=1;
    do
    {
        n=[ NSString stringWithFormat: @"Pattern %d", num++ ];
        if(num>16) return nil;
    }
    while([ self findPatternByName: n ]!=nil);
    
    return n;
}

- (int) addPattern: (SeqPattern *) new
{
    NSString *n;
    
    n=[ self uniquePatternName ];
    if(n==nil) return -1;

    [ new setName: n ];
    [ new setPart: self ];
    [ patterns addObject: new ];
    if(!currentPattern) currentPattern=new;
    if(!editPattern) editPattern=new;
    return [ patterns count ]-1;

}

- (int) newPattern
{
    int r;
    SeqPattern *new;
    
    new=[[ SeqPattern alloc ] init ];
    r=[ self addPattern: new ];
    [ new release ];
    return r;
}

- (int) duplicateEditPattern
{
    int r;
    SeqPattern *p;
    
    p=[ editPattern duplicate ];
    r=[ self addPattern: p ];
    [ p release ];
    return r;
}

- removePatternAtIndex: (int) index
{
    [ deletedPattern release ];
    deletedPattern=[ patterns objectAtIndex: index ];
    [ deletedPattern retain ];

    [ patterns removeObjectAtIndex: index ];
    return self;
}

- undoRemove
{
    return self;
}

- (SeqPattern *) selectPattern: (int) index
{
    currentPattern=[ patterns objectAtIndex: index ];
    currentPatternIndex=index;
    return currentPattern;
}

- (SeqPattern *) selectEditPattern: (int) index
{
    editPattern=[ patterns objectAtIndex: index ];
    editPatternIndex=index;
    return editPattern;    
}

- setPatternLength: (int) anInt
{
    patternLength=anInt;
    return self;
}

- (SeqPattern *) currentPattern
{
    return currentPattern;
}

- (int) currentPatternIndex
{
    return currentPatternIndex;
}

- (SeqPattern *) editPattern
{
    return editPattern;
}

- (int) editPatternIndex
{
    return editPatternIndex;
}

- (int) patternLength
{
    return patternLength;
}

- (BOOL) mute
{
    return mute;
}

- (NSArray *) patterns
{
    return [ NSArray arrayWithArray: patterns ];
}

- (int) countPatterns
{
    if(!patterns) return 0;
    
    return [ patterns count ];
}

- setSequencer: anId
{
    sequencer=anId;
    return self;
}

- setOutputChannel: aPort
{
    [ aPort retain ];
    [ port release ];
    port=aPort;
    return self;
}

- setName: (NSString *)anId
{
    [ anId retain ];
    [ name release ];
    name=anId;
    return self;
}

- setMute: (BOOL) aBool
{
    mute=aBool;
    return self;
}

- outputChannel
{
    return port;
}

- (NSString *) name
{
    return name;
}

- sequencer
{
    return sequencer;
}

- playStep: (unsigned long int) step at: (Timestamp) time
{
    id notes;
    id n;
    id e;
    ParameterChange *parameterChange;

    unsigned long int d;
    unsigned long int mask;
    Timestamp ticksPerStep;

    if(mute) return self;

    mask=patternLength-1;
    step=step & mask;

    ticksPerStep=[ sequencer ticksPerStep ];
    notes=[ currentPattern notesAtStep: step ];
    parameterChange=[ currentPattern parametersAtStep: step ];

    [ parameterChange sendTo: port at: time interval: ticksPerStep ];

    e=[ notes objectEnumerator ];
    while( n=[ e nextObject ] )
    {
        d=[ n duration ];
        if(d==0)
            d=ticksPerStep/2;
        else
            d=ticksPerStep*d;
        
       // dbgprintf("tps %llu duration %lu ticks %lu\n",
       //     ticksPerStep, [ n duration ],d);
        
        [ port note: [ n keyNumber ] at: time
            duration: d velocity: [ n velocity ] ];
    }
    return self;
}

- auditionStep: (unsigned long int) step duration: (float) duration
{
    id notes;
    id n;
    id e;
    unsigned long int mask;

    mask=128-1;
    step=step & mask;

    notes=[ currentPattern notesAtStep: step ];

    e=[ notes objectEnumerator ];
    while( n=[ e nextObject ] )
    {
        
        [ port note: [ n keyNumber ] atTime: [ sequencer currentTick ]
            duration: duration*1E7 velocity: [ n velocity ] ];
    }
    return self;
}

@end
