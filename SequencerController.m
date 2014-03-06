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

#import "SequencerController.h"

#import "PatternMatrix.h"
#import "PatternView.h"
#import "Note.h"
#import "MidiPort.h"
#import "OutputChannel.h"
#import "ScoreController.h"
#import "PreferencesController.h"

#include "debug.h"

#define LOWEST_OCTAVE 2
#define MAX_PARTS 16
#define MAX_PATTERNS 8

#define DRAG_MODE_MOVE      2
#define DRAG_MODE_RESIZE    1
#define DRAG_MODE_NONE      0

extern NSString *PSeqOutputPort;

int lengthToIndex(int length)
{
    /* 1,2,4,8 */
    
    static int i[]={ 0,1,0,2,0,0,0,3 };
    
    length=(length/16)-1;
    
    if(length<0 || length>7) return 0;
    
    return i[length];
}

@implementation SequencerController

- (void) awakeFromNib
{
    currentVelocity=100;

    [ renameController setDelegate: self ];

    [ self newSequencer ];

    [ self resetViews ];

    [ self updateSequencer ];
}

- (void) dealloc
{
    [ sequencer release ];
    [ matrix release ];
    [ super dealloc ];
}

- (void) resetViews
{
    [ scoreController createColumns ];
    [ self updateSequencerFields ];

    currentOctave=3;
    [ octaveMatrix selectCellWithTag: currentOctave ];

    [ matrixModeMenu selectCellWithTag: 0 ];
    [ self disableVelocityEdit ];

    [ partsMenu selectItemAtIndex: 0 ];
    [ self selectPartAtIndex: 0 ];
    [ self updatePartsMenu ];
    [ self updatePortsMenu ];
}

- (int) stepsPerBeatValue
{
    return [[[ stepsPerBeatMenu selectedItem ] title ] intValue ];
}

- (void) updateSequencer
{
    int tempo=[ tempoField intValue ];
    [ sequencer setStepsPerBeat: [ self stepsPerBeatValue ]];               
    if(tempo>0 && tempo<999) [ sequencer setTempo: tempo ];
}

- (IBAction) stepRecordClicked: (id) sender
{
    if([ sequencer isRunning ]) return;
    
    stepRecording=YES;
    [ self updateSequencer ];
    [ sequencer startStepRecordingOnPart: [ partsMenu indexOfSelectedItem ]];
    [ self updateButtons ];
    [ scoreController sequencerStarted ];
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqStarted" object: sequencer ];
}

- (IBAction) stopClicked: (id) sender
{
    int x;

    // "Stop" clicked while in step record mode
    if(stepRecording==YES)
    {
        [ sequencer stop ];
        stepRecording=NO;
        [ currentPart selectPattern: currentPatternIndex ];
        [ self updateIndicator ];
        [ self updateButtons ];
        [ scoreController sequencerStopped ];
    }
    else
    {
    // "Stop" clicked while in play mode
        [ timer invalidate ];
        timer=nil;
        [ sequencer stop ];
        if([ sequencer isRunning ]) printf("crap: sequencer isRunning is still YES\n");
        [ currentPart selectPattern: currentPatternIndex ];
        [ self updateIndicator ];
        [ self updateButtons ];
        [ scoreController sequencerStopped ];
    }

    // wrap step position in the sequencer
    // so that it matches the visible one
    x= [ sequencer realtimeStep ];
    x &= (currentPatternLength-1);
    [ sequencer setStep: x ];

    [[ NSNotificationCenter defaultCenter ]
        postNotificationName: @"pseqStopped" object: sequencer ];
}

- (IBAction)start:(id)sender
{
    if(!timer)
    {
        if([ sequencer isRunning ]) return;
        
        [ self updateSequencer ];

        timer=[ NSTimer scheduledTimerWithTimeInterval: [ sequencer stepTime ]
                        target: self selector: @selector(tick:)
                        userInfo: nil repeats: YES ];


        [ sequencer start ];
        [ self updateButtons ];
        [ scoreController sequencerStarted ];
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqStarted" object: sequencer ];
    }
    else
    {
        printf("should not come here!\n");
        [ timer invalidate ];
        timer=nil;
        [ sequencer stop ];
        [ currentPart selectPattern: currentPatternIndex ];
        [ self updateIndicator ];
        [ self updateButtons ];
        [ scoreController sequencerStopped ];
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqStopped" object: sequencer ];
    }
}

- patternAdded: (int) index
{
    [ self updatePatternsMenu ];

    // show new pattern
    [ patternsMenu selectItemAtIndex: index ];
    [ self selectPatternAtIndex: index ];
    
    return self;
}

- (BOOL) canAddPattern
{
    int count;

    count=[[currentPart patterns ] count ];

    if(count>=MAX_PATTERNS) return NO;
    else return YES;
}

- (BOOL) modified
{
    return modified;
}

- setModified
{
    modified=YES;
    return self;
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
    SEL action=[ menuItem action ];
    BOOL notRunning=![ sequencer isRunning ];

    if(action==@selector(loadPattern:)
        || action==@selector(duplicateEditPattern:))
    {
        return notRunning && [ self canAddPattern ] && [ mainWindow isKeyWindow ];
    }
    else
    if(action==@selector(savePattern:))
    {
        return notRunning && [ mainWindow isKeyWindow ];
    }
    else
    if(action==@selector(save:))
    {
        return notRunning && modified;
    }
    else
    if(action==@selector(open:) || action==@selector(saveAs:) 
        || action==@selector(clean:))
    {
        return notRunning;
    }
    else
        return YES;
}

- loadPatternFromPath: (NSString *) path
{
    id newPattern;
    int index;

    if(![ self canAddPattern ]) return nil;

    NS_DURING
        newPattern=[ NSUnarchiver unarchiveObjectWithFile: path ];
    NS_HANDLER
        newPattern=nil;
        NSBeep();
        NSRunAlertPanel(@"Error Opening File", @"%@",@"OK",nil,nil,
            localException);
        NS_VALUERETURN(nil,id);
    NS_ENDHANDLER;
    
    index=[ currentPart addPattern: newPattern ];
 
    [ self patternAdded: index ];
    
    return self;
}

- savePatternToPath: (NSString *) path
{
    BOOL success;
    NSString *realPath;
    SeqPattern *pattern=[ currentPart currentPattern ];

    if(![ path hasSuffix: @".ptrn" ])
        realPath=[ path stringByAppendingString: @".ptrn" ];
    else
        realPath=path;

    NS_DURING
        success=[ NSArchiver archiveRootObject: pattern toFile: realPath ];
    NS_HANDLER
        NSBeep();
        NSRunAlertPanel(@"Error Writing File", @"%@", @"OK", nil, nil, 
                localException);
        NS_VALUERETURN(nil,id);
    NS_ENDHANDLER

    if(!success)
    {
        NSBeep();
        NSRunAlertPanel(@"Error Writing File", @"%@", @"OK", nil, nil, 
                path);        
    }

    return self;

}

- (IBAction) loadPattern: (id) sender
{
    NSOpenPanel *openPanel;
    
    openPanel=[NSOpenPanel openPanel];
    
    [ openPanel beginSheetForDirectory: nil
        file: nil
        types: [ NSArray arrayWithObject: @"ptrn" ]
        modalForWindow: mainWindow
        modalDelegate: self
        didEndSelector: @selector(loadPatternEnd:returnCode:contextInfo:)
        contextInfo: nil ];
}

- (void) loadPatternEnd: (NSOpenPanel *) sheet returnCode: (int) returnCode
    contextInfo: (void *) contextInfo
{
    NSString *path;
    
    if(returnCode!=NSOKButton) return;
    
    path=[ sheet filename ];

    dbgprintf("loadPatternEnd %s\n",[ path cString ]);

    [ self loadPatternFromPath: path ];
}

- (IBAction) savePattern: (id) sender
{
    NSSavePanel *savePanel=[ NSSavePanel savePanel ];
    
    [ savePanel beginSheetForDirectory: nil
        file: @"Unnamed.ptrn"
        modalForWindow: mainWindow
        modalDelegate: self
        didEndSelector: @selector(savePatternEnd:returnCode:contextInfo:)
        contextInfo: nil
    ];
}

- (void) savePatternEnd: (NSOpenPanel *) sheet returnCode: (int) returnCode
    contextInfo: (void *) contextInfo
{
    NSString *path;
    
    if(returnCode!=NSOKButton) return;
    
    path=[ sheet filename ];

    dbgprintf("savePatternEnd %s\n",[ path cString ]);

    [ self savePatternToPath: path ];
}

- (BOOL) application: (NSApplication *) app openFile: (NSString *) filename
{
    if(![ self mayOpenFile]) return NO;

    [ filename retain ];
    [ currentFilePath release ];
    currentFilePath=filename;
    
    return ([ self load ]!=nil);
}

- load
{
    id newSequencer;
    
    NS_DURING
        newSequencer= [ NSUnarchiver unarchiveObjectWithFile: currentFilePath ];
    NS_HANDLER
        newSequencer=nil;
        NSBeep();
        NSRunAlertPanel(@"Error Opening File", @"%@", @"OK", nil, nil, 
                localException);
        NS_VALUERETURN(nil,id);
    NS_ENDHANDLER

    [ sequencer release ];

    sequencer=newSequencer;

    [ sequencer retain ];


    // FIX: duplicate code in -newSequencer
    [ sequencer setPort: [ MidiPort defaultPort ]];
    [ scoreController setSequencer: sequencer ];
    [ parameterPanelController setSequencer: sequencer ];
    [ preferencesController setSequencer: sequencer ];
    
    [ self resetViews ];

    modified=NO;

    return self;
}

- save
{
    BOOL success;
    NSString *path;

    if(![ currentFilePath hasSuffix: @".pseq" ])
        path=[ currentFilePath stringByAppendingString: @".pseq" ];
    else
        path=currentFilePath;

    dbgprintf("saving sequencer tempo %d\n", [ sequencer tempo ]);
    [ self updateSequencer ];

    NS_DURING
        success=[ NSArchiver archiveRootObject: sequencer toFile: path ];
    NS_HANDLER
        NSBeep();
        NSRunAlertPanel(@"Error Writing File", @"%@", @"OK", nil, nil, 
                localException);
        NS_VALUERETURN(nil,id);
    NS_ENDHANDLER

    if(!success)
    {
        NSBeep();
        NSRunAlertPanel(@"Error Writing File", @"%@", @"OK", nil, nil, 
                path);        
    }
    else
    {
        modified=NO;
    }
    
    return self;
}

- (void) newSequencer
{
    OutputChannel *channel;
    Part *part;
    MidiPort *port;
    NSNotificationCenter *nc=[ NSNotificationCenter defaultCenter ];

    // release old sequencer object
    if(sequencer)
    {
        [ nc removeObserver: self ];
    }
    [ sequencer release ];
    
    // forget old file name
    [ currentFilePath release ];
    currentFilePath=nil;
    
    // create a new sequencer object
    sequencer= [[ Sequencer alloc ] init ];
    [ sequencer setTempo: 120 ];
    [ sequencer setStepsPerBeat: 4 ];
    [ sequencer setTiming ];

    // create some parts, patterns and output channels
    channel=[[ OutputChannel alloc ] init ];
    [ channel setMidiChannel: 1 ];
    part=[ sequencer newPart ];
    [ part newPattern ];
    [ part setOutputChannel: channel ];

    channel=[[ OutputChannel alloc ] init ];
    [ channel setMidiChannel: 2 ];    
    part=[ sequencer newPart ];
    [ part newPattern ];    
    [ part setOutputChannel: channel ];
    
    channel=[[ OutputChannel alloc ] init ];
    [ channel setMidiChannel: 10 ];    
    part=[ sequencer newPart ];
    [ part newPattern ];    
    [ part setOutputChannel: channel ];

    // make it known to the other controllers
    [ scoreController setSequencer: sequencer ];
    [ parameterPanelController setSequencer: sequencer ];
    [ preferencesController setSequencer: nil ];
    // make sure the preferencesController has been called once
    // before accessing the defaults

    // create output port
    portIndex=[[ NSUserDefaults standardUserDefaults ] integerForKey: PSeqOutputPort ];
    if(portIndex>=[[ MidiPort availablePorts ] count ]) portIndex=0;
    port=[ MidiPort port: portIndex ];
    // and tell the sequencer object
    [ sequencer setPort: port ];
    [ preferencesController setSequencer: sequencer ];

    // create default parts and their output channels
    

    [ nc addObserver: self selector: @selector(stepChanged:)
                name: @"pseqStepChanged"
              object: nil ];
    [ nc addObserver: self selector: @selector(externallyEdited:)
                name: @"pseqEdited"
              object: nil ];
    
    [ self updateSequencerFields ];
}

- (BOOL) mayOpenFile
{
    int choice;

    if(modified)
    {
        choice=NSRunAlertPanel(@"Unsaved Changes",@"There are unsaved changes. Really open another file, "
                    "losing your changes?",
                    @"Cancel", @"Open", nil);
        if(choice==NSAlertDefaultReturn) return NO;
    }

    return YES;
}

- (IBAction) open: (id) sender
{
    NSOpenPanel *openPanel;
    
    if(![self mayOpenFile]) return;

    openPanel=[NSOpenPanel openPanel];
    
    [ openPanel beginSheetForDirectory: nil
        file: nil
        types: [ NSArray arrayWithObject: @"pseq" ]
        modalForWindow: mainWindow
        modalDelegate: self
        didEndSelector: @selector(openEnd:returnCode:contextInfo:)
        contextInfo: nil ];
}

- (void) openEnd: (NSOpenPanel *) sheet returnCode: (int) returnCode
    contextInfo: (void *) contextInfo
{
    NSString *path;
    
    if(returnCode!=NSOKButton) return;
    
    path=[ sheet filename ];

    dbgprintf("openEnd %s\n",[ path cString ]);
    [ path retain ];
    [ currentFilePath release ];
    currentFilePath=path;

    [ self load ];
}

- (IBAction) save: (id) sender
{
    if(!currentFilePath)
    {
        [ self saveAs: sender ];
        return;
    }
    
    dbgprintf("save %s\n", [ currentFilePath cString ]);
    [ self save ];
}

- (IBAction) saveAs: (id) sender
{
    NSSavePanel *savePanel=[ NSSavePanel savePanel ];
    
    [ savePanel beginSheetForDirectory: nil
        file: @"Unnamed.pseq"
        modalForWindow: mainWindow
        modalDelegate: self
        didEndSelector: @selector(saveEnd:returnCode:contextInfo:)
        contextInfo: nil
    ];
}

- (void) saveEnd: (NSSavePanel *) sheet returnCode: (int) returnCode
    contextInfo: (void *) contextInfo
{
    NSString *path;
    
    if(returnCode!=NSOKButton) return;
    
    path=[ sheet filename ];

    dbgprintf("saveEnd %s\n",[ path cString ]);
    [ path retain ];
    [ currentFilePath release ];
    currentFilePath=path;
    
    [ self save ];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [ mainWindow makeKeyAndOrderFront: self ];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    int choice;

    if(!modified) return YES;

    choice=NSRunAlertPanel(@"Unsaved Changes",@"There are unsaved changes. Really quit?",
            @"Cancel", @"Quit", nil);
    if(choice==NSAlertDefaultReturn)
    {
        return NO;
    }
    return YES;
}

- (IBAction) clean: (id) sender
{
    int choice;
    
    if(modified)
    {
        choice=NSRunAlertPanel(@"Unsaved Changes",@"There are unsaved changes. Really start a new document, "
                    "losing your changes?",
                    @"Cancel", @"New", nil);
        if(choice==NSAlertDefaultReturn) return;

        modified=NO;
    }

    [ self newSequencer ];
    [ self resetViews ];

    [ scoreController showWindow ];
    [ mainWindow makeKeyAndOrderFront: sender ];
    // [ mainWindow makeMainWindow ];
}

- (IBAction) octaveClicked: (id) sender
{
    id cell=[ sender selectedCell ];
    int tag=[ cell tag ];
    
    dbgprintf("octaveClicked: tag %d\n",tag);
    
    [ self changeOctave: tag ];
}

- (IBAction) editStepsClicked: (id) sender
{
    id cell=[ sender selectedCell ];
    int tag=[ cell tag ];
    
    dbgprintf("editStepsClicked: tag %d\n",tag);

    [ self changeStepRange: tag ];
}

- (IBAction) programFieldChanged: (id) sender
{
    int program=[ sender intValue ];
    
    dbgprintf("programFieldChanged value %d\n",program);
    
    [[ currentPart outputChannel ] changeProgram: program ];

    [ self setModified ];
}

- (IBAction) partMenuChanged: (id) sender
{
    int part=[ sender indexOfSelectedItem ];
    
    dbgprintf("partMenu indexOfSelectedItem %d\n",part);
    [ self selectPartAtIndex: part ];
}

- (IBAction) editModeChanged: (id) sender
{
    BOOL multi=[ sender intValue ];
    
    dbgprintf("editMode multi: %s\n", multi ? "YES" : "NO" );
    multiEdit=multi;
}

- (IBAction) bankFieldChanged: (id) sender
{
    int bank=[ sender intValue ];
    
    dbgprintf("bankFieldChanged value %d\n",bank);
    
    [[ currentPart outputChannel ] changeBank: bank ];

    [ self setModified ];
}

- (IBAction) patternMenuChanged: (id) sender
{
    int patternIndex=[ sender indexOfSelectedItem ];
    
    dbgprintf("patternMenu indexOfSelectedItem %d\n",patternIndex);
    [ self selectPatternAtIndex: patternIndex ];

}

- (IBAction) channelMenuChanged: (id) sender
{
    int channel=[ sender indexOfSelectedItem ];
    
    dbgprintf("channelMenuChanged value %d\n",channel);
    
    [[ currentPart outputChannel ] setMidiChannel: channel+1 ];

    [ self setModified ];
}

- (IBAction) portMenuChanged: (id) sender
{
    portIndex=[ sender indexOfSelectedItem ];
    
    dbgprintf("portMenu value %d\n",portIndex);
    
    [ sequencer setPort: [ MidiPort port: portIndex ]];
    [ preferencesController selectInputPort ];

    [[ NSUserDefaults standardUserDefaults ] setInteger: portIndex forKey: PSeqOutputPort ];

}

- (IBAction) patternLengthMenuChanged: (id) sender
{
    int index=[ sender indexOfSelectedItem ];
    int length;
    
    length=1 << (index+4);

    dbgprintf("patternLengthMenu value %d length:%d\n", index,length);
    
    [ currentPart setPatternLength: length ];
    currentPatternLength=length;

    [ self setModified ];
}

- (IBAction) tempoFieldChanged: (id) sender
{
    int tempo=[ sender intValue ];
    
    dbgprintf("tempoFieldChanged value %d\n",tempo);
    
    [ tempoStepper setIntValue: tempo ];

    [ self setModified ];
}

- (IBAction) tempoStepperChanged: (id) sender
{
    int tempo=[ sender intValue ];
    
    dbgprintf("tempoStepperChanged value %d\n",tempo);
    [ tempoField setIntValue: tempo ];
}

- (IBAction) stepsPerBeatMenuChanged: (id) sender
{
    int newSpb;
    int index=[ sender indexOfSelectedItem ];
    
    newSpb=[ self stepsPerBeatValue ];
    
    dbgprintf("stepsPerBeatMenuChanged index %d spb %d\n", index, newSpb);
    [ self updateSequencer ];
    [ sequencer rewind ];
    [ self setModified ];
    
}

- (IBAction) volumeSliderChanged: (id) sender
{
    int volume=[ sender intValue ];
    
    dbgprintf("volumeSliderChanged value %d\n",volume);
    
    [[ currentPart outputChannel ] changeVolume: volume ];

    [ self setModified ];
}

- (IBAction) velocitySliderChanged: (id) sender
{
    int velocity=[ sender intValue ];
    
    if([ self selectedNote]!=nil)
    {
        [ self setVelocityOnSelection: velocity ];
    }
    else
    {
        currentVelocity=velocity;
    }
}

- (IBAction) renamePartClicked: (id) sender
{
    [ renameController setLabelText: @"Rename Part:" ];
    [ renameController setName: [ currentPart name ]];
    [ renameController setDoneSelector: @selector(partRenamed) ];
    [ renameController setDisallowedNames: [ sequencer parts ]];
    [ renameController beginSheet ];
}

- (IBAction) newPartClicked: (id) sender
{
    Part *newPart;
    int count;

    count=[[sequencer parts ] count ];

    if(count>=MAX_PARTS) return;

    newPart=[ sequencer newPart ];
    [ newPart newPattern ];
    [ self updatePartsMenu ];
    [ scoreController addPart: count ];
    
    // select and show new part
    [ partsMenu selectItemAtIndex: count ];
    [ self selectPartAtIndex: count ];

    [ self setModified ];    
}

- (IBAction) deletePartClicked: (id) sender
{
    int index;
    int count;
    
    count=[[sequencer parts ] count ];
    index=[ partsMenu indexOfSelectedItem ];

    dbgprintf("deletePartClicked: deleting index %d of %d\n", index,count);

    if(count==1) return;

    [ sequencer deletePartAtIndex: index ];

    [ scoreController removePart: index ];

    // select previous entry and update the menu
    if(index>0) index--;
    [ partsMenu selectItemAtIndex: index ];
    [ self updatePartsMenu ];
    [ self selectPartAtIndex: index ];
}

- (IBAction) renamePatternClicked: (id) sender
{
    [ renameController setLabelText: @"Rename Pattern:" ];
    [ renameController setName: [ currentPattern name ]];
    [ renameController setDoneSelector: @selector(patternRenamed) ];
    [ renameController setDisallowedNames: [ currentPart patterns ]];
    [ renameController beginSheet ];
}

- (IBAction) newPatternClicked: (id) sender
{
    int index;

    if(![ self canAddPattern ]) return;

    index=[ currentPart newPattern ];
    [ self updatePatternsMenu ];
    
    // show new pattern
    [ patternsMenu selectItemAtIndex: index ];
    [ self selectPatternAtIndex: index ];

    [ self setModified ];
}

- (IBAction) deletePatternClicked: (id) sender
{
    int index;
    int count;
    
    count=[[currentPart patterns ] count ];
    index=[ patternsMenu indexOfSelectedItem ];

    dbgprintf("deletePatternClicked: deleting index %d of %d\n", index,count);

    if(count==1) return;

    [ currentPart removePatternAtIndex: index ];
    [ scoreController pattern: index
        removedFromPart: [ partsMenu indexOfSelectedItem ] ];
    // select previous entry and update the menu
    if(index>0) index--;
    [ patternsMenu selectItemAtIndex: index ];
    [ self selectPatternAtIndex: index ];
    [ self updatePatternsMenu ];

    [ self setModified ];
}

- (IBAction) songModeClicked: (id) sender
{
    BOOL songMode=[ sender intValue ]!=0;
    
    [ sequencer setSongMode: songMode ];
    [ autoRewindButton setEnabled: !songMode ];

    dbgprintf("setSongMode: %d\n", (int) songMode);
}

- (IBAction) autoRewindClicked: (id) sender
{
    BOOL autoRewind=[ sender intValue ]!=0;
    
    [ sequencer setAutoRewind: autoRewind ];
}

- (IBAction) matrixModeChanged: (id) sender
{
    id cell=[ sender selectedCell ];
    int tag=[ cell tag ];
    
    dbgprintf("matrixMode: %d\n", (int) tag);    
}

- (IBAction) muteButtonClicked: (id) sender
{
    BOOL mute=[ sender intValue ]!=0;
    
    //[ sequencer setSongMode: songMode ];
    dbgprintf("mute: %d\n", (int) mute);
    
    [ currentPart setMute: mute ];
}

- (IBAction) duplicateEditPattern: (id) sender
{
    int index;
    
    if(![ self canAddPattern ]) return;

    index=[ currentPart duplicateEditPattern ];
    [ self updatePatternsMenu ];

    // show new pattern
    [ patternsMenu selectItemAtIndex: index ];
    [ self selectPatternAtIndex: index ];

    [ self setModified ];
}

- (IBAction) deleteNoteClicked: (id) sender
{
    Note *note=[ self selectedNote ];
    int step=[ matrix stepFromColumn: [ patternView selectedColumn ]];
    
    [ currentPattern clearNote: note atStep: step ];

    [ patternView deselect ];
    [ matrix reload ];
    [ patternView setNeedsDisplay: YES ];
    [ self setModified ];
}

- (void) partRenamed
{
    NSString *newName;
    int index=[ partsMenu indexOfSelectedItem ];
    
    newName=[ renameController name ];
    if(newName==nil) return;
    
    [ currentPart setName: newName ];
    [ self updatePartsMenu ];

    [ scoreController updatePart: index ];

    [ self setModified ];
}

- (void) patternRenamed
{
    NSString *newName;
    
    newName=[ renameController name ];
    if(newName==nil) return;
    
    [ currentPattern setName: newName ];
    [ self updatePatternsMenu ];

    [ self setModified ];
}

- (void) tick: (id) anId
{
    [ self updateIndicator ];
}

- (void) updateIndicator
{
    int x;
    
    x= [ sequencer realtimeStep ];
    x &= (currentPatternLength-1);
    x= x-[ matrix startColumn ];
    if(x<0 || x> [ matrix columns]) x=-1;
    [ patternView setIndicator:  x ];
}

- (void) updatePartButtons
{
    int count;
    BOOL running=[ sequencer isRunning ];

    count=[[ sequencer parts ] count ];
    [ newPartButton setEnabled: (!running && count<MAX_PARTS) ? YES : NO ];
    [ deletePartButton setEnabled: (!running && count>1) ? YES : NO ];

}

- (void) updatePartsMenu
{
    int index;
    
    index=[ partsMenu indexOfSelectedItem ];
    [ self updateMenu: partsMenu from: [ sequencer parts ] ];
    [ partsMenu selectItemAtIndex: index ];

    [ self updatePartButtons ];
}

- (void) updatePatternButtons
{
    int count;
    BOOL running=[ sequencer isRunning ];

    count=[[ currentPart patterns ] count ];
    
    [ newPatternButton setEnabled: (!running && count<MAX_PATTERNS) ? YES : NO ];
    [ deletePatternButton setEnabled: (!running && count>1)  ? YES : NO ];    
}

- (void) updatePatternsMenu
{
    int index;
    
    index=[ currentPart editPatternIndex ];
    [ self updateMenu: patternsMenu from: [ currentPart patterns ]];
    [ patternsMenu selectItemAtIndex: index ];
    
    [ self updatePatternButtons ];

    [ scoreController updatePart: [ partsMenu indexOfSelectedItem ] ];
}

- (void) updatePortsMenu
{
    NSArray *ports;
    id e,o;

    [ portsMenu removeAllItems ];

    ports=[ MidiPort availablePorts ];
    e=[ ports objectEnumerator ];
    while(o=[ e nextObject ])
    {
        [ portsMenu addItemWithTitle: o ];
        dbgprintf("portsMenu: %s\n", [ o cString ]);
    }
    
    [ portsMenu selectItemAtIndex: portIndex ];
}

- (void) updateMenu: menu from: collection
{
    id e,o;
    id name;
    
    [ menu removeAllItems ];

    e=[ collection objectEnumerator ];
    while(o=[ e nextObject ])
    {
        name=[ o name ];
        if(!name) name=[ NSString stringWithString: @"(unnamed)" ];
        dbgprintf("updateMenu:from: %s\n",  [ name cString ]);
        [ menu addItemWithTitle: name ];
    }
}

- (void) updateButtons
{
    BOOL running=[ sequencer isRunning ];

    [ self updatePartButtons ];
    [ self updatePatternButtons ];

    //[ startButton setTitle: running ? @"Stop" : @"Start" ];
    [ startButton setEnabled: !running ];
    [ stepRecordButton setEnabled: !running ];
    [ stopButton setEnabled: running ];
    [ songModeButton setEnabled: !running ];
    [ autoRewindButton setEnabled: ![ sequencer songMode ] && !running ];
    [ stepsPerBeatMenu setEnabled: !running ];
    [ portsMenu setEnabled: !running ];
}

- (void) updateSequencerFields
{
    NSString *wantedTitle;

    int tempo=[ sequencer tempo ];
    dbgprintf("sequencer tempo %d\n",tempo);

    [ tempoField setIntValue: tempo ];
    [ tempoStepper setIntValue: tempo ];
    [ velocitySlider setIntValue: currentVelocity ];
    
    [ songModeButton setIntValue: [ sequencer songMode ] ? 1 : 0 ];
    [ autoRewindButton setIntValue: [ sequencer autoRewind ] ? 1 : 0 ];
    // steps per beat...

    wantedTitle=[ NSString stringWithFormat: @"%d",[ sequencer stepsPerBeat ]];
    
    [ stepsPerBeatMenu selectItemWithTitle: wantedTitle ];
}

- (void) updatePartFields
{
    id channel=[ currentPart outputChannel ];
    int midiChannel=[ channel midiChannel ];
    int index;
    
    index=lengthToIndex([ currentPart patternLength ]);
    dbgprintf("patternLength index: %d\n",index);

    [ programField setIntValue: [ channel lastProgram ]];
    [ bankField setIntValue: [ channel lastBank ]];
    [ volumeSlider setIntValue: [ channel lastVolume ]];
    [ patternLengthMenu selectItemAtIndex: index ];
    [ muteButton setIntValue: [ currentPart mute ]];
    if(midiChannel<1 || midiChannel>16) return;
    [ channelMenu selectItemAtIndex: midiChannel-1 ];
}

- (void) enableVelocityEdit
{
    [ patternView setSelectionEnabled: YES ];
    [ velocitySlider setEnabled: NO ];
    [ self updateMessageField ];
}

- (void) disableVelocityEdit
{
    [ patternView setSelectionEnabled: YES ];
    [ velocitySlider setEnabled: YES ];
    [ velocitySlider setIntValue: currentVelocity ];
}

- (Note *) selectedNote
{
    int x,y,key,step;

    x=[ patternView selectedColumn ];
    y=[ patternView selectedRow ];
    
    key=[ matrix keyNumberFromRow: y ];
    step=[ matrix stepFromColumn: x ];
    return [ currentPattern noteForKey: key atStep: step ];
}

- (Part *) selectedPart
{
    return currentPart;
}

- (Sequencer *) sequencer
{
    return sequencer;
}

- (void) setVelocityOnSelection: (int) velocity
{
    int step;
    Note *old;
    Note *new;
    
    step=[ matrix stepFromColumn: [ patternView selectedColumn ]];

    old=[ self selectedNote ];
    new=[ Note key: [ old keyNumber ] duration: [ old duration ] velocity: velocity ];
    [ currentPattern setNote: new atStep: step multi: YES];
    
    [ matrix loadColumn: [ patternView selectedColumn ]];
    [ patternView redisplayRow: [ patternView selectedRow ]];
}

- (void) stepClicked: (int) x;
{
    x=[ matrix stepFromColumn: x ];
    dbgprintf("stepClicked: %d\n",x);
    if([ sequencer setStep: x ])
    {
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqStepChanged" object: sequencer ];
        //[ self updateIndicator ];
    }
}

- (void) stepChanged: (NSNotification *) note
{
    [ self updateIndicator ];
}

- (void) externallyEdited: (NSNotification *) note
{
    [ self updateIndicator ];
    [ matrix reload ];
    [ self setModified ];
    [ patternView setNeedsDisplay: YES ];
}


- (void) editNoteAt: (int) x : (int) y clear: (BOOL) clearFlag
{
    int key,step;
    Note *note;

    // create new note
    key= [ matrix keyNumberFromRow: y ];
    step = [ matrix stepFromColumn: x ];
    note=[ Note key: key duration: 1 velocity: currentVelocity ];

    // show note name in message field
    [ self setMessageFieldNote: note step: step ];

    dbgprintf("%s (%d) step %d\n clearFlag:\n",
        [[ Note nameForKeyNumber: key ] lossyCString ], key,
        step,  (int) clearFlag);

    if(!clearFlag)
    {
        [ currentPattern setNote: note atStep: step multi: multiEdit ];
        if(!multiEdit) [ matrix clearColumn: x ];

        if(![ sequencer isRunning ])
            [ currentPart auditionStep: step duration: 1.0 ];
    }
    else
    {
        [ currentPattern clearNote: note atStep: step ];
        [ matrix clearNoteAt: x : y ];
    }
    
    [ matrix loadColumn: x ];

    [ patternView setNeedsDisplay: YES ];
    
    [ self setModified ];
}

- (void) endClick
{   
    // if mouse was not dragged and cell was not emtpy, clear it on mouse release
    //if(!wasDragged && !clickedCellWasEmpty && noteStartClicked)
    //{
    //    [ self editNoteAt: dragStartColumn : dragStartRow clear: YES ]; 
    //}
    
    dragStartStep=-1;
    dragStartColumn=-1;
}

- (void) cellClickedAt: (int) x : (int) y
{
    int key,step;
    CellType oldType;
    int noteStart;
    
    oldType=[ matrix cellAtX: x y: y ];

    // if the clicked cell is empty, create a note
    if(oldType==Empty)
    {
        clickedCellWasEmpty=YES;
        [ self editNoteAt: x : y clear: NO ];
        dragMode=DRAG_MODE_RESIZE;
    }
    else
    {
    // pretend the click was at the start of the note
        clickedCellWasEmpty=NO;
        if(oldType==End)
            dragMode=DRAG_MODE_RESIZE;
        else
            dragMode=DRAG_MODE_MOVE;

        noteStart=[ matrix findStartOfX: x y: y ];
        x=noteStart;
    }
    
    key= [ matrix keyNumberFromRow: y ];
    step = [ matrix stepFromColumn: x ];

    // remember clicked cell as starting point for dragging
    dragStartStep=step;
    dragStartColumn=x;
    dragStartKey=key;
    dragStartRow=y;
    dragCurrentStep=step;
    wasDragged=NO;
}

- parametersChanged
{
    [ self setModified ];
    [ patternView setNeedsDisplay: YES ];
    return self;
}

- (void) cellDraggedAt: (int) x : (int) y
{
    int key,step;
    Note *note;
    int length;
    int b;
    int velocity;
    
    // if we have no valid starting point for the drag operation,
    // ignore it
    if(dragMode==DRAG_MODE_NONE) return;
    
    switch(dragMode)
    {
        case DRAG_MODE_MOVE:
            // TO BE IMPLEMENTED
            break;
        case DRAG_MODE_RESIZE:
            
            // resize note 
            // abort drag when dragging into an occupied cell
            
            for(b=dragStartColumn;b<=x;b++)
            {
                if( [ matrix cellAtX: b y: dragStartRow ] != Empty &&
                    [ matrix findStartOfX: b y: dragStartRow ] != dragStartColumn)
                {
                    [ self endClick ];
                    return;
                }
            }
            
            key= [ matrix keyNumberFromRow: dragStartRow ];
            step = [ matrix stepFromColumn: x ];
            
            length=step-dragStartStep;
            
            if(length<0) return;
                
                length=length+1;
            
            // if still dragging in the same cell as before, ignore it
            
            if(step==dragCurrentStep) return;
                
                wasDragged=YES;
            
            dbgprintf("drag length: %d\n",length);
            
            velocity=[[ currentPattern noteForKey: key atStep: dragStartStep ] velocity ];
            note=[ Note key: dragStartKey duration: length velocity: velocity ];
            
            [ currentPattern setNote: note atStep: dragStartStep multi: multiEdit ];
            
            default:
                // should not happen
                break;
    }

    [ matrix clearNoteAt: dragStartColumn : dragStartRow ];
    [ matrix loadColumn: dragStartColumn ];
    
    [ patternView setNeedsDisplay: YES ];
    
    dragCurrentStep=step;
}

- (void) updateMessageField
{
    [ self setMessageFieldNote: [ self selectedNote ] step: selectedStep ];
}

- (void) clearMessageField
{
    [ messageField setStringValue: @"" ];
}

- (void) setMessageFieldNote: (Note *)n step: (int) step
{
    NSString *msg;
    if(!n || step<0)
    {
        [ self clearMessageField ];
        return;
    }
    else
    {
        msg=[ NSString stringWithFormat: @"%@ step %d",[ n keyName ],step+1 ];
        [ messageField setStringValue: msg ];
    }
}

- (void) cellSelected
{
    Note *n=[ self selectedNote ];
    selectedStep=[ matrix stepFromColumn: [ patternView selectedColumn ]];
    [ velocitySlider setIntValue: [ n velocity ]];
    [ velocitySlider setEnabled: YES ];
    [ self updateMessageField ];
}

- (void) cellDeselected
{
    [ velocitySlider setEnabled: NO ];
    selectedStep=-1;
    [ self updateMessageField ];
}

- (void) changeOctave: (int) anInt
{
    int startLine;

    currentOctave=anInt;

    anInt += LOWEST_OCTAVE;

    startLine=anInt*12-1;
    
    if(startLine<0) startLine=0;
    
    [ matrix setStartLine: startLine ];
    [ matrix loadColumns ];
    
    [ self updateMessageField ];
    [ patternView deselect ];
    [ patternView setNeedsDisplay: YES ];
    
}

- (void) changeStepRange: (int) anInt
{
    int startStep;

    currentStepRange=anInt;
    
    startStep=anInt*32;
    
    [ matrix setStartColumn: startStep ];
    [ matrix loadColumns ];
    [ self updateIndicator ];
    [ self updateMessageField ];
    [ patternView deselect ];
    [ patternView setNeedsDisplay: YES ];
}

- (void) selectPartAtIndex: (int) anInt
{
    currentPart=[ sequencer partAtIndex: anInt ];
    currentPattern=[ currentPart editPattern ];
    currentPatternIndex=[ currentPart editPatternIndex ];
    currentPatternLength=[ currentPart patternLength ];

    dbgprintf("currentPart %p octave %d length%d\n", currentPart, currentOctave,
        currentPatternLength);
    
    [ sequencer selectEditPartAtIndex: anInt ];
    
    if(matrix) [ matrix release ];
    matrix= [[ PatternMatrix alloc] init ];
    [ matrix setPattern: currentPattern ];
    [ matrix loadColumns ];
    //[ matrix print ];
    [ patternView setPatternMatrix: matrix ];

    [ self changeOctave: currentOctave ];
    [ self changeStepRange: currentStepRange ];
    [ self updatePatternsMenu ];
    [ self updatePartFields ];

    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqPatternChanged" object: sequencer ];
}

- (void) selectPatternAtIndex: (int) anInt
{
    currentPattern=[ currentPart selectEditPattern: anInt ];
    if(![ sequencer isRunning ]) [ currentPart selectPattern: anInt ];
    currentPatternIndex=anInt;

    dbgprintf("currentPattern %p octave %d\n", currentPattern, currentOctave);
    
    if(matrix) [ matrix release ];
    matrix= [[ PatternMatrix alloc] init ];
    [ matrix setPattern: currentPattern ];
    [ matrix loadColumns ];
    //[ matrix print ];
    [ patternView setPatternMatrix: matrix ];
    [ self changeOctave: currentOctave ];
    [ self changeStepRange: currentStepRange ];

    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: @"pseqPatternChanged" object: sequencer ];

}

@end
