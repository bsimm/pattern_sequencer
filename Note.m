//
//  Note.m
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


#import "Note.h"

#include "debug.h"

#define DEFAULT_VELOCITY 90
#define LOWEST_OCTAVE 2

@implementation Note
+ key: (int) k duration: (unsigned long int) d velocity: (int) v
{
    id newNote=[ self alloc ];
    
    [ newNote autorelease ];

    return [ newNote initWithKey: k duration: d velocity: v ];
}

+ keyNumber: (int) k
{
    return [ self key: k duration: 1 velocity: DEFAULT_VELOCITY ];
}

+ (NSString *) nameForKeyNumber: (int) k
{
    char buffer[32];
    static const char *keyNames[]=
    {
        "C", 	// 0
        "C#",	// 1
        "D",	// 2
        "D#",	// 3
        "E",	// 4
        "F",	// 5
        "F#",	// 6
        "G",	// 7
        "G#",	// 8
        "A",	// 9
        "A#",	// 10
        "H"	// 11
    };
    int offset;
    int octave;
    
    offset=k % 12;
    octave=k/12;
    octave-=LOWEST_OCTAVE;

    snprintf(buffer,sizeof(buffer),"%s%d", keyNames[offset],
            octave);
    buffer[sizeof(buffer)-1]='\0';
    
    return [ NSString stringWithCString: buffer ];
}

- initWithCoder: (NSCoder *) coder
{
    if(![super init ]) return nil;
    
    [ coder decodeValueOfObjCType: @encode(int) at: &key ];
    [ coder decodeValueOfObjCType: @encode(unsigned long int) at: &duration ];
    [ coder decodeValueOfObjCType: @encode(int) at: &velocity ];
    [ coder decodeValueOfObjCType: @encode(int) at: &release ];
    [ coder decodeValueOfObjCType: @encode(double) at: &shuffle ];
    [ coder decodeValueOfObjCType: @encode(int) at: &spare1 ];
    [ coder decodeValueOfObjCType: @encode(double) at: &spare2 ];    
    dbgprintf("Note unarchived: %d\n", (int) key );
    return self;
}

- (void)encodeWithCoder: (NSCoder *) coder
{
    [ coder encodeValueOfObjCType: @encode(int) at: &key ];
    [ coder encodeValueOfObjCType: @encode(unsigned long int) at: &duration ];
    [ coder encodeValueOfObjCType: @encode(int) at: &velocity ];
    [ coder encodeValueOfObjCType: @encode(int) at: &release ];
    [ coder encodeValueOfObjCType: @encode(double) at: &shuffle ];
    [ coder encodeValueOfObjCType: @encode(int) at: &spare1 ];
    [ coder encodeValueOfObjCType: @encode(double) at: &spare2 ];   
}

- initWithKey: (int) k duration: (unsigned long int) d velocity: (int) v
{
    [ super init ];
    
    key=k;
    duration=d;
    velocity=v;
    return self;
}

- (BOOL) equals: aNote
{
    if( [ aNote class ] != [ self class ] ) return NO;
    if( [ aNote keyNumber ] != key ) return NO;
    return YES;
}

- (int) keyNumber
{
    return key;
}

- (NSString *) keyName
{
    return [[ self class ] nameForKeyNumber: key ];
}

- setKeyNumber: (int) anInt
{
    key=anInt;
    return self;
}

- (unsigned long int) duration
{
    return duration;
}

- setDuration: (unsigned long int) anInt
{
    duration=anInt;
    return self;
}

- (int) velocity
{
    return velocity;
}

- setVelocity: (int) anInt
{
    velocity=anInt;
    return self;
}

@end
