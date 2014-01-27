//  Created by Michael Kamphausen on 04.10.13.
//  Copyright (c) 2013 apploft GmbH. All rights reserved.
//

#import "APLKeyboardControls.h"
#import "NSData+Base64.h"

@interface APLKeyboardControls ()

@property (nonatomic, weak) UIResponder* currentInput;
@property (nonatomic, strong) UIBarButtonItem* flexSpace;
@property (nonatomic, strong) UIBarButtonItem *fixedSpace;

@end


@implementation APLKeyboardControls

NSString* const APLKeyboardControlsInputDidBeginEditingNotification = @"APLKeyboardControlsInputDidBeginEditingNotification";

#pragma mark - initialization

- (id)initWithInputFields:(NSArray*)inputFields {
    self = [super init];
    if (self) {
        self.inputFields = inputFields;
    }
    return self;
}

#pragma mark - properties

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

- (UIBarButtonItem *)fixedSpace {
    if (!_fixedSpace) {
        _fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        _fixedSpace.width = 20.;
    }
    return _fixedSpace;
}

- (UIBarButtonItem *)previousButton {
    if (!_previousButton) {
        
        _previousButton = [[UIBarButtonItem alloc] initWithImage:[self arrowImageWithName:@"leftArrowImage"] style:UIBarButtonItemStylePlain target:self action:@selector(focusPrevious:)];
    }
    return _previousButton;
}

- (UIBarButtonItem *)nextButton {
    if (!_nextButton) {
        _nextButton = [[UIBarButtonItem alloc] initWithImage:[self arrowImageWithName:@"rightArrowImage"] style:UIBarButtonItemStylePlain target:self action:@selector(focusNext:)];
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
    self.inputAccessoryView.items = hasPreviousNext ? @[self.previousButton, self.fixedSpace, self.nextButton, self.flexSpace, self.doneButton] : @[self.flexSpace, self.doneButton];
}

- (void)setInputFields:(NSArray *)inputFields {
    for (id input in _inputFields) {
        if ([input respondsToSelector:@selector(setInputAccessoryView:)]) {
            ((UITextField*)input).inputAccessoryView = nil;
            if ([input isKindOfClass:[UITextField class]]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:input];
            } else if ([input isKindOfClass:[UITextView class]]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:input];
            } else {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:input];
            }
        }
    }
    
    _inputFields = inputFields;
    
    for (id input in _inputFields) {
        if ([input respondsToSelector:@selector(setInputAccessoryView:)]) {
            ((UITextField*)input).inputAccessoryView = self.inputAccessoryView;
            if ([input isKindOfClass:[UITextField class]]) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:input];
            } else if ([input isKindOfClass:[UITextView class]]) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:input];
            } else {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:input];
            }
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

#pragma mark - inline images

/**
 *  Add left and right arrow images as previous/next controls
 *  We use base64Encoded strings that represent our desired images and decode them into NSData and after that create UIImage from data.
 *  The imageName param represents either leftArrowImage or rightArrowImage method name. We dynamically create a selector from this string
 *  and call the appropriate method to get the right base64Encoded image string
 *
 *  @param imageName Name of the image to create. leftArrowImage or rightArrowImage
 *
 *  @return A UIImage object with the desired image
 */
- (UIImage *)arrowImageWithName:(NSString *)imageName {
    if ([UIScreen mainScreen].scale == 2) {
        imageName = [imageName stringByAppendingString:@"2x"];
    }
    
    SEL imageMethodSelector = NSSelectorFromString(imageName);
    if ([self respondsToSelector:imageMethodSelector] == NO) {
        return nil;
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSData *decodedBase64Data = [[NSData alloc] initWithData:[NSData dataFromBase64String:[self performSelector:imageMethodSelector]]];
    #pragma clang diagnostic pop
    
    UIImage *buttonImage = [UIImage imageWithData:decodedBase64Data];
    return [UIImage imageWithCGImage:buttonImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
}

- (NSString *)leftArrowImage {
    return @"iVBORw0KGgoAAAANSUhEUgAAAAwAAAAVCAQAAADYpcc/AAAA30lEQVQoz2NgwABHTY+1bWPHEN6rfPLqkYdHpNCEj8iduHDi9RELdGGp42dOfDhigya8X+T48ROfjjiiCV8SPL7v1JdD7uiqBY7tOPXzsA+62bzHNp3+dTAcTXgn97FVp/8cjkUT3sZ3bNHp70eSMTx0ZNqV/4eXM2AJAOUj607/PJyPRWo/x7G5Z/4fLcIitY39+Kyz/w+VYZFaxXZs+tn/R0qxSJ1hPT4JKFWJzS6WI1OAUnVYpP4zH50AlGr6z4hpF/PRnrP/j3Ye48SQamA63nP00jlRrHYdFWNgAAALT2b7gSKqyQAAAABJRU5ErkJggg==";
}

- (NSString *)leftArrowImage2x {
    return @"iVBORw0KGgoAAAANSUhEUgAAABgAAAAqCAQAAAADzFPVAAABZElEQVRIx53VyyuEURjH8ZlkMEITSkpSSkopWSilLJSFhZXYuOaShchCspBioSQ1C2XLQiILl0RK8pUkSUlKUZIkkZDRuLxzPH/AL+fdfr6dxXuec3w+aeFnhi6fujw+zQ/ftKs87PHYN6sFU8bniVP4pPEFjY8bXyRe4WPGlwkofMT4isaHja9rfMj4BgkKHzC+SZLC+41vE1R4r/Edjfd4JybGd0lWeLfxPVIU3mF8nzSFtxk/1HgLX44fabyRqOPHhBTeYPyEdIXXGT8lU5unJftR52RrQYA1Sy7JVZNOIi65Jl+9SGr4cMkthWpSxZtL7ilWkwpeXPJIqZqU8eSSZ8rVpIQHl7xSqSZF3LnknWo1KeDGJRFq1SSPK5d8Uq8mOVy4JEqTmmRx5pJv+SEhw5uPv6RPTUIc2MEcVJNU78L5S0bVJMiWJRP4tSSRVUvC6i4BN5dfNOsPbxxztPr+s34BfdlgDgC+gwgAAAAASUVORK5CYII=";
}

- (NSString *)rightArrowImage {
    return @"iVBORw0KGgoAAAANSUhEUgAAAAwAAAAVCAQAAADYpcc/AAAA00lEQVQoz2M4aneou4GJARMcbTn1/2jPKmYMif0sx5rO/j86YT8LFl1H6s7+PzZ5Jis2qSqg1PQz2KQOlwMNnLaKDZtUEVBq1jZ2LFIHS4AGzt3PgU1X/pn/xxaeF8AidSjz1L+jh08KY+qJPf3v2MojvOjOjjr9+/iaqzzoxoSc/nlsy25+dDd5nfp+bPdhQXSzXU5+PnYQw9Kjdic/HDu1Uwxd2PL4u+Pn9sugu8Tk+Kvjl/croKt2Ov70xPWDqpgB3n7iykFNLEGwn+WQKBZhBgCyn2XLw2syLwAAAABJRU5ErkJggg==";
}

- (NSString *)rightArrowImage2x {
    return @"iVBORw0KGgoAAAANSUhEUgAAABgAAAAqCAYAAACpxZteAAABjklEQVRIx7XXP4jIYRzH8d91OpzQhVJSDJIySCmDLLLIYlEMcsi/QeoGww0yUAaUpKxSStziTyIleUmSpCSDJEVRRMjl7lhOPX3nzz31rK93v+F5vr+n67quwy5cQm+XXtiJcfzFNfSlA+cm8f/7BmYkAz04XSJ30Z/+khMl8gBz0pHhEnmMgXRkCBNN5BnmpyMHSuQlFqYjgxhrIq+xOB3Zhj9N5C2WpiNbMNpE3mN5OrIJv5rIR6xMRzbgRxP5jNXpyDp8ayJfsTYdWYMvTeQ71qcjq/CpifzExnRkBT40kd/YnI4sw7smMop90ZmCJXhTLsmb6cgivCqRkWRgAV40+Bi2pvB5eF7w7Sl8YHJetPiOFD4XTxt8HINJ/EmDT2B3En9U8L0pfDYeFvxgCp81+SvT4odSeD/ul4N0OInfK/hQCp+JOwU/ksKn43bBh1N4H24V/GgSv17wY0l8pODHU/g0XC34yRTeiysFP5XELxf8THIaXSz4WfQkA3uat8D5KN5E9uPClOBTvf4BgaTTHtNq9/UAAAAASUVORK5CYII=";
}
@end
