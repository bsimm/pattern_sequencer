//
//  ParameterChange.m
//  PatternSequencer
//
//  Created by Sebastian Lederer on 09.09.04.
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


#import "ParameterChange.h"
#import "OutputChannel.h"

#import <Foundation/NSCoder.h>

#define SMOOTH 6

@implementation ParameterChange

- init
{
    pitchStart=0x2000;
    pitchEnd=0x2000;
    ccNumber=-1;
    return self;
}

- initWithCoder: (NSCoder *) coder
{
    if(![super init ]) return nil;
    
    [ coder decodeValueOfObjCType: @encode(int) at: &programNumber ];
    [ coder decodeValueOfObjCType: @encode(int) at: &ccNumber ];
    [ coder decodeValueOfObjCType: @encode(int) at: &ccValue ];
    [ coder decodeValueOfObjCType: @encode(int) at: &ccNextValue ];
    [ coder decodeValueOfObjCType: @encode(BOOL) at: &programEnabled ];
    [ coder decodeValueOfObjCType: @encode(BOOL) at: &ccEnabled ];
    [ coder decodeValueOfObjCType: @encode(BOOL) at: &smooth ];
    [ coder decodeValueOfObjCType: @encode(BOOL) at: &pitchEnabled ];
    [ coder decodeValueOfObjCType: @encode(int) at: &pitchStart ];
    [ coder decodeValueOfObjCType: @encode(int) at: &pitchEnd ];
    [ coder decodeValueOfObjCType: @encode(int) at: &spare ];
    [ coder decodeValueOfObjCType: @encode(int) at: &spare1 ];
    spare2=[ coder decodeObject ];
    spare3=[ coder decodeObject ];
    
    [ self updateFlags ];
    return self;
}

- (void)encodeWithCoder: (NSCoder *) coder
{
    [ coder encodeValueOfObjCType: @encode(int) at: &programNumber ];
    [ coder encodeValueOfObjCType: @encode(int) at: &ccNumber ];
    [ coder encodeValueOfObjCType: @encode(int) at: &ccValue];
    [ coder encodeValueOfObjCType: @encode(int) at: &ccNextValue];
    [ coder encodeValueOfObjCType: @encode(BOOL) at: &programEnabled];
    [ coder encodeValueOfObjCType: @encode(BOOL) at: &ccEnabled];
    [ coder encodeValueOfObjCType: @encode(BOOL) at: &smooth];
    [ coder encodeValueOfObjCType: @encode(BOOL) at: &pitchEnabled];
    [ coder encodeValueOfObjCType: @encode(int) at: &pitchStart];
    [ coder encodeValueOfObjCType: @encode(int) at: &pitchEnd];
    [ coder encodeValueOfObjCType: @encode(int) at: &spare ];
    [ coder encodeValueOfObjCType: @encode(int) at: &spare1];    
    [ coder encodeObject: spare2 ];
    [ coder encodeObject: spare3 ];
}

- initWith: (ParameterChange *) o
{
    programNumber=[ o programNumber ];
    ccNumber=[ o ccNumber ];
    ccValue=[ o ccValue ];
    ccNextValue=[ o ccNextValue ];
    smooth=[ o smooth ];
    pitchEnabled=[ o pitchBend ];
    pitchStart=[ o pitchStart ];
    pitchEnd=[ o pitchEnd ];
    
    [ self updateFlags ];

    return self;
    
}
- (int)programNumber
{
    return programNumber;
}

- (void) updateFlags
{
    programEnabled=(programNumber>0);
    ccEnabled=(ccNumber>=0);   
}

- (void)setProgramNumber:(int)newProgramNumber
{
    programNumber = newProgramNumber;
    programEnabled=(programNumber>0);
}

- (int)ccNumber
{
    return ccNumber;
}

- (void)setCcNumber:(int)newCcNumber
{
    ccNumber = newCcNumber;
    ccEnabled=(ccNumber>=0);
}

- (int)ccValue
{
    return ccValue;
}

- (void)setCcValue:(int)newCcValue
{
    ccValue = newCcValue;
}

- (void) setCcNextValue: (int) anInt
{
    ccNextValue=anInt;
}

- (int) ccNextValue
{
    return ccNextValue;
}

- (int) pitchStart
{
    return pitchStart;
}

- (int) pitchEnd
{
    return pitchEnd;
}

- (void) setSmooth: (BOOL) aBool
{
    smooth=aBool;
}

- (void) setPitchBend: (BOOL) aBool
{
    pitchEnabled=aBool;
}

- (void) setPitchStart: (int) anInt
{
    pitchStart=anInt;
}

- (void) setPitchEnd: (int) anInt
{
    pitchEnd=anInt;
}

- (BOOL) pitchBend
{
    return pitchEnabled;
}

- (BOOL) smooth
{
    return smooth;
}

- (BOOL) ccEnabled
{
    return ccEnabled;
}

- (BOOL) programEnabled
{
    return programEnabled;
}

- (BOOL) enabled
{
    return ccEnabled || programEnabled || pitchEnabled;
}

- sendTo: (OutputChannel *) output at: (Timestamp) time interval: (Timestamp) ticks
{
    int deltaTime;
    float deltaValue;
    float value;
    Timestamp t;
    int i;
    
    if(programEnabled && programNumber>0)
    {
        [ output sendProgramChange: programNumber at: time ];
    }
    
    if(ccEnabled)
    {
        if(smooth)
        {
            deltaTime=ticks/SMOOTH;
            deltaValue=(ccNextValue-ccValue)/(float)SMOOTH;
            value=ccValue;
            t=time;
            for(i=0;i<SMOOTH;i++)
            {
                [ output sendController: ccNumber value: value at: t ];
                value+=deltaValue;
                t+=deltaTime;
            }
        }
        else
        {
            [ output sendController: ccNumber value: ccValue at: time ];
        }
    }
    
    if(pitchEnabled)
    {
        deltaTime=ticks/SMOOTH;
        deltaValue=(pitchEnd-pitchStart)/(float)SMOOTH;
        value=pitchStart;
        t=time;
        for(i=0;i<SMOOTH;i++)
        {
            [ output sendPitchBend: value at: t ];
            value+=deltaValue;
            t+=deltaTime;
        }
    }
    return self;
}
@end
