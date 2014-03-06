//
//  ScoreController.m
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

#import "ScoreController.h"
#import "SequencerController.h"
#import "Sequencer.h"
#import "Block.h"

#include "debug.h"

#define START_COLUMN 2
#define MAX_BLOCKS 20

@implementation ScoreController

- setSequencer:anId
{
    sequencer=anId;
    return self;
}

- sequencer
{
    return sequencer;
}

- (void) awakeFromNib
{
    //[ self updateParts ];
    [ self updateButtons ];
}

- sequencerStarted
{
    [ self updateButtons ];
    
    return self;
}

- sequencerStopped
{
    [ self updateButtons ];
    
    return self;
}

- (BOOL) windowShouldClose: (id) sender
{
    return YES;
}

- showWindow
{
    [ scoreWindow orderFront: self ];
    return self;
}

- (IBAction) upClicked: sender
{
    int row=[ tableView selectedRow ];
    
    if(row<0) return;
    
    [ sequencer moveBlockFrom: row to: row-1 ];
    [ tableView reloadData ];
    [ tableView selectRow: row-1 byExtendingSelection: NO ];
    [ sequencerController setModified ];
}

- (IBAction) downClicked: sender
{
    int row=[ tableView selectedRow ];
    
    if(row<0) return;
    
    [ sequencer moveBlockFrom: row to: row+1 ];
    [ tableView reloadData ];
    [ tableView selectRow: row+1 byExtendingSelection: NO ];
    [ sequencerController setModified ];
}

- (IBAction) newClicked: sender
{
    [ sequencer newBlock ];
    [ self updateButtons ];
    [ tableView reloadData ];
    [ sequencerController setModified ];
}

- (IBAction) removeClicked: sender
{
    int row=[ tableView selectedRow ];
    int count=[[ sequencer blocks ] count ];

    if(row<0 || row>=count) return;
    
    if(count<=1) return;

    [ sequencer removeBlock: row ];
    [ self updateButtons ];
    [ tableView reloadData ];
}
- updateButtons
{
    int row=[ tableView selectedRow ];
    int count=[ [ sequencer blocks ] count ];
    BOOL running=[ sequencer isRunning ];

    [ upButton setEnabled: (!running && row>0) ? YES: NO ];
    [ downButton setEnabled: (!running && row >= 0 && row!=count-1) ? YES: NO ];
    [ newButton setEnabled: (!running && count<MAX_BLOCKS) ? YES : NO ];
    [ removeButton setEnabled: (!running && row>=0 && count>1) ? YES : NO ];

    return self;
}


- removePart: (int) partIndex
{
    NSTableColumn *col;
    NSArray *columns=[ tableView tableColumns ];

    col=[ columns objectAtIndex: START_COLUMN + partIndex ];
    [ tableView removeTableColumn: col ];
    [ self updateHeaders ]; //  need to update identifiers
    partsCount--;
    return self;
}

- addPart: (int) partIndex
{
    [ self addColumnForPart: partIndex ];
    partsCount++;
    return self;
}

- updatePart: (int) partIndex
{
    [ self createMenuCellForPart: partIndex ];
    [ self updateHeaders ];
    return self;
}

- pattern:(int) patternIndex removedFromPart: (int) partIndex
{
    Block *block;
    id e;
    int oldIndex;

// when a pattern is removed, all pattern indices must be adjusted
// accordingly

    e=[[ sequencer blocks ] objectEnumerator ];
    
    while(block=[ e nextObject ])
    {
            oldIndex=[ block patternForPart: partIndex ];
            if(oldIndex>0 && oldIndex>=patternIndex)
            {
                [ block setPattern: oldIndex-1 forPart: partIndex ];
            }
    }
    return self;
}

- createColumns
{
    int i;
    int newPartsCount=[[ sequencer parts ] count ];
    NSTableColumn *col;
    NSArray *columns;

    // some parts have been added
    if(newPartsCount>partsCount)
    {
        for(i=0;i<partsCount;i++)
            [ self createMenuCellForPart: i ];

        for(i=partsCount;i<newPartsCount;i++)
            [ self addColumnForPart: i ];
    }
    // some parts have been removed
    else if(newPartsCount<partsCount)
    {
    
        for(i=0;i<newPartsCount;i++)
            [ self createMenuCellForPart: i ];

        columns=[ tableView tableColumns ];
        for(i=partsCount-1;i>=newPartsCount;i--)
        {
            col=[ columns objectAtIndex: START_COLUMN+i ];
            [ tableView removeTableColumn: col ];
        }
    }
    else
    {
        // number of columns stayed the same
        for(i=0;i<partsCount;i++)
            [ self createMenuCellForPart: i ];
    }
    //[ self updateHeaders ];
    partsCount=newPartsCount;
    [ tableView reloadData ];
    return self;
}

- updateHeaders
{
    NSArray *columns;
    Part *part;
    NSTableColumn *col;
    NSString *identifier;

    id e,e2;
    int i;
    
    columns=[ tableView tableColumns ];
    e=[[ sequencer parts ] objectEnumerator ];
    e2=[ columns objectEnumerator ];
    for(i=0;i<START_COLUMN;i++) [ e2 nextObject ];

    i=0;
    while( part=[ e nextObject ] )
    {
            col=[ e2 nextObject ];
            identifier=[ NSString stringWithFormat: @"%d", i++ ];                        
            [[ col headerCell ] setStringValue: [ part name ]];
            [ col setIdentifier: identifier ];
            
            //[ col sizeToFit ];
    }
    
    [[ tableView headerView ] setNeedsDisplay: YES ];
    return self;
}

- addColumnForPart: (int) partIndex
{
    NSTableColumn *column;
    NSPopUpButtonCell *cell;
    NSString *identifier=[ NSString stringWithFormat: @"%d", partIndex ];
    Part *part=[ sequencer partAtIndex: partIndex ];
    
    column=[[ NSTableColumn alloc ] initWithIdentifier: identifier ];
    [ column autorelease ];
    [ column setResizable: NO ];

    cell=[ self createMenuCellFrom: [ part patterns ]];
    [ column setDataCell: cell ];
    [[ column headerCell ] setStringValue: [ part name ]];
    [ tableView addTableColumn: column ];
    
    return self;
}

- createMenuCellForPart: (int) partIndex
{
    NSTableColumn *column;
    NSPopUpButtonCell *cell;
    Part *part=[ sequencer partAtIndex: partIndex ];
    
    column=[[ tableView tableColumns ]
        objectAtIndex: START_COLUMN + partIndex ];

    cell=[ self createMenuCellFrom: [ part patterns ]];
    [[ column headerCell ] setStringValue: [ part name ]];
    [ column setDataCell: cell ];
    
    return self;
}

- createMenuCellFrom: collection
{
    id e,o;
    id name;
    NSPopUpButtonCell *cell;
    
    cell = [[[NSPopUpButtonCell alloc] init] autorelease];
    
    e=[ collection objectEnumerator ];
    while(o=[ e nextObject ])
    {
        name=[ o name ];
        if(!name) name=[ NSString stringWithString: @"(unnamed)" ];
        [ cell addItemWithTitle: name ];
    }

    [ cell setBordered: NO];

    return cell;
}

- createMenuCells
{
    int i;
    
    partsCount=[ [ sequencer parts ] count ];
    
    for(i=0;i<partsCount;i++) [ self createMenuCellForPart: i ];

    return self;
}

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
    return [ [ sequencer blocks ] count ];
}

- (id) tableView: (NSTableView *) aTableView
    objectValueForTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex
{
    // NSString *s;
    NSString *colName;
    Block *block;
    int partIndex;
    int n;

    colName=[ aTableColumn identifier ];
    block= [ sequencer blockAtIndex: rowIndex ];
    
    if( [ colName isEqual: @"L" ])
    {
        return [ NSNumber numberWithInt: [ block length ] ];
    }

    if([ colName isEqual: @"N" ])
    {
        return [ block name ];
    }

    partIndex=[ colName intValue ];

    //s=[ NSString stringWithFormat: @"%d, %s", rowIndex, [ colName cString ]];
    //return s;
    if(partIndex<0 || partIndex>=partsCount )
        n=0;
    else
        n=[ block patternForPart: partIndex ];
        
    return [ NSNumber numberWithInt: n ];
}

- (IBAction) tableRowClicked: (id) sender
{
    // dbgprintf("row %d clicked\n", [ tableView selectedRow ]);
    [ sequencer switchToBlockAtIndex: [ tableView selectedRow ]];
}

- (void) tableView: (NSTableView *) aTableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex
{
    NSString *colName;
    Block *block;
    int partIndex;
    int n;
    
    colName=[ aTableColumn identifier ];
    block= [ sequencer blockAtIndex: rowIndex ];

    [ sequencerController setModified ];

    if([ colName isEqual: @"L" ])
    {
        n=[ anObject intValue ];
        [ block setLength: n ];
        return;
    }
    
    if([ colName isEqual: @"N" ])
    {
        [ block setName: anObject ];
        return;
    }

    partIndex=[ colName intValue ];
    
    dbgprintf("column identifier: %s\n", [ colName cString ]);
    
    n=[ anObject intValue ];

    dbgprintf("pattern: %d atBlock: %d (%p)  forPart: %d \n", n, rowIndex, block, partIndex);
    [ block setPattern: n forPart: partIndex ];
}

- (void)tableViewSelectionDidChange:(NSNotification *) aNotification
{
    dbgprintf("tableViewSelectionDidChange\n");
    [ self updateButtons ];
}

@end
