/* ParameterPanelController */
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

#import "ParameterChange.h"
#import "SeqPattern.h"
#import "Sequencer.h"

@interface ParameterPanelController : NSObject
{
    IBOutlet id ccButton;
    IBOutlet id ccNoField;
    IBOutlet id ccValueField;
    IBOutlet id pcButton;
    IBOutlet id pcValueField;
    IBOutlet id stepField;
    IBOutlet id sequencerController;
    IBOutlet id smoothButton;
    IBOutlet id endValueField;
    IBOutlet id pitchButton;
    IBOutlet id pitchNextButton;
    IBOutlet id ccNextButton;
    IBOutlet id pitchMatrix;

    Sequencer *sequencer;

    SeqPattern *pattern;
    int step;
    ParameterChange *parameters;
}

- (void) dealloc;

- (IBAction)ccButtonClicked:(id)sender;
- (IBAction)ccNoChanged:(id)sender;
- (IBAction)ccValueChanged:(id)sender;
- (IBAction)pcButtonClicked:(id)sender;
- (IBAction)pcValueChanged:(id)sender;
- (IBAction)endValueChanged: (id) sender;
- (IBAction)smoothButtonClicked: (id) sender;
- (IBAction)ccNextClicked: (id) sender;
- (IBAction)pitchMatrixClicked: (id) sender;
- (IBAction)pitchNextClicked: (id) sender;
- (IBAction)pitchButtonClicked: (id) sender;

- (void) loadStepParameters: (int) x;
- (void) updateButtons;
- (void) updateFields;
- (void) updateParameters;
- (void) enableFields;

- (void) patternChanged: (NSNotification *) note;
- (void) stepChanged: (NSNotification *) note;
- (void) partAdded: (NSNotification *) note;
- (void) partDeleted: (NSNotification *) note;
- (void) patternAdded: (NSNotification *) note;
- (void) patternDeleted: (NSNotification *) note;

- (id)sequencer;
- (void)setSequencer:(id)newSequencer;
- (id)pattern;
- (void)setPattern:(id)newPattern;
- (int)step;
- (void)setStep:(int)newStep;

@end
