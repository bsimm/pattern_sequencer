//
//  RenameController.m
//  PatternSequencer
//
//  Created by Sebastian Lederer on Sun Oct 12 2003.
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


#import "RenameController.h"

#include "debug.h"

@implementation RenameController

- (void) dealloc
{
    [ disallowedNames release ];
    [ name release ];
    [ labelText release ];
}

- setDelegate: (id) anId
{
    delegate=anId;
    return self;
}

- setDisallowedNames: (NSArray *) array
{
    [ array retain ];
    [ disallowedNames release ];
    disallowedNames=array;
    return self;
}

- setDoneSelector: (SEL) selector
{
    doneSelector=selector;
    return self;
}

- setName: (NSString *) newName
{
    [ newName retain ];
    [ name release ];
    name=newName;
    return self;
}

- setLabelText: (NSString *) newLabel
{
    [ newLabel retain ];
    [ labelText release ];
    labelText=newLabel;
    return self;
}

- (NSArray *) disallowedNames
{
    return disallowedNames;
}

- (SEL) doneSelector
{
    return doneSelector;
}

- (id) delegate
{
    return delegate;
}

- (NSString *) name
{
    return name;
}

- (NSString *) labelText
{
    return labelText;
}


- (BOOL) isValidName: (NSString *) newName;
{
    id e,o;
    NSString *n;
    
    if( [ newName length ]==0 ) return NO;
    
    e=[ disallowedNames objectEnumerator ];
    while(o=[ e nextObject ])
    {
        n= [ o name ];
        if([ newName isEqual: n ]) return NO;
    }
    
    return YES;
}

- beginSheet
{
    if(labelText) [ label setStringValue: labelText ];
    [ nameField setStringValue: name ];
    [ NSApp beginSheet: renameWindow modalForWindow: mainWindow
            modalDelegate: self
            didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
            contextInfo: nil ];
    return self;
}

- endSheetFromSender: sender code: (BOOL) succeeded
{
    if(succeeded)
    {
        if( [ self isValidName: [ nameField stringValue ] ]==NO)
        {
            NSBeep();
            return self;
        }
    }

    [ renameWindow orderOut: sender ];
    [ NSApp endSheet: renameWindow returnCode: ( succeeded ? 1 : 0 ) ];
    return self;
}

- (void) sheetDidEnd: (NSWindow *) sheet returnCode: (int) returnCode
        contextInfo: (void *) contextInfo
{
    dbgprintf("renameWindow sheetDidEnd\n");
    if(returnCode==0)
    {
        dbgprintf("cancel\n");
        [ name release ];
        name=nil;
        return;
    }

    [ self renameDone ];
}

- renameDone
{
    [ name release ];
    name=[ nameField stringValue ];
    [ name retain ];

    dbgprintf("renameDone new name: %s\n", [ name cString ]);
    
    if(doneSelector) [ delegate performSelector: doneSelector ];
    return self;
}

- (IBAction) okClicked: sender
{
    [ self endSheetFromSender: sender code: YES ];
}

- (IBAction) cancelClicked: sender
{
    [ self endSheetFromSender: sender code: NO ];
}

- (IBAction) nameChanged: sender
{

}

@end
