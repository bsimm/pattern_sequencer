//
//  Pattern.m
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


#import "SeqPattern.h"
#import "Note.h"
#import "ParameterChange.h"

#include "debug.h"

@implementation SeqPattern

+ (void) initialize
{
    [ self setVersion: 1 ];
}

- init
{
    [ self allocateSteps ];
    lock=[[ NSLock alloc ] init ];
    return self;
}

- (void) dealloc
{
    [ self deallocateSteps ];
    [ lock release ];
    [ name release ];
    [ super dealloc ];
}

- deallocateSteps
{
    int i;
    for(i=0;i<MAX_STEPS;i++)
    {
        [ steps[i] release ];
        [ parameters[i] release ];
    }
    return self;
}

- initWithCoder: (NSCoder *) coder
{
    int i;
    int version=[ coder versionForClassName: @"SeqPattern" ];
    
    if(![ super init ]) return nil;

    dbgprintf("SeqPattern version %d\n",version);

    lock=[[ NSLock alloc ] init ];
    
    part=[ coder decodeObject ];
    [ coder decodeValueOfObjCType: @encode(int) at: &length ];
    for(i=0;i<MAX_STEPS;i++)
    {
        steps[i]=[ coder decodeObject ];
        [ steps[i] retain ];
        if(version>=1)
        {
            parameters[i]=[ coder decodeObject ];
            [ parameters[i] retain ];
        }
    }
    name=[ coder decodeObject ];
    [ name retain ];
    dbgprintf("SeqPattern unarchived: %s length %d\n", [ name cString ],length);
    return self;    
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    int i;
    
    [ coder encodeConditionalObject: part ];
    [ coder encodeValueOfObjCType: @encode(int) at: &length ];
    for(i=0;i<MAX_STEPS;i++)
    {
        [ coder encodeObject: steps[i] ];
        [ coder encodeObject: parameters[i]];
    }
    [ coder encodeObject: name ];
}

- (SeqPattern *) duplicate
{
    SeqPattern *new=[[ isa alloc ] init ];
    
    [ new copyStepsFrom: self ];
    [ new setPart: part ];
    [ new setLength: length ];

    return new;
}

- copyStepsFrom: (SeqPattern *) original
{
    NSMutableArray *a;
    int i;
    
    for(i=0;i<MAX_STEPS;i++)
    {
            a=[ NSMutableArray arrayWithArray: [ original notesAtStep: i ]];
            steps[i]=a;
            [ steps[i] retain ];
            
            parameters[i]=[ original parametersAtStep: i ];
            [ parameters[i] retain ];
    }
    
    return self;
}

- part
{
    return part;
}

- setPart: (Part *) anId
{
    part=anId;
    return self;
}

- setName: (NSString *)anId
{
    [ anId retain ];
    if(name) [ name release ];
    name=anId;
    return self;
}

- (NSString *) name
{
    return name;
}

- (int) length
{
    return length;
}

- setLength: (int) anInt
{
    length=anInt;
    return self;
}

- allocateSteps
{
    int i;
    NSMutableArray *notes;
    
    for(i=0;i<MAX_STEPS;i++)
    {
        notes=[[ NSMutableArray alloc ] init ];
        steps[i]=notes;
        
        parameters[i]=[[ ParameterChange alloc ] init ];
    }

    return self;
}

- noteForKey: (int) key atStep: (int) index
{
    id note,e;
    id step;
    
    if(index>=MAX_STEPS) return nil;
    
    [ lock lock ];
    
    step=steps[index];
    
    e=[ step objectEnumerator ];
    while( (note=[ e nextObject ]) != nil)
    {
        if([ note keyNumber ]==key)
        {
            [ lock unlock ];
            return note;
        }
    }
    [ lock unlock ];
    return nil;
}

- (int) findNote: newNote inStep: (int) index
{
    int i,end;
    id step;
    Note *note;
    
    if(index>=MAX_STEPS) return -1;
    
    [ lock lock ];
    
    step=steps[index];
    end=[ step count ];

    for(i=0;i<end;i++)
    {
        note=[ step objectAtIndex: i ];
        if ( [ note equals: newNote ] )
        {
            [ lock unlock ];
            return i;
        };
    }

    [ lock unlock ];

    return -1;
}

- setNote: aNote atStep: (unsigned long int) index
    multi: (BOOL) aBool
{
    int i;
    id step;
    if(index>=MAX_STEPS) return nil;
    
    step=steps[index];
    
    // find note with the same key number
    i=[ self findNote: aNote inStep: index ];
    if(i>=0)
    {
        // replace it with the new one
        [ lock lock ];
        [ step replaceObjectAtIndex: i withObject: aNote ];
        // and we are finished
        [ lock unlock ];
        return self;
    }

    [ lock lock ];

    // if not in multi edit mode, remove all other notes
    if(aBool==NO) [ step removeAllObjects ];
    
    // then add new note
    [ step addObject: aNote ];

    [ lock unlock ];
     
    return self;
}

- clearAllNotesAtStep: (unsigned long int) index
{
    id step;
    
    if(index>=MAX_STEPS) return nil;
    
    step=steps[index];
    [ lock lock ];
    [ step removeAllObjects ];
    [ lock unlock ];
    
    return self;
}

- clearNote: aNote atStep: (unsigned long int) index
{
    int i;
    
    if(index>=MAX_STEPS) return nil;
    
    i=[ self findNote: aNote inStep: index ];
    if(i>=0)
    {
        [ lock lock ];

        [ steps[index] removeObjectAtIndex: i ];

        [ lock unlock ];

    }

    return self;
}

- (NSArray *) notesAtStep: (unsigned long int) index
{
    NSArray *array;
    
    if(index>=MAX_STEPS) return nil;
    
    [ lock lock ];
    
    array=[ NSArray arrayWithArray: steps[index] ];

    [ lock unlock ];

    return array;
}

- setParameters: (ParameterChange *) p atStep: (unsigned long int) step
{
    if(step>=MAX_STEPS) return nil;
    
    [ p retain ];
    [ parameters[step] release ];
    parameters[step]=p;
    return self;
}

- (ParameterChange *) parametersAtStep: (unsigned long int) step
{
    if(step>=MAX_STEPS) return nil;
    
    return parameters[step];
}

- (void) print
{
    int i;
    
    dbgprintf("pattern %s length: %d\n", [ name cString ], (int) length);
    for(i=0;i<MAX_STEPS;i++)
    {
        dbgprintf("%d ", [ steps[i] count ]);
    }
    dbgprintf("\n");
}

+ test
{
    int i;
    id note1,note2, note3,n,a,e;
    id pattern;
    
    dbgprintf("SeqPattern test\n");
    
    pattern=[[ self alloc ] init ];
    note1=[ Note keyNumber: 60 ];
    note2=[ Note keyNumber: 61 ];
    note3=[ Note keyNumber: 60 ];
    
    for(i=0;i<10;i++)
    {
        [ pattern setNote: note1 atStep: i multi: YES ];
    }

    for(i=0;i<10;i++)
    {
        //[ pattern setNote: note2 atStep: i multi: YES ];
    }

    for(i=0;i<10;i++)
    {
        [ pattern setNote: note3 atStep: i multi: YES ];
    }

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
    [ pattern release ];
    
    return self;
}

@end
