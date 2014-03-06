/* SequencerController */
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

#import <Cocoa/Cocoa.h>
#import "Sequencer.h"
#import "RenameController.h"
#import "Note.h"
#import "Part.h"
#import "SeqPattern.h"

@interface SequencerController : NSObject
{
    IBOutlet id mainWindow;
    IBOutlet id patternView;
    IBOutlet id textField;
    IBOutlet id partsMenu;
    IBOutlet id patternsMenu;
    IBOutlet id portsMenu;
    IBOutlet id programField;
    IBOutlet id bankField;
    IBOutlet id channelMenu;
    IBOutlet id volumeSlider;
    IBOutlet id stepsPerBeatMenu;
    IBOutlet id patternLengthMenu;
    IBOutlet id tempoField;
    IBOutlet id tempoStepper;
    IBOutlet id newPartButton;
    IBOutlet id deletePartButton;
    IBOutlet id newPatternButton;
    IBOutlet id deletePatternButton;
    IBOutlet Sequencer *sequencer;
    IBOutlet RenameController *renameController;
    IBOutlet id scoreController;
    IBOutlet id parameterPanelController;
    IBOutlet id preferencesController;
    IBOutlet id songModeButton;
    IBOutlet id autoRewindButton;
    IBOutlet id startButton;
    IBOutlet id stopButton;
    IBOutlet id stepRecordButton;
    IBOutlet id octaveMatrix;
    IBOutlet id velocitySlider;
    IBOutlet id muteButton;
    IBOutlet id matrixModeMenu;
    IBOutlet id messageField;
    IBOutlet id deleteNoteButton;

    NSTimer *timer;
    
    NSString *currentFilePath;

    SeqPattern *currentPattern;
    Part *currentPart;
    int currentPatternIndex;
    id matrix;
    int currentPatternLength;
    int currentVelocity;
    int portIndex;

    int selectedStep;
    int dragStartStep;
    int dragStartColumn;
    int dragCurrentStep;
    int dragStartKey;
    int dragStartRow;
    int dragMode;
    BOOL wasDragged;
    BOOL clickedCellWasEmpty;
    BOOL noteStartClicked;

    BOOL multiEdit;
    int currentOctave;
    int currentStepRange;
    BOOL modified;
    BOOL stepRecording;
}

- (void) awakeFromNib;
- (void) dealloc;

- (IBAction) open: (id) sender;
- (IBAction) save: (id) sender;
- (IBAction) saveAs: (id) sender;
- (IBAction) clean: (id) sender;

- (void) saveEnd: (NSSavePanel *) sheet returnCode: (int) returnCode
    contextInfo: (void *) contextInfo;
    
- (int) stepsPerBeatValue;
- (void) updateSequencer;
- load;
- save;
- (void) newSequencer;

- (IBAction)start:(id)sender;
- (IBAction) songModeClicked: (id) sender;
- (IBAction) muteButtonClicked: (id) sender;
- (IBAction) octaveClicked: (id) sender;
- (IBAction) editStepsClicked: (id) sender;
- (IBAction) programFieldChanged: (id) sender;
- (IBAction) bankFieldChanged: (id) sender;
- (IBAction) partMenuChanged: (id) sender;
- (IBAction) patternMenuChanged: (id) sender;
- (IBAction) editModeChanged: (id) sender;
- (IBAction) matrixModeChanged: (id) sender;
- (IBAction) velocitySliderChanged: (id) sender;
- (IBAction) channelMenuChanged: (id) sender;
- (IBAction) volumeSliderChanged: (id) sender;
- (IBAction) portMenuChanged: (id) sender;
- (IBAction) tempoFieldChanged: (id) sender;
- (IBAction) tempoStepperChanged: (id) sender;
- (IBAction) stepsPerBeatMenuChanged: (id) sender;
- (IBAction) patternLengthMenuChanged: (id) sender;

- (IBAction) renamePartClicked: (id) sender;
- (IBAction) newPartClicked: (id) sender;
- (IBAction) deletePartClicked: (id) sender;

- (IBAction) renamePatternClicked: (id) sender;
- (IBAction) newPatternClicked: (id) sender;
- (IBAction) deletePatternClicked: (id) sender;

- (IBAction) duplicateEditPattern: (id) sender;
- (IBAction) deleteNoteClicked: (id) sender;
- (void) tick: (id) anId;

- (void) stepClicked: (int) x;
- (void) cellClickedAt: (int) x : (int) y;
- (void) cellDraggedAt: (int) x : (int) y;
- (void) endClick;
- (void) cellSelected;
- (void) cellDeselected;

- (void) changeOctave: (int) anInt;
- (void) changeStepRange: (int) anInt;
- (void) selectPartAtIndex: (int) anInt;
- (void) selectPatternAtIndex: (int) anInt;

- (void) resetViews;
- (void) updateMenu: menu from: collection;
- (void) updatePartsMenu;
- (void) updatePatternsMenu;
- (void) updatePortsMenu;
- (void) updatePartFields;
- (void) updateSequencerFields;
- (void) updateIndicator;
- (void) updatePartButtons;
- (void) updatePatternButtons;
- (void) updateButtons;
- (void) updateMessageField;
- (void) clearMessageField;
- (void) setMessageFieldNote: (Note *)n step: (int) step;

- (void) setVelocityOnSelection: (int) velocity;
- (void) enableVelocityEdit;
- (void) disableVelocityEdit;

- (BOOL) mayOpenFile;
- (BOOL) canAddPattern;
- (BOOL) modified;
- setModified;

- (Part *) selectedPart;
- (Sequencer *) sequencer;
- (Note *) selectedNote;

- parametersChanged;
- patternAdded: (int) index;
- loadPatternFromPath: (NSString *) path;
- savePatternToPath: (NSString *) path;
- (IBAction) loadPattern: (id) sender;
- (void) loadPatternEnd: (NSOpenPanel *) sheet returnCode: (int) returnCode
    contextInfo: (void *) contextInfo;
- (BOOL) application: (NSApplication *) app openFile: (NSString *) filename;
- (void) stepChanged: (NSNotification *) note;

@end
