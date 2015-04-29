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
        UIImage *leftArrowImage = [[self arrowImageWithName:@"leftArrowImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _previousButton = [[UIBarButtonItem alloc] initWithImage:leftArrowImage style:UIBarButtonItemStylePlain target:self action:@selector(focusPrevious:)];
    }
    return _previousButton;
}

- (UIBarButtonItem *)nextButton {
    if (!_nextButton) {
        UIImage *rightArrowImage = [[self arrowImageWithName:@"rightArrowImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _nextButton = [[UIBarButtonItem alloc] initWithImage:rightArrowImage style:UIBarButtonItemStylePlain target:self action:@selector(focusNext:)];
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
                [[NSNotificationCenter defaultCenter] removeObserver:self name:APLKeyboardControlsInputDidBeginEditingNotification object:input];
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
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputDidBeginEditing:) name:APLKeyboardControlsInputDidBeginEditingNotification object:input];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    if (screenScale > 1) {
        NSString *suffix = [NSString stringWithFormat:@"%dx", (NSInteger)screenScale];
        imageName = [imageName stringByAppendingString:suffix];
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
    return @"iVBORw0KGgoAAAANSUhEUgAAAAwAAAAWCAQAAABeMbWRAAAAzklEQVQoz22QvQ4BURCFRywRWSSEkFAoNBQ03kGjoCCRkEj8xE8I+wKeQQh3znAb1b4klebuTPmdk5k5h0gZbpmEgm0XwasddXcQSI9iDn43ETz7XxfbBp95EMYdjLqceHTx3CU1Ocok8o2p4CBTm3LdRbPH3KQdLHlsZHH3HXz3zZq3YS4SKIxjyGfbUCq4eBjLCXVFCpMykSOqWnEpzHCwZUUyacyxexcV6ZXhJTaS127lZI3VJ6tItwJvTTQsEdGjpNbzL5RbpM01S/QDwjtDOUu9838AAAAASUVORK5CYII=";
}

- (NSString *)leftArrowImage2x {
    return @"iVBORw0KGgoAAAANSUhEUgAAABgAAAAsCAQAAADVlbDIAAABoElEQVRIx52U2UpCURSGz3GszMwMIyqKRiopGygKQQgkMGlAmieaVMzK4QW8F7qIUs/e+yR16QP4eqZr7wf4bZ3b7197rXXW+jUNDqNH6yTMLZYqe2Gcr/FC60uAr/Alwgss1tQRfN6Q+FHdCuBimuUJPynaALwywbNtXFwYdqSYUfZG+HXDieBD7IWavYNmYwzyZ8r++NUL4GUvS7VxI2l4APyjjydoMmkxAOAlF3+g7JmKH8Dfu8UttfpqDAN43cGvCM9+jyGTsbMzmkyuPIlkt5pxajXPZgG8aOEHaicXkQ3WeVTiYgXb+IjCNyCchSVuhjA8qLLvgfdacol7EmR+/aDEdMvdEelPHyip9cvtFMm6B5T8+ESa/sKT6Ua9p7MLo5MfkTfMb2pdoESMS5dgl3UHarlTIkevnELGQkOeU04Xh5yOCguovd0vWtDCVqWERzUdlWwqSURDwwypwsKwhO8oyTaq0NmuupR1UNHUWUxKqsugpGgRh+SDheoCKrEZx9J+ajPoiO38XPohZP3taDjbFsqCGh4tkw5o/4k/hvrXE+ZABCgAAAAASUVORK5CYII=";
}

- (NSString*)leftArrowImage3x {
    return @"iVBORw0KGgoAAAANSUhEUgAAACQAAABCCAYAAAA/rXTfAAACw0lEQVR42u2aWWuTURCGU7dqXSIVInWpVqnRWncUkSoWtVRccd/3khpiW+sfyC/IRci+QshVfkD+XnznQijhPRfezPtd9MAQ+JKP8zAzZ847Q2Kba8NqNptzlUplJhIw9Xr9OuxPrVZbb7fb01KYarV62WD+WaPR+I3PKQkMNp81iGGDpx4qciZpIRqGAeTLbDa7zRWm1WqdsNAQ77xFCLe7wnQ6nUlsvEY887Hf7496h+kQNl8hnvkKz4x5eyYBL2SIZ34Ui8U9rjCFQuEANk4Pw8ArKVjcFabX68UBkyJHO43n4945sxcbLxHPZMrlcsK7Ao9ZspIEXsF3E64wuI92YuNPJIFXUYOOeufMDmz8zgDkd5SVfOTMK5LA67BT3p7Zis2fBS7Ls96e2YKQPArAXIw5rxHALDIYPL+m0DR3GAyO9pxCet5kMCiI8xodzGEWLIwCHcyl52AwcIc5F0jgp3bavGFOw1gCu+tggzkZGR0MkGNMByNn/HUwdMthbLwaCR2MTQ8C5hfJmWjp4G63u89bYO2HZ5ZJmH6aDlZU4Q+s1ljHSX6uyx3Yd/RXu1VQR9jpwrMvuVxulwQKR/44qz8W0nw+PyqBwphtmo1N8OyNVWhV+M6wOwz2wu4wFdT5gDIkt7wf1JWA9HhAdJBWKcJTCzHVgkduBaDmZVA4ZXd13QZfI4C6L+zHeMcKqMcBqEvklcj19PqpR6lUSpJXtHMhIlu0kzPYGk7fJHlFO1u0wbkEyhoAG4iT8GVsgK7yVByWIlBpayBUV8y4DcjJ6Vu2RkKlOhM2KCdQSzZYV4VvwpKahO+bHQIJlA3MbXBOoD5buVBpqSk2QUHo3lthVRVP2jTAXsuaBoRvJjCffG6XteqfDBcYFOyJrGlA6K4GtNSiUgrfGJLAFrqk+r8ftzd4Z1aAQKHu2fw7trn+Y/0F7VT4viogMqgAAAAASUVORK5CYII=";
}

- (NSString *)rightArrowImage {
    return @"iVBORw0KGgoAAAANSUhEUgAAAAwAAAAWCAQAAABeMbWRAAAAx0lEQVR4AW2QU8JDUQyEf9u2ba7ht20b1QbuFuqeTOo+nUUWz+dmHr8kM0mKVDnNFkmKLsITX5cqxbwJDy0JlVxxZA+e2IxQ0qV0RO74uFCyyuicXRgWSqqcr9kR6xdK8Sq+w7/qlqZq8KR+Y+1CKVjHr/jiFmnDRvpWH8E6e9I4uXGsSw2MYXbhwiozcR87+FpXmCZd+Md9vMrAsXb84EnVGJhb8EVv0XoDZxrwzh+60XaUeqXvQKv4hnBHkSmalR9XkK9Bonk7ikM5YrTXEwAAAABJRU5ErkJggg==";
}

- (NSString *)rightArrowImage2x {
    return @"iVBORw0KGgoAAAANSUhEUgAAABgAAAAsCAQAAADVlbDIAAABhUlEQVR4Aa2URWI0IRSE+4+7u7u7u7u7u7teYNZxT4DXseUcYI4XaeAAleSv3tYHNNQrwxLzMn6ih0C+YVbCduYl1sTx91cMAp//eI8EjkUeiNid+aAFsGORCSI2Fz5mIfyIUkCEudKUPNbBYwKIONxpVu6yL2Lw+1qUyK4IB5F7H1qRB9tmIegu/mxd7rLxEAgiFMS35C5rN34g8hjGdiSyfOqNHixS7FkIzV94gshzrDiQu8zY3dAMJ9Gh/P0J5goiPI0fWYg5bHdGkWyd436bE4hQoUa6jH8oUqaRVgOVWaMQXg8j1K2RAsj+Hkby5WkJevm7YNLZMn2Refcnnd6XAOR3ffmqPMzWW/D/n8AXDzGnZvwxGjm7G59WLULxUOmIcXn2Q5aMNeGwakIzHWlBJ96n3pVyDED/RJeysyIDkWjV9nJsYOqV3azB7FU6+U1Y6kt0hNuh2XrK1/aeT8iexaSdBqBhf0lVdcJGbS5QxeuOm8QLq8CqRIe7gYty4NL9ub4AvfvXEzLeIocAAAAASUVORK5CYII=";
}

- (NSString *)rightArrowImage3x {
    return @"iVBORw0KGgoAAAANSUhEUgAAACQAAABCCAQAAACVpLxUAAACE0lEQVR4Ad2XRcLcMAxGM1NmZmZmZmbGn5mZLpALlCEjSx5e5QA9XrmVvZZcVPbP/PQlCly5nfZ0AExhixnHCTyuxOAGGsOJrx8cVIHMbZz4+dFuBSieTE9+gsy43aZAwRSs4zmN5TcqUB+mURMvcLS8VjOrmdjGqGG7UoF6N5s6eYGD5aWaWc2DHkb1v12kQNFC08+onnSeApUshUG+DF12jmaBK3CYt70NZipQ+TU0wqjmwnTl++O9qk+nal7gVjPOe/U0nqxB7cIJ/h6mkzSo/Q5Fd+KsAkVHPdT1KKNAwWkPdSnSlL3gUHhGQ8rYqwzSmf1ThnWsNXucpfseao/K7PCEQROwPZjZYZPK7MYzO60LZHYzkqxSmR06GTWEyxSo6tyAZsc+nlVvYb7GoRu9u94oxpRnYUeAfXo+w7S6k8PVQszradjo7lKyXny7Ta2LQLkt4veGj917wx1iA4BnANwrdhLd8jCH5K8sjCXB8zadDdJJzOUgvc3cEPc2OuBh7sbZP9v/32/TJRJWRZCMBGtxNEBqsyuD5MjyUuJkS53vZgsxbxcRZ23oAWnWLsw3vXxS/bRQujdzTBfPZjBZKu6j1O7+kGCFdFHTqYW3eCS/RohJp9oGlzVwgzyy1DipF6RSTyfZR+5x5neKpY73HMbuk4vrusOYI5ocvQ1+Yk5GuqLd30DnI33BQbwS/Wf1GSZDwFrdLRGJAAAAAElFTkSuQmCC";
}

@end
