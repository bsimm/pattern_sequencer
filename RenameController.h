//
//  RenameController.h
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

#import <Cocoa/Cocoa.h>


@interface RenameController : NSObject {
    IBOutlet id renameWindow;
    IBOutlet id cancelButton;
    IBOutlet id okButton;
    IBOutlet id label;
    IBOutlet id nameField;
    IBOutlet id mainWindow;

    id disallowedNames;
    id delegate;
    SEL doneSelector;
    NSString *name;
    NSString *labelText;
}

- setDisallowedNames: (NSArray *) array;
- setDoneSelector: (SEL) selector;
- setName: (NSString *) name;
- setLabelText: (NSString *) label;
- setDelegate: (id) anId;
- (id) delegate;
- (NSArray *) disallowedNames;
- (SEL) doneSelector;
- (NSString *) name;
- (NSString *) labelText;

- beginSheet;
- endSheetFromSender: sender code: (BOOL) succeeded;
- renameDone;

- (IBAction) okClicked: sender;
- (IBAction) cancelClicked: sender;
- (IBAction) nameChanged: sender;

@end
