//  Created by Michael Kamphausen on 04.10.13.
//  Copyright (c) 2013 apploft GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APLKeyboardControls : NSObject

@property (nonatomic, strong) NSArray* inputFields;
@property (nonatomic, assign) BOOL hasPreviousNext;
@property (nonatomic, strong) UIBarButtonItem* previousButton;
@property (nonatomic, strong) UIBarButtonItem* nextButton;
@property (nonatomic, strong) UIBarButtonItem* doneButton;
@property (nonatomic, strong) UIToolbar* inputAccessoryView;

- (id)initWithInputFields:(NSArray*)inputFields;

- (void)focusPrevious:(id)sender;
- (void)focusNext:(id)sender;

@end
