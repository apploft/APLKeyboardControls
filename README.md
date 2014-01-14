APLKeyboardControls
=========
InputAccesoryView above the keyboard with done button and optional previous and next buttons.

* close the keyboard with a done button
* navigate between text fields, text views and search bars with optional previous and next buttons
* skips hidden inputs
* completely customizable bar button items and toolbar
* implemented with iOS 7 in mind

## Installation
Install via cocoapods by adding this to your Podfile:

	pod "APLKeyboardControls", "~> 0.0.2"

## Usage
Import header file:

	#import "APLKeyboardControls.h"
	
Define keyboardControls as a property in your viewController and initialize it like this:
	
	NSArray* inputChain = @[self.textField1, self.textField2, self.textField3];
	self.keyboardControls = [[APLKeyboardControls alloc] initWithInputFields:inputChain];
	self.keyboardControls.hasPreviousNext = YES;

Customize buttons like this:

	self.keyboardControls.doneButton.tintColor = [UIColor redColor];