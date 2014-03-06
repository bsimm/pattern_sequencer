//
//  PatternMatrix.h
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


#import <Foundation/Foundation.h>

typedef enum { Empty=0, Full, End, Up, Down, Half } CellType;
struct cell
{
    CellType type;
    int startColumn;
    int value;
    int color;
    int endColumn;
};

@interface PatternMatrix : NSObject {
    int height;
    int width;

    struct cell **cells;
    
    int startLine;
    int startColumn;
    int baseLine;
    
    id pattern;
}

- (void) dealloc;

- (int) rows;
- (int) columns;
- (int) startLine;
- (int) startColumn;
- (int) baseLine;
- pattern;

- (CellType) cellAtX: (int) x y: (int) y;
- (int) cellValueAtX: (int) x y: (int) y;
- (int) cellColorAtX: (int) x y: (int) y;
- (int) findStartOfX: (int) x y: (int) y;
- (int) findEndOfX: (int) x y: (int) y;
- (NSString *) columnTagAt: (int) col;
- setCellAtX: (int) x y: (int) y type: (CellType) t start: (int) s;
- setCellValue: (int) v atX: (int) x y: (int) y;
- (int) keyNumberFromRow: (int) row;
- (int) stepFromColumn: (int) column;
- setHeight: (int) anInt;
- setStartLine: (int) anInt;
- setStartColumn: (int) anInt;
- setBaseLine: (int) anInt;
- setPattern: (id) aPattern;

- (void) allocCells;
- (void) deallocCells;
- (void) loadColumn: (int) x;
- (void) clearColumn: (int) x;
- (void) clearNoteAt: (int) x : (int) y;

- loadColumns;
- reload;

- print;
@end
