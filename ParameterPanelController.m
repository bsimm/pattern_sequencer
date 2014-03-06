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

#import "ParameterPanelController.h"
#import "SequencerController.h"
#import "Sequencer.h"
#import "Part.h"

@implementation ParameterPanelController

- (void) dealloc
{
    [ parameters release ];
    [ super dealloc ];
}
- (IBAction)ccButtonClicked:(id)sender
{
    BOOL enabled=[ ccButton intValue ];
    
    if(enabled)
        [ parameters setCcNumber: 0 ];
    else
        [ parameters setCcNumber: -1 ];

    [ self enableFields ];
    [ self updateFields ];
    [ self updateParameters ];
}

- (IBAction)ccNoChanged:(id)sender
{
    [ self updateParameters ];
}

- (IBAction)ccValueChanged:(id)sender
{
    [ self updateParameters ];
}

- (IBAction)pcButtonClicked:(id)sender
{
    BOOL enabled=[ pcButton intValue ];
    
    if(enabled)
        [ parameters setProgramNumber: 1 ];
    else
        [ parameters setProgramNumber: 0 ];

    [ self enableFields ];
    [ self updateFields ];
    [ self updateParameters ];
}

- (IBAction)pcValueChanged:(id)sender
{
    [ self updateParameters ];
}

- (IBAction)endValueChanged: (id) sender
{
    [ parameters setCcNextValue: [ endValueField intValue ]];
    [ self updateParameters ];
}

- (IBAction)smoothButtonClicked: (id) sender
{
    BOOL smooth=[ smoothButton intValue ];
    
    [ parameters setSmooth: smooth ];
    [ self enableFields ];
    [ self updateFields ];
    [ self updateParameters ];
}

- (IBAction)ccNextClicked: (id) sender
{
    int value1,value2,delta;
    
    ParameterChange *newParameters;
    
    int x=(step+1) & 127;
    
    // if changing the step in the sequencer fails,
    // it is currently playing and we must keep
    // our own step position
    if([ sequencer setStep: x ]) x=[ sequencer currentStep ];
    step=x;

    newParameters=[[ ParameterChange alloc ] initWith: parameters ];
    
    if([ parameters smooth ])
    {
        value1=[ parameters ccValue ];
        value2=[ parameters ccNextValue ];
        delta=value2-value1;
        
        
        value1=value2;
        value2=value1+delta;
        
        if(value2<0) value2=0;
        if(value2>127) value2=127;
        
        [ newParameters setCcValue: value1 ];
        [ newParameters setCcNextValue: value2 ];
    }
    
    
    [ pattern setParameters: newParameters atStep: x ];

    [ sequencerController parametersChanged ];

    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqStepChanged" object: sequencer ];
    
    [ newParameters release ];

}

- (IBAction)pitchMatrixClicked: (id) sender
{
    // id cell=[ sender selectedCell ];
    // int tag=[ cell tag ];
    
    [ self updateParameters ];

}

- (IBAction)pitchNextClicked: (id) sender
{
    int value1,value2,delta;
    
    ParameterChange *newParameters;
    
    int x=(step+1) & 127; 
    
    if([ sequencer setStep: x ]) x=[ sequencer currentStep ];
    step=x;
    
    newParameters=[[ ParameterChange alloc ] initWith: parameters ];
    
    if([ parameters pitchBend ])
    {
        value1=[ parameters pitchStart ];
        value2=[ parameters pitchEnd ];
        delta=value2-value1;
        
        
        value1=value2;
        value2=value1+delta;
        
        if(value2<0) value2=0;
        if(value2>16383) value2=16383;
        
        [ newParameters setPitchStart: value1 ];
        [ newParameters setPitchEnd: value2 ];
    }

    [ pattern setParameters: newParameters atStep: x ];
    
    [ sequencerController parametersChanged ];
    
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqStepChanged" object: sequencer ];
    
    [ newParameters release ];

}

- (IBAction)pitchButtonClicked: (id) sender
{
    [ self updateParameters ];
    [ self enableFields ];
}

- (void) loadStepParameters: (int) x
{
    step=x;
    [ parameters release ];
    
    parameters=[ pattern parametersAtStep: step ];
    [ parameters retain ];

    [ self updateButtons ];
    [ self updateFields ];
}

- (void) updateButtons
{
    [ pcButton setIntValue: (int) [ parameters programEnabled ]];
    [ ccButton setIntValue: (int) [ parameters ccEnabled ]];
    [ pitchButton setIntValue: (int) [ parameters pitchBend ]];
    [ smoothButton setIntValue: (int) [ parameters smooth ]];
    [ self enableFields ];
}

- (void) enableFields
{
    BOOL pcFlag=[ parameters programEnabled ];
    BOOL ccFlag=[ parameters ccEnabled ];
    BOOL pFlag=[ parameters pitchBend ];
    
    [ pcValueField setEnabled: pcFlag ];
    [ ccValueField setEnabled: ccFlag ];
    [ ccNoField setEnabled: ccFlag ];
    [ smoothButton setEnabled: ccFlag ];
    [ ccNextButton setEnabled: ccFlag ];
    [ pitchNextButton setEnabled: pFlag ];
    [ endValueField setEnabled: [ parameters smooth ]];
    [[ pitchMatrix cellWithTag: 0 ] setEnabled: pFlag ];
    [[ pitchMatrix cellWithTag: 1 ] setEnabled: pFlag ];
}

- (void) updateFields
{
    int start,end;
    
    [ stepField setIntValue: step ];
    [ ccValueField setIntValue: [ parameters ccValue ]];
    [ ccNoField setIntValue: [ parameters ccNumber ]];
    [ pcValueField setIntValue: [ parameters programNumber ]];
    [ endValueField setIntValue: [ parameters ccNextValue ]];
    
    if([ parameters pitchBend ])
    {
        start=[ parameters pitchStart ];
        end=[ parameters pitchEnd ];
    }
    else
    {
        start=end=0x2000;
    }
    
    [[ pitchMatrix cellWithTag: 0 ] setIntValue:
        start*1000/16384 ];
    [[ pitchMatrix cellWithTag: 1 ] setIntValue:
        end*1000/16384 ];
}

- (void) updateParameters
{
    int start;
    int end;
    ParameterChange *p=[[ ParameterChange alloc ] init ];

    [ p setCcValue: [ ccValueField intValue ]];
    [ p setCcNumber: [ ccNoField intValue ]];
    [ p setProgramNumber: [ pcValueField intValue ]];
    [ p setSmooth: (BOOL) [ smoothButton intValue ]];
    [ p setPitchBend: (BOOL) [ pitchButton intValue ]];
    [ p setCcNextValue: [ endValueField intValue ]];

    start=[[ pitchMatrix cellWithTag: 0 ] intValue ];
    end=[[ pitchMatrix cellWithTag: 1 ] intValue ];
    start=start*16384/1000;
    end=end*16384/1000;
    if(start>16383) start=16383;
    if(end>16383) end=16383;
    [ p setPitchStart: start ];
    [ p setPitchEnd: end ];


    [ pattern setParameters: p atStep: step ];
    parameters=p;
    // [ parameters retain ];
    // [ p release ];

    [ sequencerController parametersChanged ];
}

- (void) patternChanged: (NSNotification *) note
{
    // id sequencer=[ sequencerController sequencer ];
    id part=[ sequencerController selectedPart ];
    id newPattern=[ part editPattern ];

    [ self setPattern: newPattern ];
    
}

- (void) stepChanged: (NSNotification *) note
{
    int s=step;
    
    if(![sequencer isRunning]) s=[ sequencer currentStep ];
    [ self loadStepParameters: s];
}

- (void) partAdded: (NSNotification *) note
{

}

- (void) partDeleted: (NSNotification *) note
{

}

- (void) patternAdded: (NSNotification *) note
{

}

- (void) patternDeleted: (NSNotification *) note
{

}


- (id)sequencer {
    return sequencer;
}

- (void)setSequencer:(id)newSequencer
{
    NSNotificationCenter *nc=[ NSNotificationCenter defaultCenter ];

    if (sequencer != newSequencer)
    {
        [ nc removeObserver: self ];
    
        [sequencer release];
        
        sequencer = newSequencer;
        [ sequencer retain ];
        
        [ self setPattern: [[ sequencer partAtIndex: 0 ] editPattern ]];

        [ nc addObserver: self selector: @selector(stepChanged:)
                name: @"pseqStepChanged"
                object: nil ];
        [ nc addObserver: self selector: @selector(patternChanged:)
                name: @"pseqPatternChanged"
                object: nil ];


    }
    
}

- (id)pattern
{
    return pattern;
}

- (void)setPattern:(id)newPattern
{
        [ newPattern retain ];
        [ pattern release ];
        pattern=newPattern;

        step=[ sequencer currentStep ];
        [ self loadStepParameters: step ];
}

- (int)step
{
    return step;
}

- (void)setStep:(int) newStep
{
    [ self loadStepParameters: newStep ];
}

@end
