//
//  Block.m
//  PatternSequencer
//
//  Created by Sebastian Lederer on Sun Nov 02 2003.
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

#import "Block.h"

#include "debug.h"

@implementation Block

- init
{
    length=4;
    name=[ NSString stringWithString: @"-" ];
    [ name retain ];
    return self;
}

- (void) dealloc
{
    [ name release ];
}

- initWithCoder: (NSCoder *) coder
{
    int i;
    
    if(![ super init ]) return nil;
    
    [ coder decodeValueOfObjCType: @encode(int) at: &partsCount ];
    [ coder decodeValueOfObjCType: @encode(int) at: &length ];
    name=[ coder decodeObject ];
    [ name retain ];
    for(i=0;i<partsCount;i++)
        [ coder decodeValueOfObjCType: @encode(int) at: &patternIndex[i] ];
    return self;    
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    int i;
    
    [ coder encodeValueOfObjCType: @encode(int) at: &partsCount ];
    [ coder encodeValueOfObjCType: @encode(int) at: &length ];
    [ coder encodeObject: name ];
    for(i=0;i<partsCount;i++)
        [ coder encodeValueOfObjCType: @encode(int) at: &patternIndex[i] ];
}

- setPartsCount: (int) anInt
{
    int i;

    if(anInt>MAX_PARTS) return nil;

    dbgprintf("partsCount: %d, new: %d\n",partsCount,anInt);
    
    if(anInt>partsCount)
    {
        for(i=partsCount;i<anInt;i++)
        {
            patternIndex[i]=0;
        }
    }
    partsCount=anInt;
    return self;
}

- (int) length
{
    return length;
}

- (NSString *) name
{
    return name;
}

- (int) patternForPart: (int) partNo
{
    return patternIndex[partNo];
}

- setLength: (int) anInt
{
    length=anInt;
    return self;
}

- setName: (NSString *) aStr
{
    [ aStr retain ];
    [ name release ];
    name=aStr;
    return self;
}

- setPattern: (int) pIndex forPart: (int) partIndex
{
    patternIndex[partIndex]=pIndex;
    return self;
}

- removePart: (int) partIndex
{
    int i;
    
    dbgprintf("removePart\n");
    for(i=partIndex;i<partsCount-1;i++) patternIndex[i]=patternIndex[i+1];
    partsCount--;
    return self;
}

@end
