//
//  PatternMatrix.m
//  PatternSequencer
//
//  Created by Sebastian Lederer on Wed Aug 20 2003.
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

#import "PatternMatrix.h"
#import "SeqPattern.h"
#import "Note.h"
#import "ParameterChange.h"

#include "debug.h"

#define DEFAULT_HEIGHT 20
#define DEFAULT_WIDTH 32
#define DEFAULT_VALUE 4
#define DEFAULT_COLOR 1

@implementation PatternMatrix

- (void) dealloc
{
    dbgprintf("PatternMatrix dealloc\n");
    [ self deallocCells ];
    dbgprintf("pattern retainCount %u\n", [ pattern retainCount ]);
    [ pattern release ];
    [ super dealloc ];
}

- (int) rows
{
    return height;
}

- (int) columns
{
    return width;
}

- (int) startLine
{
    return startLine;
}

- (int) startColumn
{
    return startColumn;
}

- (int) baseLine
{
    return baseLine;
}

- pattern
{
    return pattern;
}

- (CellType) cellAtX: (int) x y: (int) y
{
    return cells[y][x].type;
}

- (int) cellValueAtX: (int) x y: (int) y
{
    return cells[y][x].value;
}

- (int) cellColorAtX: (int) x y: (int) y
{
    return cells[y][x].color;
}

- (int) findStartOfX: (int) x y: (int) y
{
    return cells[y][x].startColumn;
}

- (int) findEndOfX: (int) x y: (int) y
{
    return cells[y][x].endColumn;
}

- (NSString *) columnTagAt: (int) col
{
    ParameterChange *p=[ pattern parametersAtStep: startColumn+col ];
    
    if([ p enabled ]) return @"P";
    
    return nil;
}

- setCellAtX: (int) x y: (int) y type: (CellType) t start: (int) s
{
    if(x<0 || x>=width || y<0 || y>=height) return nil;
    cells[y][x].type=t;
    cells[y][x].startColumn=s;
    cells[y][x].value=DEFAULT_VALUE;
    cells[y][x].color=DEFAULT_COLOR;
    return self;
}

- setCellValue: (int) v atX: (int) x y: (int) y
{
    if(x<0 || x>=width || y<0 || y>=height) return nil;
    cells[y][x].value=v;
    return self;
}

- (int) keyNumberFromRow: (int) row
{
    return row+startLine;
}

- (int) stepFromColumn: (int) column
{
    return column+startColumn;
}

- setHeight: (int) anInt
{
    height=anInt;
    return self;
}

- setStartLine: (int) anInt
{
    startLine=anInt;
    return self;
}

- setStartColumn: (int) anInt
{
    startColumn=anInt;
    return self;
}

- setBaseLine: (int) anInt
{
    baseLine=anInt;
    return self;
}

- setPattern: (id) aPattern
{
    dbgprintf("matrix setPattern %p retain count %u\n",aPattern,
        [ aPattern retainCount ]);

    [ aPattern retain ];
    if(pattern) [ pattern release ];
    pattern=aPattern;
    return self;
}

- reload
{
    return [ self loadColumns ];
}

- loadColumns
{
    int x;
    
    if(!pattern) return nil;
    
    if(!width) width=DEFAULT_WIDTH;
    if(!height) height=DEFAULT_HEIGHT;
    
    [ self allocCells ];
    
    for(x=0;x<width;x++)
    {
        [ self loadColumn: x ];
    }
    return self;
}

- (void) clearColumn: (int) x
{
    int y;
    
    for(y=0;y<height;y++)
    {
        if(cells[y][x].startColumn==x) [ self clearNoteAt: x : y ];
    }
}

- (void) clearNoteAt: (int) x : (int) y
{
    struct cell c;
    int x1;

    c=cells[y][x];

    if(c.type==Empty) return;
    
    x1=c.startColumn;

    while(cells[y][x1].startColumn==x) cells[y][x1++].type=Empty;
}

- (void) loadColumn: (int) x
{
    int k,i;
    int upperLimit, lowerLimit;
    int step;
    unsigned long int l;
    int value;
    id notes;
    id o,e;

    // first and last line have special meaning:
    // they are used for "Up" and "Down" symbols only
    upperLimit=startLine+height-2;
    lowerLimit=startLine+1;

    step=x+startColumn;

    // process all notes at step
    notes=[ pattern notesAtStep: step ];
    e=[ notes objectEnumerator ];
    while( o=[ e nextObject ] )
    {
        k=[ o keyNumber ];
        l=[ o duration ];
        value=([ o velocity ]+1)/32;

        if(k>upperLimit)
        {
            cells[height-1][x].type=Up;
            cells[height-1][x].startColumn=x;
        }
        else
        if(k<lowerLimit)
        {
            cells[0][x].type=Down;
            cells[0][x].startColumn=x;
        }
        else
        {
            k=k-startLine;
            
            if(l==0)
            {
                cells[k][x].type=Half;
                cells[k][x].startColumn=x;
                cells[k][x].endColumn=x;
            }
            else
            {
                l=l-1;

                cells[k][x].type=Full;
                cells[k][x].startColumn=x;
                cells[k][x].endColumn=x+l;                
                for(i=1;i<l && (x+i)<width;i++)
                {
                    cells[k][x+i].type=Full;
                    cells[k][x+i].startColumn=x;
                    cells[k][x+i].value=value;
                    cells[k][x+i].color=0;
                    cells[k][x+i].endColumn=x+l;                 
                }
                
                cells[k][x+l].type=End;
                cells[k][x+l].startColumn=x;
                cells[k][x+l].value=value;
                cells[k][x+l].color=0;
                cells[k][x+l].endColumn=x+l;
            }
            
            cells[k][x].value=value;
            cells[k][x].color=0;
        }
    }
    // notes, e and o are autoreleased
}

- (void) allocCells
{
    int y;
    
    if(cells) [ self deallocCells ];

    if(!width | !height) return;
    
    cells=calloc(height,sizeof(struct cell *));
    
    for(y=0;y<height;y++)
    {
        cells[y]=calloc(width,sizeof(struct cell));
    }
}

- (void) deallocCells
{
    int y;
    
    if(!cells) return;
    
    for(y=0;y<height;y++)
    {
        free(cells[y]);
    }
    free(cells);
    cells=NULL;
}

- print
{
    int x,y;

    for(y=0;y<height;y++)
    {
        for(x=0;x<width;x++)
        {
            switch(cells[y][x].type)
            {
                case Full:
                    putchar('=');
                    break;
                case End:
                    putchar(']');
                    break;
                case Up:
                    putchar('^');
                    break;
                case Down:
                    putchar('v');
                    break;
                case Half:
                    putchar(')');
                default:
                    putchar('.');
                    break;
            }
        }
        putchar('\n');
    }
    return self;
}
@end
