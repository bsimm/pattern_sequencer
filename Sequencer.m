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

#import "Sequencer.h"

#include <CoreAudio/HostTime.h>

#include <time.h>
#include <sys/time.h>

#import "SeqPattern.h"
#import "Part.h"
#import "Note.h"
#import "PatternMatrix.h"
#import "Block.h"
#include "debug.h"

#define QUEUED_STEPS 1

@implementation Sequencer

- init
{
    NSNotificationCenter *nc;
    
    // create parts array
    parts=[[ NSMutableArray alloc ] initWithCapacity: 4 ];
    blocks=[[ NSMutableArray alloc ] initWithCapacity: 4 ];
    lock=[[ NSLock alloc ] init ];
    [ self newBlock ];
    // [ self newBlock ];
    stopped=YES;
    
    // set these to yes for testing
    sendRealtime=YES;    
    externalClock=YES;
    
    nc=[ NSNotificationCenter defaultCenter ];
    
    [ nc addObserver: self selector: @selector(inputReceived:)
                name: @"pseqExtInput"
              object: nil ];
    
    return self;
}

- (void) dealloc
{
    [ parts release ];
    [ blocks release ];
    [ deletedPart release ];
    [ lock release ];
    [ super dealloc ];
}

- initWithCoder: (NSCoder *) coder
{
    if(![super init]) return nil;

    // sequencerController is not encoded
    // timer is not encoded
    // currentStep is not encoded
    // isRunning is not encoded
    // destPort is not encoded
    // nextTick is not encoded
    [ coder decodeValueOfObjCType: @encode(int) at: &stepsPerBeat ];
    // stepTime is not encoded
    [ coder decodeValueOfObjCType: @encode(int) at: &tempo ];
    parts=[ coder decodeObject ];
    [ parts retain ];
    blocks=[ coder decodeObject ];
    [ blocks retain ];

    [ self setTiming ];
    
    stopped=YES;

    dbgprintf("Sequencer unarchived timer %p destPort %p\n", timer, destPort);
    
    return self;
}

- (void)encodeWithCoder: (NSCoder *) coder
{    
    // sequencerController is not encoded
    // timer is not encoded
    // currentStep is not encoded
    // isRunning is not encoded
    // stopped is not encoded
    // destPort is not encoded
    // nextTick is not encoded
    [ coder encodeValueOfObjCType: @encode(int) at: &stepsPerBeat ];
    // stepTime is not encoded
    [ coder encodeValueOfObjCType: @encode(int) at: &tempo ];
    [ coder encodeObject: parts ];
    [ coder encodeObject: blocks ];
}

- (long int) currentStep
{
    return currentStep;
}

- (long int) realtimeStep
{
    return realtimeStep;
}

- (int) stepsPerBeat
{
    return stepsPerBeat;
}

- (int) tempo
{
    return tempo;
}

- (Timestamp) ticksPerStep
{
    return clocksPerStep;
}

- (BOOL) songMode
{
    return songMode;
}

- (BOOL) autoRewind
{
    return autoRewind;
}

- (BOOL) externalClock
{
    return externalClock;
}

- (BOOL) sendRealtime
{
    return sendRealtime;
}

- (double) stepTime
{
    return stepTime;
}

- port
{
    return destPort;
}

- (NSArray *) parts
{
    return [ NSArray arrayWithArray: parts ];
}

- (NSArray *) blocks
{
    return blocks;
}

- partAtIndex: (int) anInt
{
    dbgprintf("parts class: %s\n", [[[parts class ] description ] cString ]);
    dbgprintf("parts count: %d\n", [ parts count ]);
    return [ parts objectAtIndex: anInt ];
}
- setStepsPerBeat: (int) anInt
{
    stepsPerBeat=anInt;
    if(tempo) [ self setTiming ];
    return self;
}

- setTempo: (int) anInt
{
    tempo=anInt;
    if(stepsPerBeat) [ self setTiming ];
    return self;
}

- setExternalClock: (BOOL) aBool
{
    externalClock=aBool;
    
    return self;
}


- setSongMode: (BOOL) aBool
{
    // cannot change songMode while playing

    if(isRunning) return nil;

    songMode=aBool;
    
    return self;
}

- setAutoRewind: (BOOL) aBool
{
    autoRewind=aBool;
    return self;
}

- setSendRealtime: (BOOL) aBool
{
    sendRealtime=aBool;
    return self;
}

- setStep: (long int) step
{
    if(isRunning && !stepRecording) return nil;

    realtimeStep=step;
    currentStep=step;
    return self;
}

- setPort: anId
{
    id inputBuffer;

    [ anId retain ];
    [ destPort release ];
    destPort=anId;
    [ destPort setSequencer: self ];
    
    inputBuffer=[[ InputBuffer alloc ] init ];
    [ destPort setInputBuffer: inputBuffer ];
    [ inputBuffer release ];
    
    [ self setPortOnAllParts ];
    return self;
}

- (void) setPortOnAllParts
{
    id o,e;
    
    e=[ parts objectEnumerator ];
    while(o=[ e nextObject ])
    {
            [[ o outputChannel ] setMidiPort: destPort ];
    }
}

- (Part *) findPartByName: (NSString *) n
{
    id e;
   Part *p;
    
    e=[ parts objectEnumerator ];
    
    while(p=[ e nextObject ])
    {
        if([[ p name ] isEqualToString: n ]==YES)
            return p;
    }
    return nil;
}

- (BOOL) isValidPartName: (NSString *) n
{
    id e;
    Part *p;
    
    if(!n || [ n length ]==0 ) return NO;

    e=[ parts objectEnumerator ];
    
    while(p=[ e nextObject ])
    {
        if([[ p name ] isEqual: n ]==YES)
            return NO;
    }
    return YES;
}

- (Block *) blockAtIndex: (int) anInt
{
    return [ blocks objectAtIndex: anInt ];
}

- (int) newBlock
{
    Block *newBlock;

    newBlock=[[ Block alloc ] init ];
    [ newBlock setPartsCount: [ parts count ]];
    [ blocks addObject: newBlock ];
    [ newBlock release ];
    return [ blocks count ] - 1;
}

- updateBlocks
{
    Block *b;
    int partsCount=[ parts count ];
    id e=[ blocks objectEnumerator ];
    
    while(b=[ e nextObject ]) [ b setPartsCount: partsCount ];
    
    return self;
}

- removeBlock: (int)index
{
    [ blocks removeObjectAtIndex: index ];
    return self;
}

- moveBlockFrom: (int) oldIndex to: (int) newIndex
{    
    [ blocks exchangeObjectAtIndex: oldIndex withObjectAtIndex: newIndex ];
    return self;
}

- (Part *) newPart
{
    Part *part;
    NSString *name;
    OutputChannel *channel;
    static int num=1;

    do
    {
        name=[ NSString stringWithFormat: @"Part %d", num++ ];
    }
    while(![ self isValidPartName: name ]);

    channel=[[ OutputChannel alloc ] init ];
    [ channel setMidiPort: destPort ];
    [ channel setMidiChannel: 1 ];

    part=[ [ Part alloc ] init ];
    [ part setSequencer: self ];
    [ part setName: name ];
    [ part setOutputChannel: channel ];
    [ parts addObject: part ];
    [ part release ];
    [ channel release ];
    
    [ self updateBlocks ];

    return part;
}

- deletePartAtIndex: (int) anInt
{
    id e;
    Block *b;
    int partsCount;
    
    [ deletedPart release ];
    deletedPart=[ parts objectAtIndex: anInt ];
    [ deletedPart retain ];
    [ parts removeObjectAtIndex: anInt ];
    
    partsCount=[ parts count ];
    
    e=[ blocks objectEnumerator ];
    while(b=[e nextObject])
    {
        [ b removePart: anInt ];
        [ b setPartsCount: partsCount ];
    }
    dbgprintf("setting partsCount %d on blocks\n",partsCount);
    return self;
}

- undoDelete
{
    return self;
}

- (int) insertNotes: (NSArray *) notes atStep: (int) step length: (unsigned long int) length
{
    id allObjects;
    Note *newNote,*object;
    NSArray *stepNotes;
    int i;
    SeqPattern *pattern=[ editPart editPattern ];

    [ pattern clearAllNotesAtStep: step ];

    // shorten all preceding notes which extend over the current step
    for(i=0;i<step;i++)
    {
        stepNotes=[ pattern notesAtStep: i ];
        allObjects=[ stepNotes objectEnumerator ];
        while(object=[ allObjects nextObject ])
        {
            if([ object duration ]+i > step)
            {
                newNote=[ Note key: [ object keyNumber ]
                          duration: step-i
                          velocity: [ object velocity ]];
                [ pattern setNote: newNote atStep: i multi: YES ];
            }
        }
    }

    // trim the length down to the beginning of the next note
    if(length>1)
    {
        for(i=1;i<length && (step+i)<MAX_STEPS;i++)
        {
            stepNotes=[ pattern notesAtStep: step+i ];
            if([ stepNotes count ]!=0)
            {
                length=i;
                break;
            }
        }
    }

    allObjects=[ notes objectEnumerator ];    
    while(object=[ allObjects nextObject ])
    {
        newNote=[ Note key: [ object keyNumber ]
                  duration: length
                  velocity: [ object velocity ]];
        [ pattern setNote: newNote atStep: step multi: YES ];
    }
    return length;
}

- (void) inputReceived: (NSNotification *) notification
{
    InputBuffer *inputBuffer=[ notification object ];
    NSArray *notes=[ inputBuffer notes ];
    double noteLength=[ inputBuffer noteLength ];
    int length=1;
    int boundary;

    if(!stepRecording) return;
    
    [ notes count ];
        
    // printf("inputReceived %d notes length %.2f sec\n", [ notes count ], [ inputBuffer noteLength ]);

    [ inputBuffer clear ];
    
    if(noteLength>1.3) length=16;
    boundary=(realtimeStep | 31);
    if(realtimeStep+length > boundary) length=boundary-realtimeStep+1;
    length=[ self insertNotes: notes atStep: realtimeStep length: length ];
    realtimeStep=(realtimeStep+length) % [ editPart patternLength ];

    [[ NSNotificationCenter defaultCenter ] postNotificationName: @"pseqEdited"
                                                              object: self ];
}

- (void) setTiming
{
    float stepsPerSecond;
    float beatsPerSecond;
    Timestamp ticksPerSecond;
    
    // calculate length of a step in ticks
    
    beatsPerSecond=tempo/60.0;
    stepsPerSecond=(tempo*(float)stepsPerBeat/60.0);
    
    // convert one milliard nanoseconds = one second to ticks
   // ticksPerSecond=AudioConvertNanosToHostTime(1E9);

    ticksPerSecond=AudioGetHostClockFrequency();

    ticksPerStep=ticksPerSecond/stepsPerSecond;
    
    stepTime=1.0/stepsPerSecond;

    clocksPerStep=24/stepsPerBeat;
    ticksPerClock=ticksPerSecond/(24*beatsPerSecond);
    
    dbgprintf("ticksPerSecond: %lld\n", ticksPerSecond);
    dbgprintf("stepsPerSecond: %f\n",stepsPerSecond);
    dbgprintf("ticksPerStep: %ld\n", (long int) ticksPerStep);
    dbgprintf("ticksPerClock: %ld\n", (long int) ticksPerClock);
    dbgprintf("stepTime: %lf\n", stepTime);
}

- (void) cleanup
{    
    if(!externalClock) [ destPort realtimeControl: RealtimeStop ];

    [ destPort setSendClocks: NO ];
    [ destPort setExternalClock: NO ];

    [ self quietAllChannels ];
}

- (void) quietAllChannels
{
    id o,e;
    
    e=[ parts objectEnumerator ];
    while(o=[ e nextObject ]) [[ o outputChannel ] quiet ];
}

- (void) scheduleMIDIClock
{
    [ destPort sendMIDIClocks: clocksPerStep at: nextTick+ticksPerClock tickLength: ticksPerClock ];
}

- (void) scheduleNextStep
{
    MIDITimeStamp t;
    Part *part;
    int i,c;

    t=1;
        
    // go through all parts
    c=[ parts count ];    
    for(i=0;i<c;i++)
    {
        part=[ parts objectAtIndex: i ];
        [ part playStep: currentStep at: t ];
    }
    
    currentStep = (currentStep + 1) & 127;

    if(currentStep==0) realtimeResetCounter=QUEUED_STEPS;

    // check for manually scheduled pattern switch
    if(patternSwitch)
    {
        if((currentStep & 15)==0)
        {
            [ self selectPatternsFromBlock: patternSwitch ];
            currentStep=0;
            realtimeResetCounter=QUEUED_STEPS;
            [ patternSwitch release ];
            patternSwitch=nil;
        }
    }

    if(!songMode) return;

    remainingBeatLength--;
    if(remainingBeatLength==0)
    {
        remainingBeatLength=stepsPerBeat;
        
        remainingBlockLength--;
        if(remainingBlockLength==0)
        {
            [ self nextBlock ];
        }
    }

}

- (void) tick: anId;
{
    [ self scheduleNextStep ];

    realtimeStep = (realtimeStep+1);
    realtimeResetCounter--;
    if(realtimeResetCounter==0) realtimeStep=0;
}

- (Timestamp) currentTick
{
        return AudioGetCurrentHostTime();
}

- start
{
    [ lock lock ];
    if(isRunning)
    {
        [ lock unlock ];
        return nil;
    }
    isRunning=YES;
    [ lock unlock ];

    // start new thread

    [NSThread detachNewThreadSelector:@selector(run:)
                toTarget: self withObject:nil];
    
    return self;
}

- selectEditPartAtIndex: (int) index
{
    editPart=[ parts objectAtIndex: index ];
    return self;
}

- startStepRecordingOnPart: (int) index
{
    InputBuffer *inputBuffer=[ destPort inputBuffer ];
    if(isRunning) return nil;
    
    editPart=[ parts objectAtIndex: index ];

    isRunning=YES;
    stepRecording=YES;
    [ inputBuffer clear ];
    [ destPort setMIDIThru: YES ];
    // printf("startStepRecordingOnPart: %d\n",index);
    return self;
}

- stop
{
    if(!isRunning) return nil;

    // stopped from step record mode
    if(stepRecording)
    {
        stepRecording=NO;
        [ destPort setMIDIThru: NO ];
    }
    // stopped from play mode
    else
    {
        
        if(externalClock) [ self cleanup ];
    }
    
    isRunning=NO;
    return self;
}

- (void) portStarted
{
    if(!isRunning) return;

    if(!externalClock) return;

    [ self rewind ];
    [ self scheduleNextStep ];

}

- (void) portStopped
{
    if(!isRunning) return;
    
    if(!externalClock) return;
    
    [ self quietAllChannels ];
}

- (void) rewind
{
    if(songMode)
    {
        [ self firstBlock ];
    }
    
    remainingBeatLength=stepsPerBeat;
    realtimeStep=0;
    realtimeResetCounter=-1;
    currentStep=realtimeStep;
}

- (void) run: anId
{
    NSAutoreleasePool *pool;
    struct timeval now,next;
    long int uSecPerClock,jitter_usec,jitter_sec;
    long int nSecPerClock,correction;
    int i=0;

    // int songPosition;
    struct timespec requested,remaining;

    dbgprintf("thread start\n");
    dbgprintf("external clock: %d send realtime: %d\n",
        (int) externalClock, (int) sendRealtime);
    [ lock lock ];
    
    [ NSThread setThreadPriority: 0.75 ];

    pool = [[NSAutoreleasePool alloc] init];

    if(autoRewind || songMode) [ self rewind ];

    stopped=NO;
    
    [ destPort setSendClocks: sendRealtime ];
    [ destPort setExternalClock: externalClock ];

    if(!externalClock)
    {
        if(songMode || realtimeStep==0)
            [ destPort realtimeControl: RealtimeStart ];
        else
        {
            // songPosition=realtimeStep*clocksPerStep/6;
            // [ destPort sendSongPosition: songPosition at: now ];
            [ destPort realtimeControl: RealtimeContinue ];
        }
    }

    if(!externalClock)
    {
        uSecPerClock=(60*1E6)/(tempo*24);
        nSecPerClock=uSecPerClock*1000L;
        correction=0;
        
        dbgprintf("stepTime: %f uSecPerClock: %ld nSecPerClock: %ld\n",stepTime,uSecPerClock,nSecPerClock);

        if(realtimeStep==0) [ self scheduleNextStep ];

        gettimeofday(&next,NULL);
    
        while(isRunning)
        {
        
            next.tv_usec += uSecPerClock;
            if(next.tv_usec >= 1E6)
            {
                next.tv_sec++;
                next.tv_usec -= 1E6;
            }

            [ destPort clockTick ];
            
            requested.tv_sec=0;
            requested.tv_nsec=nSecPerClock+correction;
            if(requested.tv_nsec>=1E9)
            {
                requested.tv_sec++;
                requested.tv_nsec-=1E9;
            }
            
            if(requested.tv_nsec<0)
            {
                correction=requested.tv_nsec;
                requested.tv_nsec=0;
            }
            else
            {
                correction=0;
            }

            if(nanosleep(&requested,&remaining)!=0)
            {
                perror("nanosleep");
                printf("requested.tv_sec=%d\nrequested.tv_nsec=%ld\n", (int) requested.tv_sec, requested.tv_nsec);
            }
            

            gettimeofday(&now,NULL);

            jitter_usec=now.tv_usec-next.tv_usec;
            jitter_sec=now.tv_sec-next.tv_sec;
            if(jitter_usec<0)
            {
                jitter_sec--;
                jitter_usec += 1E6;
            }
            
            if(jitter_usec) correction -= jitter_usec * 1000;
            
            if(jitter_sec) correction -= jitter_sec *1E9;
            
            i=(i+1)&15;
            if(i==0)
            {
                [ pool release];    
                pool=[[ NSAutoreleasePool alloc ] init ];
            }
            
            next=now;
        }
        
        [ self cleanup ];
        stopped=YES;
    }


    [ lock unlock ];
    dbgprintf("thread end\n");      
}

- (BOOL) isRunning
{
    return isRunning;
}

- (BOOL) isRecording
{
    return stepRecording;
}

- (void) firstBlock
{
    [ blocksEnumerator release ];
    blocksEnumerator=[ blocks objectEnumerator ];
    [ blocksEnumerator retain ];
    [ self nextBlock ];
}

- (void) selectPatternsFromBlock: (Block *) block
{
    id allObjects=[ parts objectEnumerator ];
    int partIndex=0;
    Part *part;
    
    while( (part=[ allObjects nextObject ])!=nil)
    {
        [ part selectPattern: [ block patternForPart: partIndex ]];
        partIndex++;
    }
}

- switchToBlockAtIndex: (int) index
{
    id newBlock;
    
    if(songMode) return self;

    if(index>=[ blocks count]) return nil;

    newBlock=[ blocks objectAtIndex: index ];
    [ newBlock retain ];
    [ patternSwitch release ];
    patternSwitch=newBlock;
    return self;
}

- (void) nextBlock
{
    Block *block;
        
    block=[ blocksEnumerator nextObject ];
    if(block==nil)
    {
        [ blocksEnumerator release ];
        blocksEnumerator=[ blocks objectEnumerator ];
        [ blocksEnumerator retain ];

        block=[ blocksEnumerator nextObject ];
    }
    
    remainingBlockLength=[ block length ];

    [ self selectPatternsFromBlock: block ];

//    e=[ parts objectEnumerator ];
//    partIndex=0;
//    
//    while( (part=[ e nextObject ])!=nil )
//    {
//        patternIndex=[ block patternForPart: partIndex ];
//
//        dbgprintf("nextBlock: set pattern %d for part %d\n", patternIndex, partIndex);
//        
//        [ part selectPattern: patternIndex ];
//        
//        partIndex++;
//    }
    
    currentStep=0;
    realtimeResetCounter=QUEUED_STEPS;
}

- (void) test
{
    id part;
    id pattern;
    int i;
    id a,e,n;

    part=[ parts lastObject ];
    pattern=[ part currentPattern ];
    
    for(i=0;i<10;i++)
    {
        a=[ pattern notesAtStep: i ];
        
        e=[ a objectEnumerator ];
        
        dbgprintf("step %d count: %d\n", i, [ a count ]);
        while(n=[ e nextObject ])
        {
            dbgprintf("step %d keyNumber %d\n",i, [n keyNumber]);
        }
    }
}

@end
