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

#import "PreferencesController.h"

#import "Sequencer.h"
#import "PatternView.h"
#import "MidiPort.h"

NSString *PSeqExternalClock=@"PSeqExternalClock";
NSString *PSeqSendRealtime=@"PSeqSendRealtime";
NSString *PSeqGridColor=@"PSeqGridColor";
NSString *PSeqInputPort=@"PSeqInputPort";
NSString *PSeqOutputPort=@"PSeqOutputPort";

@implementation PreferencesController
+ (void) initialize
{
    NSMutableDictionary *defaultValues = [ NSMutableDictionary dictionary ];
    NSData *colorData = [ NSArchiver archivedDataWithRootObject:
                            [ NSColor redColor ]];
    
    [ defaultValues setObject: colorData forKey: PSeqGridColor ];
    [ defaultValues setObject: [ NSNumber numberWithBool: NO ] forKey: PSeqSendRealtime ];
    [ defaultValues setObject: [ NSNumber numberWithBool: NO ] forKey: PSeqExternalClock ];
    [ defaultValues setObject: [ NSNumber numberWithInt: 0 ] forKey: PSeqInputPort ];
    [ defaultValues setObject: [ NSNumber numberWithInt: 0 ] forKey: PSeqOutputPort ];
    [[ NSUserDefaults standardUserDefaults ] registerDefaults: defaultValues ];
}

- (void) dealloc
{
    [[ NSNotificationCenter defaultCenter ] removeObserver: self ];    
    [ super dealloc ];
}

- (void) awakeFromNib
{
    NSUserDefaults *defaults=[ NSUserDefaults standardUserDefaults ];
    NSColor *color;
    NSNotificationCenter *nc=[ NSNotificationCenter defaultCenter ];

    [ self createInputPortMenu ];

    useExternalClock=[ defaults boolForKey: PSeqExternalClock ];
    sendRealtime=[ defaults boolForKey: PSeqSendRealtime ];
    color=[ NSUnarchiver unarchiveObjectWithData: [ defaults objectForKey: PSeqGridColor ]];
    portIndex=[ defaults integerForKey: PSeqInputPort ];
    if(portIndex>=numberOfPorts) portIndex=0;

    [ realtimeButton setState: sendRealtime ];
    [ externalClockButton setState: useExternalClock ];
    [ gridColour setColor: color ];
    [ midiInputButton selectItemAtIndex: portIndex ];

    [ patternView setGridColor: color ];
    [ sequencer setSendRealtime: sendRealtime ];
    [ sequencer setExternalClock: useExternalClock ];
    [ self selectInputPort ];

    [ nc addObserver: self selector: @selector(sequencerStarted:)
                name: @"pseqStarted"
                object: nil ];
    [ nc addObserver: self selector: @selector(sequencerStopped:)
                name: @"pseqStopped"
                object: nil ];
}

- createInputPortMenu
{
    NSArray *ports;
    id e,o;

    [ midiInputButton removeAllItems ];

    ports=[ MidiPort availableInputPorts ];
    e=[ ports objectEnumerator ];
    while(o=[ e nextObject ])
    {
        [ midiInputButton addItemWithTitle: o ];
    }
    
    numberOfPorts=[ ports count ];
    return self;
}

- (IBAction)colourChanged:(id)sender
{
    NSColor *newColor=[ sender color ];
    NSData *colorData = [ NSArchiver archivedDataWithRootObject: newColor ];

    [ patternView setGridColor: newColor ];
    [[ NSUserDefaults standardUserDefaults ] setObject: colorData forKey: PSeqGridColor ];
}

- (IBAction)externalClockClicked:(id)sender
{
    NSUserDefaults *defaults=[ NSUserDefaults standardUserDefaults ];
    
    useExternalClock=[ externalClockButton state ];
    
    [ defaults setBool: useExternalClock forKey: PSeqExternalClock ];
    [ sequencer setExternalClock: useExternalClock ];
}

- (IBAction)midiInputClicked:(id)sender
{
    portIndex=[ sender indexOfSelectedItem ];
    
    [[ NSUserDefaults standardUserDefaults ] setInteger: portIndex forKey: PSeqInputPort ];
    
    // ... set input port on sequencer
    [ self selectInputPort ];
}

- (IBAction)realtimeClicked:(id)sender
{
    NSUserDefaults *defaults=[ NSUserDefaults standardUserDefaults ];
    
    sendRealtime=[ realtimeButton state ];
    
    [ defaults setBool: sendRealtime forKey: PSeqSendRealtime ];
    [ sequencer setSendRealtime: sendRealtime ];

}

- setSequencer: anId
{ 
    [ anId retain ];
    [ sequencer release ];
    sequencer=anId;

    [ sequencer setSendRealtime: sendRealtime ];
    [ sequencer setExternalClock: useExternalClock ];

    [ self selectInputPort ];
    
    return self;
}

- updateButtons
{
    BOOL running=[ sequencer isRunning ];
    
    [ realtimeButton setEnabled: !running ];
    [ externalClockButton setEnabled: !running ];
    [ midiInputButton setEnabled: !running ];
    
    return self;
}

// notifications
- (void) sequencerStarted: (NSNotification *) note
{
    [ self updateButtons ];
}

- (void) sequencerStopped: (NSNotification *) note
{
    [ self updateButtons ];
}


- (void) selectInputPort
{
    MidiPort *port;
    if(!sequencer) return;
    
    port=[ sequencer port ];
    [ port closeInputPort ];
    [ port openInputPort: portIndex ];
}
@end
