/* PatternView */
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

#define CELL_COLORS 4

@interface PatternView : NSView
{
    IBOutlet id patternMatrix;
    IBOutlet id sequencerController;
    
    NSBezierPath *grid;
    NSBezierPath *indicatorRow;
    NSRect indicatorBounds;
    NSColor *gridColor;
    NSColor *dimGridColor;
    NSColor *blackKeyColor;
    NSColor *whiteKeyColor;
    NSColor *cellColor;
    NSColor *cellColors[CELL_COLORS];
    NSColor *selectionColor;
    NSMutableDictionary *fontAttributes;
    NSRect selectionRect;
    NSArray *columnTags;

    int gridHeight;
    int gridWidth;
    float cellHeight;
    float cellWidth;
    
    float leftBorder,rightBorder;
    float upperBorder,lowerBorder;
    float fontYOffset;
    
    int selectedColumn;
    int selectedRow;
    BOOL selection;
    BOOL selectionEnabled;

    int indicatorColumn;
    
    BOOL ignoreMouseDown;
}

- initWithFrame: (NSRect) rect;
- (void) drawRect: (NSRect) rect;
- (void) dealloc;
- (BOOL) isOpaque;

- patternMatrix;
- (int) indicator;
- (BOOL) selectionEnabled;
- setPatternMatrix: anId;
- setSelectionEnabled: (BOOL) aBool;
- setIndicator: (int) anInt;
- (void) setGridColor: (NSColor *) color;

//- selectColumn: (int) anInt;
- (int) selectedColumn;
- (int) selectedRow;

- selectCellAt: (int) x : (int) y;
- selectCellsAt: (int) x : (int) y count: (int) count;
- deselect;
- redisplayRow: (int) row;

// Events

- (void) mouseDown: (NSEvent *) event;
- (void) mouseUp: (NSEvent *) event;
- (void) mouseDragged: (NSEvent *) event;

// internal
- (void) makeGrid;
- (void) drawCell: (int) x : (int) y;
- (void) drawIndicatorAt: (int) x filled: (BOOL) fill;
- (void) redisplayIndicatorRow;
- (void) makeSelectionRect;
- (NSRect) makeSelectionRectAtRow: (int) row column: (int) col
    width: (int) w height: (int) h;
- (void) redrawSelection;
- (void) drawSelection;

- (int) cellRowFromPoint: (NSPoint) aPoint;
- (int) cellColumnFromPoint: (NSPoint) aPoint;

@end
