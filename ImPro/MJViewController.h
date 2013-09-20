//
//  MJViewController.h
//  ImPro
//
//  Created by Martin Johannesson on 2013-09-14.
//  Copyright (c) 2013 Martin Johannesson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MJViewController : NSViewController <NSComboBoxDelegate, NSComboBoxDataSource>
@property (weak) IBOutlet NSImageView *beforeImageView;
@property (weak) IBOutlet NSImageView *afterImageView;

@property (weak) IBOutlet NSComboBox *shaderComboBox;
@property (unsafe_unretained) IBOutlet NSWindow *shaderEditorWindow;
@property (unsafe_unretained) IBOutlet NSTextView *shaderTextView;
@property (unsafe_unretained) IBOutlet NSTextView *shaderCompilerLogTextView;

- (IBAction)selectBeforeAction:(id)sender;

- (IBAction)runAction:(id)sender;
- (IBAction)imageChangedAction:(id)sender;
- (IBAction)compileShaderAction:(id)sender;
- (IBAction)copyAfterImageToPasteboard:(id)sender;
- (IBAction)openFragmentShaderEditor:(id)sender;

@end
