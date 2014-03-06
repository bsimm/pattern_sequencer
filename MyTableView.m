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

#import "MyTableView.h"

@implementation MyTableView

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *keyString;
    unichar   keyChar;
    int row;
    
    keyString = [theEvent charactersIgnoringModifiers];
    keyChar = [keyString characterAtIndex:0];
    
    if([ keyString length ]>0 && keyChar>='0' && keyChar <='9')
    {
        if(keyChar=='0')
            row=9;
        else
            row=keyChar-'1';

        if(row<[ self numberOfRows ])
        {
            
            [ self selectRowIndexes: [ NSIndexSet indexSetWithIndex: row ]
               byExtendingSelection: NO ];
            [ [ self target ] performSelector: [ self action ] withObject: self ];
            return;
        }      
    }

    [super keyDown:theEvent];
}

@end
