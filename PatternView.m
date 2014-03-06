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

#include <math.h>

#import <AppKit/NSGraphicsContext.h>

#import "PatternView.h"
#import "PatternMatrix.h"
#import "SequencerController.h"
#import "Note.h"

#include "debug.h"


// recommended view size: 608x263

#define FONT_SIZE 9.0

@implementation PatternView

- (BOOL) isBlackKey: (int) key
{
    static BOOL black[]={ 0,1,0,1,0,0,1,0,1,0,1,0 };
    
    return black[ key % sizeof(black) ];
}

- (void) dealloc
{
    int i;
    
    [ grid release ];
    [ gridColor release ];
    [ dimGridColor release ];
    [ cellColor release ];
    [ selectionColor release ];
    [ blackKeyColor release ];
    [ whiteKeyColor release ];
    
    for(i=0;i<CELL_COLORS;i++) [ cellColors[i] release ];
    [ super dealloc ];
}

- (BOOL) isOpaque
{
    return YES;
}

- (void) setGridColor: (NSColor *) color
{
    [ color retain ];
    [ gridColor release ];
    gridColor=color;
    
    [ dimGridColor release ];
    dimGridColor=[ gridColor blendedColorWithFraction: 0.66 ofColor: [ NSColor blackColor ]];
    [ dimGridColor retain ];

    [ self setNeedsDisplay: YES ];
}

- initWithFrame: (NSRect) rect
{
    NSFont *font;
    int i;
    float v;
    
    [ super initWithFrame: rect ];

    gridColor=[ NSColor redColor ];
    [ gridColor retain ];
    
    // dimGridColor=[ NSColor colorWithDeviceRed: 0.33
    //                green: 0.0 blue: 0.0 alpha: 1.0 ];
    
    dimGridColor=[ gridColor blendedColorWithFraction: 0.66 ofColor: [ NSColor blackColor ]];

    [ dimGridColor retain ];

    cellColor= [ NSColor lightGrayColor ];
    [ cellColor retain ];

    for(i=0;i<CELL_COLORS;i++)
    {
        v=0.1+0.6/(CELL_COLORS-i);
        cellColors[i]=[ NSColor colorWithDeviceRed: v
                            green: v blue: v alpha: 1.0 ];
        [ cellColors[i] retain ];
    }

    selectionColor=cellColor;
    [ selectionColor retain ];
    
    blackKeyColor=[ NSColor blackColor ];
    [ blackKeyColor retain ];

    v=0.9;
    whiteKeyColor=[ NSColor colorWithDeviceRed: v
                            green: v blue: v alpha: 1.0 ];
    [ whiteKeyColor retain ];

    font=[ NSFont userFontOfSize: FONT_SIZE ];
    fontYOffset=[ font descender ];
    
    fontAttributes=[[ NSMutableDictionary alloc ] init ];
    [ fontAttributes setObject: font
        forKey: NSFontAttributeName];
    [ fontAttributes setObject: [ NSColor whiteColor ]
        forKey: NSForegroundColorAttributeName ];

    // grid width and height is taken later from the matrix object
    gridWidth=0;
    gridHeight=0;
    
    leftBorder=32;
    rightBorder=8;
    upperBorder=16;
    lowerBorder=8;
    
    [ self makeGrid ];

    return self;
}

- (void) makeIndicatorRow
{
    NSRect bounds= [ self bounds ];
    NSPoint p;
    int col;
    float x;
    float gridX1,gridX2;
    float gridY1,gridY2;

    if(indicatorRow)
    {
        [ indicatorRow release ];
        indicatorRow=nil;
    }

    indicatorRow=[[ NSBezierPath alloc ] init ];
    gridX1=bounds.origin.x+leftBorder+0.5;
    gridY1=bounds.origin.y+lowerBorder+0.5+cellHeight*gridHeight;
   
    gridX2=gridX1+cellWidth*gridWidth;
    gridY2=gridY1+cellHeight;

    indicatorBounds.origin.x=gridX1;
    indicatorBounds.origin.y=gridY1;
    indicatorBounds.size.width=cellWidth*gridWidth;
    indicatorBounds.size.height=cellHeight;

    indicatorBounds=NSInsetRect(indicatorBounds,-1.0,-1.0);

    // make outer rectangle
    p.x=gridX1;
    p.y=gridY1;
    [ indicatorRow moveToPoint: p ];
    p.x=gridX2;
    [ indicatorRow lineToPoint: p ];
    p.y=gridY2;
    [ indicatorRow lineToPoint: p ];
    p.x=gridX1;
    [ indicatorRow lineToPoint: p ];
    p.y=gridY1;
    [ indicatorRow lineToPoint: p ];


    x=gridX1+cellWidth;
    for(col=0;col<gridWidth-1;col++)
    {
        p.x=x;
        p.y=gridY1;
        [ indicatorRow moveToPoint: p ];
        p.y=gridY2;
        [ indicatorRow lineToPoint: p ];
        x+=cellWidth;

        if((col-2 & 3) == 0 & col!=gridWidth-2)
        {
            p.x=x+1.0;
            p.y=gridY1;
            [ indicatorRow moveToPoint: p ];
            p.y=gridY2;
            [ indicatorRow lineToPoint: p ];
        }
    }
}

- (int) selectedRow
{
    return selectedRow;
}

- (int) selectedColumn
{
    return selectedColumn;
}


- (BOOL) selectionEnabled
{
    return selectionEnabled;
}

- setSelectionEnabled: (BOOL) aBool
{
    if(selectionEnabled==aBool) return self;

    selectionEnabled=aBool;    
    if(!selectionEnabled) [ self deselect ];
    [ self setNeedsDisplay: YES ];
    return self;
}

- deselect
{
    if(!selection) return self;

    selection=NO;
    [ self redrawSelection ];
    
    if([ sequencerController respondsToSelector: @selector(cellDeselected) ])
            [ sequencerController cellDeselected ];

    return self;
}

- selectCellAt: (int) x : (int) y
{
    selectedColumn=x;
    selectedRow=y;
    selection=YES;

    // redraw old selection rectangle
    [ self redrawSelection ];
    // calculate new rect
    [ self makeSelectionRect ];
    // redraw new rect
    [ self redrawSelection ];

    if([ sequencerController respondsToSelector: @selector(cellSelected) ])
        [ sequencerController cellSelected ];
    
    return self;
}

- selectCellsAt: (int) x : (int) y count: (int) count
{
    selectedColumn=x;
    selectedRow=y;
    selection=YES;

    // redraw old selection rectangle
    [ self redrawSelection ];
    // calculate new rect
    selectionRect=[ self makeSelectionRectAtRow: selectedRow
                        column: selectedColumn width: count height: 1 ];
    // redraw new rect
    [ self redrawSelection ];

    if([ sequencerController respondsToSelector: @selector(cellSelected) ])
        [ sequencerController cellSelected ];
    
    return self;
}


- (void) makeSelectionRect
{
    selectionRect=[ self makeSelectionRectAtRow: selectedRow
                        column: selectedColumn width:1 height: 1 ];
}


- (NSRect) makeSelectionRectAtRow: (int) row column: (int) col
    width: (int) w height: (int) h
{
    NSRect rect;
    NSPoint p;
    
    p.x=leftBorder+col*cellWidth+0.5;
    p.y=lowerBorder+row*cellHeight+0.5;
    
    rect.origin=p;
    rect.size.width=cellWidth*w;
    rect.size.height=cellHeight*h;
    
    return rect;
}

- (void) makeGrid
{
    NSRect bounds= [ self bounds ];
    NSPoint p;
    int line,col;
    float x,y;
    float gridX1,gridX2;
    float gridY1,gridY2;

    if(grid)
    {
        [ grid release ];
        grid=nil;
    }

    if(!patternMatrix) return;
    
    gridWidth= [ patternMatrix columns ];
    gridHeight= [ patternMatrix rows ];
    
    
    // calculate size of a matrix cell, take one more row for indicator row
    cellWidth=floor((bounds.size.width-leftBorder-rightBorder)/gridWidth);
    cellHeight=floor((bounds.size.height-lowerBorder-lowerBorder)/(gridHeight+1));
    
    dbgprintf("gridWidth: %d height: %d\n",gridWidth,gridHeight);
    dbgprintf("cellWidth: %f height: %f\n",cellWidth,cellHeight);
    
    grid=[[ NSBezierPath alloc ] init ];
    [ grid setLineWidth: 0.0 ];
    
    
    gridX1=bounds.origin.x+leftBorder+0.5;
    gridY1=bounds.origin.y+lowerBorder+0.5;
   
    gridX2=gridX1+cellWidth*gridWidth;
    gridY2=gridY1+cellHeight*gridHeight;

    gridY1+=cellHeight;
    gridY2-=cellHeight;
   
    // make outer rectangle
    p.x=gridX1;
    p.y=gridY1;
    [ grid moveToPoint: p ];
    p.x=gridX2;
    [ grid lineToPoint: p ];
    p.y=gridY2;
    [ grid lineToPoint: p ];
    p.x=gridX1;
    [ grid lineToPoint: p ];
    p.y=gridY1;
    [ grid lineToPoint: p ];
    
    
    // first and last rows of the matrix are not shown in the grid

    y=gridY1;

    for(line=1;line<gridHeight;line++)
    {
        p.x=gridX1;
        p.y=y;
        [ grid moveToPoint: p ];
        p.x=gridX2;
        [ grid lineToPoint: p ];
        
        y += cellHeight;

    }
    
    x=gridX1;
    
    for(col=0;col<gridWidth;col++)
    {
        p.x=x;
        p.y=gridY1;
        [ grid moveToPoint: p ];
        p.y=gridY2;
        [ grid lineToPoint: p ];

        if(col>0 && (col & 3) == 0)
        {
            p.x=x+1.0;
            p.y=gridY1;
            [ grid moveToPoint: p ];
            p.y=gridY2;
        
            [ grid lineToPoint: p ];
        }

        x += cellWidth;
    }

    // [ grid closePath ];
    
    [ self makeIndicatorRow ];
}

- (void) redrawSelection
{
    [ self setNeedsDisplayInRect: selectionRect ];
}

- (void) drawSelection
{
    if(!selection) return;
    [ selectionColor set ];
    [ NSBezierPath strokeRect: selectionRect ];
}

- (void) drawColumnTags
{
    NSRect bounds= [ self bounds ];
    NSPoint p;
    int col;
    id t;

    p.x=bounds.origin.x+leftBorder+0.5+floor(cellWidth/4);
    p.y=bounds.origin.y+lowerBorder+0.5+fontYOffset-cellHeight/2;

    for(col=0;col<gridWidth;col++)
    {
        t=[ patternMatrix columnTagAt: col ];
        [ t drawAtPoint: p withAttributes: fontAttributes ];
        p.x+=cellWidth;
    }    
}

// draw the legend (note names) left of the grid
- (void) drawLegendInRect: (NSRect) rect
{
    int i,n;
    int k;
    float y;
    NSString *name;
    NSPoint p;
    
    static BOOL drawHere[12]={1,0,1,0,0,1,0,1,0,0,0,0};
    
    p.x=rect.origin.x+2;
    
    y=rect.origin.y+lowerBorder+fontYOffset;
    
    for(i=1;i<gridHeight-1;i++)
    {
        n=(i%12)-1;
    
        if(!drawHere[n]) continue;
    
        k=[ patternMatrix keyNumberFromRow: i ];
        name=[ Note nameForKeyNumber: k ];

        p.y=y+(i*cellHeight)+2;
        [ name drawAtPoint: p withAttributes: fontAttributes ];
    }
}


// draw contents of my view
- (void) drawRect: (NSRect) rect
{
    int x,y;

    NSRect bounds = [ self bounds ];
    NSRect row;
    // do a fast update if rect is completely inside the
    // bounds of the indicator row
    if( NSContainsRect(indicatorBounds,rect))
    {
        [[ NSColor blackColor ] set ];
        [ NSBezierPath fillRect: rect ];
        [ gridColor set ];
        [ indicatorRow stroke ];
        [ self drawIndicatorAt: indicatorColumn filled: YES ];
        // dbgprintf("fast update\n");
        return;
    }

    //[[NSGraphicsContext currentContext ] setShouldAntialias: NO ];

    [ NSBezierPath setDefaultLineWidth: 0.0 ];
    [[ NSColor blackColor ] set ];
    [ NSBezierPath fillRect: bounds ];
    
    /*[[ NSColor redColor ] set ];
  
    bounds.origin.x += 50;
    bounds.origin.y += 50;
    bounds.size.width=50;
    bounds.size.height=50;
    */



//    // draw stripes for black keys
//    row.origin.x=bounds.origin.x+outerBorder+0.5;
//    row.origin.y=bounds.origin.y+outerBorder+0.5;
//    row.size.width=cellWidth*gridWidth;
//    row.size.height=cellHeight;

    // draw white keys
    row.origin.x=bounds.origin.x+cellWidth+1.0;
    row.origin.y=bounds.origin.y+lowerBorder+1.0;
    row.size.width=cellWidth-4.0;
    row.size.height=cellHeight-1.0;

    [ whiteKeyColor set ];
    row.origin.y += cellHeight;
    
    for(y=0;y<gridHeight-2;y++)
    {
        if(![ self isBlackKey: y ]) [ NSBezierPath fillRect: row ];
        row.origin.y += cellHeight;
    }

    [ gridColor set ];
    
    //[ NSBezierPath strokeRect: bounds ];

    // draw the grid and indicator line
    [ grid stroke ];
    [ indicatorRow stroke ];
    
    // paint each cell if necessary
    for(y=0;y<gridHeight;y++)
    {
        for(x=0;x<gridWidth;x++)
        {
            [ self drawCell: x : y ];
        }
    }
    
    [ self drawLegendInRect: bounds ];
    [ self drawIndicatorAt: indicatorColumn filled: YES ];
    
    [ self drawSelection ];

    [ self drawColumnTags ];
    // [[ NSColor greenColor ] set ];
    // [ NSBezierPath strokeRect: indicatorBounds ];
}

- (int) cellRowFromPoint: (NSPoint) aPoint
{
    int y;
    
    y=(aPoint.y-lowerBorder)/cellHeight;
    if(y<0 | y>=gridHeight) return -1;
    return y;
}

- (int) cellColumnFromPoint: (NSPoint) aPoint
{
    int x;
    
    x=(aPoint.x-leftBorder)/cellWidth;
    if(x<0 || x>=gridWidth) return -1;
    return x;
}

- (void) drawTriangleInRect: (NSRect) rect down: (BOOL) downFlag
{
    NSBezierPath *path=[[ NSBezierPath alloc ] init ];
    NSPoint p;
    float y1,y2,tmp;
    
    y1=rect.origin.y;
    y2=y1+rect.size.height;
    
    if(downFlag)
    {
        tmp=y1;
        y1=y2;
        y2=tmp;
    }

    p.x=rect.origin.x;
    p.y=y1;
    [ path moveToPoint: p ];
    p.x=rect.origin.x+rect.size.width/2;
    p.y=y2;
    [ path lineToPoint: p ];
    p.x=rect.origin.x+rect.size.width;
    p.y=y1;
    [ path lineToPoint: p ];
    [ path closePath ];
    
    [ path fill ];
                
    [ path release ];
}

- (void) drawCell: (int) x : (int) y
{
    NSRect cellRect;
    NSRect bounds = [ self bounds ];
    CellType t=[ patternMatrix cellAtX: x y: y ];
    int value=[ patternMatrix cellValueAtX: x y: y ];
    
    cellRect.origin.x=bounds.origin.x+leftBorder+cellWidth*(float)x+2.0;
    cellRect.origin.y=bounds.origin.y+lowerBorder+cellHeight*(float)y+2.0;

    cellRect.size.width=cellWidth-4.0;
    cellRect.size.height=cellHeight-4.0;

    if(value<0 || value>=CELL_COLORS)
        [ cellColor set ];
    else
    {
        [ cellColors[value] set ];
    }

    switch(t)
    {
        case Empty:
            return;

        case Full:
            break;

        case Half:
            cellRect.size.width = cellRect.size.width /2.0;
            break;

        case End:
            cellRect.size.width -= 3.0;
            break;
            
        case Up:
            [ cellColor set ];
            [ self drawTriangleInRect: cellRect down: NO ];
            return;
        
        case Down:
            [ cellColor set ];
            [ self drawTriangleInRect: cellRect down: YES ];
            return;

        default:
            return;
    }

    //[ cellColor set ];

    [ NSBezierPath fillRect: cellRect ];
}

- (void) drawIndicatorAt: (int) x filled: (BOOL) fill
{
    NSRect cellRect;
    NSRect bounds = [ self bounds ];
    int y=gridHeight;

    if(x<0) return;

    cellRect.origin.x=bounds.origin.x+leftBorder+cellWidth*(float)x+2.0;
    cellRect.origin.y=bounds.origin.y+lowerBorder+cellHeight*(float)y+2.0;

    cellRect.size.width=cellWidth-4.0;
    cellRect.size.height=cellHeight-4.0;

    if(fill)
        [ gridColor set ];
    else
        [[ NSColor blackColor ] set ];

    [ NSBezierPath fillRect: cellRect ];
}

- (void) redisplayIndicatorRow
{
    NSRect bounds=NSInsetRect(indicatorBounds,1.0,1.0);

    [ self setNeedsDisplayInRect: bounds ];
}

- redisplayRow: (int) row
{
    NSRect rect=[ self makeSelectionRectAtRow: row
                    column: 0
                    width: [ patternMatrix columns ]
                    height: 1 ];
                    
    [ self setNeedsDisplayInRect: rect ];
    //[ self setNeedsDisplay: YES ];

    return self;
}

- patternMatrix
{
    return patternMatrix;
}

- setPatternMatrix: anId
{
    [ anId retain ];
    [ patternMatrix release ];
    patternMatrix=anId;
    [ self makeGrid ];
    return self;
}

- setIndicator: (int) anInt
{
    if(anInt<-1 || anInt >= gridWidth) return nil;

    //[ self drawIndicatorAt: selectedColumn filled: NO ];
    //[ self drawIndicatorAt: anInt filled: YES ];
    
    indicatorColumn=anInt;
    
    [ self redisplayIndicatorRow ];

    return self;
}

- (int) indicator
{
    return indicatorColumn;
}

- (BOOL) convertPoint: (NSPoint) p toCell: (int *) xReturn : (int *) yReturn
{
    int x,y;
    
    x=[ self cellColumnFromPoint: p ];
    y=[ self cellRowFromPoint: p ];
    
    if(x==-1 || y==-1) return NO;    
    if(y<1 || y>=gridHeight-1) return NO;
    
    *xReturn=x;
    *yReturn=y;
    
    return YES;

}

- (void) mouseDown: (NSEvent *) event
{
    int x,y,s,l;
    CellType t;
    NSPoint p=[ event locationInWindow ];
    NSPoint down=[ self convertPoint:p fromView: nil ];
    
    if(![ self convertPoint: down toCell: &x : &y ])
    {
        if(NSPointInRect(down,indicatorBounds))
        {
                x=[ self cellColumnFromPoint: down ];
                [ sequencerController stepClicked: x ];
                ignoreMouseDown=YES;
        }
        return;
    }
    ignoreMouseDown=NO;
    
    if(selectionEnabled)
    {
        t=[ patternMatrix cellAtX: x y: y ];
        
        if(t!=Empty)
        {
            s=[ patternMatrix findStartOfX: x y: y ];
            l=[ patternMatrix findEndOfX: x y: y ]-s+1;
            if(l<1) l=1;
            [ self selectCellsAt: s : y count: l ];
            //[ self selectCellAt: s : y ];
        }
        else
        {
            [ self deselect ];

        }
    }
    [ sequencerController cellClickedAt: x : y ];
}

- (void) mouseUp: (NSEvent *) event
{
    if(!ignoreMouseDown) [ sequencerController endClick ];
}

- (void) mouseDragged: (NSEvent *) event
{
    NSPoint p=[ event locationInWindow ];
    NSPoint down=[ self convertPoint:p fromView: nil ];
    int x,y;
    
    if([ self convertPoint: down toCell: &x : &y ])
    {
        [ sequencerController cellDraggedAt: x : y ];
    }
}

@end
