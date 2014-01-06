//  Created by Michael Kamphausen on 04.10.13.
//  Copyright (c) 2013 apploft GmbH. All rights reserved.
//

#import "APLKeyboardControls.h"


@interface APLKeyboardControls ()

@property (nonatomic, weak) UIResponder* currentInput;
@property (nonatomic, strong) UIBarButtonItem* flexSpace;

@end


@implementation APLKeyboardControls

#pragma mark - initialization

- (id)initWithInputFields:(NSArray*)inputFields {
    self = [super init];
    if (self) {
        self.inputFields = inputFields;
    }
    return self;
}

- (UIBarButtonItem *)doneButton {
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeInput:)];
    }
    return _doneButton;
}

- (UIBarButtonItem *)flexSpace {
    if (!_flexSpace) {
        _flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    return _flexSpace;
}

- (UIBarButtonItem *)previousButton {
    if (!_previousButton) {
        _previousButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"previous", nil) style:UIBarButtonItemStylePlain target:self action:@selector(focusPrevious:)];
    }
    return _previousButton;
}

- (UIBarButtonItem *)nextButton {
    if (!_nextButton) {
        _nextButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(focusNext:)];
    }
    return _nextButton;
}

- (UIToolbar *)inputAccessoryView {
    if (!_inputAccessoryView) {
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        _inputAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0., 0., CGRectGetWidth(appFrame), 44.)];
        self.hasPreviousNext = self.hasPreviousNext;
    }
    return _inputAccessoryView;
}

- (void)setHasPreviousNext:(BOOL)hasPreviousNext {
    _hasPreviousNext = hasPreviousNext;
    self.inputAccessoryView.items = hasPreviousNext ? @[self.previousButton, self.nextButton, self.flexSpace, self.doneButton] : @[self.flexSpace, self.doneButton];
}

- (void)setInputFields:(NSArray *)inputFields {
    for (id input in _inputFields) {
        if ([input isKindOfClass:[UITextField class]]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:input];
            UITextField* textField = input;
            textField.inputAccessoryView = nil;
        } else if ([input isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:input];
            UITextView* textView = input;
            textView.inputAccessoryView = nil;
        } else if ([input isKindOfClass:[UISearchBar class]]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:input];
            UISearchBar *searchBar = input;
            searchBar.inputAccessoryView = nil;
        }
    }
    
    _inputFields = inputFields;
    
    for (id input in _inputFields) {
        if ([input isKindOfClass:[UITextField class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:input];
            UITextField* textField = input;
            textField.inputAccessoryView = self.inputAccessoryView;
        } else if ([input isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:input];
            UITextView* textView = input;
            textView.inputAccessoryView = self.inputAccessoryView;
        } else if ([input isKindOfClass:[UISearchBar class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:input];
            UISearchBar *searchBar = input;
            searchBar.inputAccessoryView = self.inputAccessoryView;
        }
    }
}

#pragma mark - actions & notification handlers

- (void)inputDidBeginEditing:(NSNotification*)notification {
    [self updatePreviousNextWithInputIndex:[self currentInputIndex]];
}

- (void)updatePreviousNextWithInputIndex:(NSUInteger)index {
    if (self.hasPreviousNext) {
        self.previousButton.enabled = [self previousVisibleControlIndex:index] != NSNotFound;
        self.nextButton.enabled = [self nextVisibleControlIndex:index] != NSNotFound;
    }
}

- (NSUInteger)currentInputIndex {
    return [self.inputFields indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isFirstResponder];
    }];
}

- (UIResponder*)currentInput {
    if (![_currentInput isFirstResponder]) {
        NSUInteger index = [self currentInputIndex];
        _currentInput = index != NSNotFound ? self.inputFields[index] : nil;
    }
    return _currentInput;
}

- (NSUInteger)previousVisibleControlIndex:(NSUInteger)index {
    if (index != NSNotFound) {
        while (index > 0) {
            index--;
            UIControl *control = self.inputFields[index];
            if (!control.hidden) {
                return index;
            }
        }
    }
    return NSNotFound;
}

- (NSUInteger)nextVisibleControlIndex:(NSUInteger)index {
    if (index != NSNotFound) {
        while (index < [self.inputFields count] - 1) {
            index++;
            UIControl *control = self.inputFields[index];
            if (!control.hidden) {
                return index;
            }
        }
    }
    return NSNotFound;
}

- (void)focusPrevious:(id)sender {
    NSUInteger index = [self previousVisibleControlIndex:[self currentInputIndex]];
    if (index != NSNotFound) {
        [self.inputFields[index] becomeFirstResponder];
        [self updatePreviousNextWithInputIndex:index];
    }
}

- (void)focusNext:(id)sender {
    NSUInteger index = [self nextVisibleControlIndex:[self currentInputIndex]];
    if (index != NSNotFound) {
        [self.inputFields[index] becomeFirstResponder];
        [self updatePreviousNextWithInputIndex:index];
    }
}

- (void)closeInput:(id)sender {
    [self.currentInput resignFirstResponder];
}

@end
