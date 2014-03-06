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

#include <CoreAudio/CoreAudio.h>

#include "InputBuffer.h"
#import "Note.h"

@implementation InputBuffer
- init
{
    lock=[[ NSLock alloc ] init ];
    [ self clear ];
    return self;
}

- (void) dealloc
{
    [ lock release ];
    [ notes release ];
}

- (NSArray *) notes
{
    NSArray *returnedNotes;
    
    [ lock lock ];
    returnedNotes=[ NSArray arrayWithArray: notes ];
    [ lock unlock ];

    return returnedNotes;
}

- (int) countNotes
{
    int c;
    
    [ lock lock ];
    c=[ notes count ];
    [ lock unlock ];
    
    return c;
}

- (double) noteLength
{
    if(!finished) return 0;
    
    return (double)(endTime-startTime)/(double)AudioGetHostClockFrequency();
}

- (BOOL) finished
{
    return finished;
}

- clear
{
    if(notes) [ notes release ];
    notes=[[ NSMutableArray alloc ] init ];
    noteOnCounter=0;
    finished=NO;
    
    return self;
}

- (void) noteOnReceived: (int) key velocity: (int) vel at: (Timestamp) time
{    
    if(finished) return;

    [ self addNote: [ Note key: key duration: 1 velocity: vel ]];
    if(noteOnCounter==0) startTime=time;
    noteOnCounter++;
}

- (void) noteOffReceived: (int) key velocity: (int) vel at: (Timestamp) time
{
    if(finished) return;

    noteOnCounter--;
    if(noteOnCounter==0 && [ self countNotes ]>0)
    {
        endTime=time;
        [ self sendNotification ];
        finished=YES;
    }
}

- (void) sendNotification
{
    NSNotification *n=[ NSNotification notificationWithName: @"pseqExtInput" object: self ];
    
    [[ NSNotificationCenter defaultCenter ] performSelectorOnMainThread: @selector(postNotification:)
                                                       withObject: n
                                                    waitUntilDone: NO];
}

- (void) addNote: (Note *) newNote
{
    [ lock lock ];
    [ notes addObject: newNote ];
    [ lock unlock ];
}
@end