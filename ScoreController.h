//
//  ScoreController.h
//  PatternSequencer
//
//  Created by Sebastian Lederer on Mon Oct 27 2003.
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


@interface ScoreController : NSObject {
    IBOutlet id tableView;
    IBOutlet id scoreWindow;
    IBOutlet id sequencerController;
    IBOutlet id upButton;
    IBOutlet id downButton;
    IBOutlet id removeButton;
    IBOutlet id newButton;

    id sequencer;
    int partsCount;
}

- (void) awakeFromNib;

- setSequencer:anId;
- sequencer;

- (IBAction) upClicked: sender;
- (IBAction) downClicked: sender;
- (IBAction) newClicked: sender;
- (IBAction) removeClicked: sender;
- (IBAction) tableRowClicked: (id) sender;

- sequencerStarted;
- sequencerStopped;

- updateButtons;

- createColumns;
- removePart: (int) partIndex;
- addPart: (int) partIndex;

- createMenuCellFrom: aCollection;
- createMenuCells;
- addColumnForPart: (int) partIndex;
- createMenuCellForPart: (int) partIndex;

- showWindow;

- pattern:(int) patternIndex removedFromPart: (int) partIndex;
- updateHeaders;

- updatePart: (int) partIndex;


- (int) numberOfRowsInTableView: (NSTableView *) aTableView;
- (id) tableView: (NSTableView *) aTableView
    objectValueForTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex;
    
- (void) tableView: (NSTableView *) aTableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex;

- (void)tableViewSelectionDidChange:(NSNotification *) aNotification;

@end
