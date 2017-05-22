//
//  OEXRegistrationFormTextField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormTextField.h"
#import "OEXRegistrationFieldWrapperView.h"
#import "OEXStyles.h"
#import "OEXTextStyle.h"
#import "UIColor+OEXHex.h"

@interface OEXRegistrationFormTextField () <UITextFieldDelegate>

@property (strong, nonatomic) OEXRegistrationFieldWrapperView* registrationWrapper;
@property (strong, nonatomic) UIView* lineView;
@property (nonatomic) OEXTextStyle *placeHolderStyle;

@end

static NSString* const textFieldBackgoundImage = @"bt_grey_default.png";
static NSInteger const textFieldHeight = 52;

@implementation OEXRegistrationFormTextField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textInputView = [[SMFloatingLabelTextField alloc] initWithFrame:CGRectZero];
        self.textInputView.font = [UIFont systemFontOfSize:16];
        self.textInputView.textColor = [[UIColor alloc] initWithHexString:@"#9B9B9B" alpha:1.0];
        self.textInputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textInputView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textInputView.delegate = self;
        _placeHolderStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[UIColor alloc] initWithHexString:@"#B9B9B9" alpha:0.5]];

        self.textInputView.floatingLabelActiveColor = [[UIColor alloc] initWithHexString:@"#B9B9B9" alpha:0.5];
        self.textInputView.floatingLabelPassiveColor = [[UIColor alloc] initWithHexString:@"#B9B9B9" alpha:0.5];
        self.textInputView.floatingLabelFont = [UIFont systemFontOfSize:14];

        [self addSubview:self.textInputView];
        
        self.registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:self.registrationWrapper];

        self.lineView = [[UIView alloc] init];
        self.lineView.backgroundColor = [[UIColor alloc] initWithHexString:@"#1D1D26" alpha:0.05];

        [self addSubview:self.lineView];
        
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat paddingHorizontal = 25;
    CGFloat frameWidth = self.bounds.size.width - 2 * paddingHorizontal;
    NSInteger paddingTop = 0;
    CGFloat offset = paddingTop;
    CGFloat paddingBottom = 15;

    CGRect viewFrame = CGRectMake(paddingHorizontal, paddingTop, frameWidth, textFieldHeight);
    self.textInputView.frame = CGRectInset(viewFrame, 0, 0);

    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[[UIColor alloc] initWithHexString:@"#B9B9B9" alpha:0.5] forKey:NSForegroundColorAttributeName];
    [attributes setObject:[UIFont systemFontOfSize:16] forKey:NSFontAttributeName];

    NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.placeholder attributes:attributes];

    [self.textInputView setAttributedPlaceholder:text];

    self.textInputView.accessibilityHint = self.instructionMessage;
    offset = offset + textFieldHeight;

    self.lineView.frame = CGRectMake(0, offset, self.frame.size.width, 1);

    [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];

    offset += 5;

    [self.registrationWrapper setFrame:CGRectMake(0, offset, self.bounds.size.width, self.registrationWrapper.frame.size.height)];
    [self.registrationWrapper setNeedsLayout];
    [self.registrationWrapper layoutIfNeeded];

    if([self.errorMessage length] > 0 || [self.instructionMessage length] > 0) {
        offset = offset + self.registrationWrapper.frame.size.height;
    }
    CGRect frame = self.frame;
    frame.size.height = offset + paddingBottom;
    self.frame = frame;

    [super layoutSubviews];
}

- (void)takeValue:(NSString *)value {
    if(value) {
        self.textInputView.text = value;
    }
}

- (NSString*)currentValue {
    return self.textInputView.text;
}

- (void)clearError {
    self.lineView.backgroundColor = [[UIColor alloc] initWithHexString:@"#1D1D26" alpha:0.05];
    self.errorMessage = nil;
}

- (void)setErrorMessage:(NSString*)errorMessage {
    self.lineView.backgroundColor = [UIColor magentaColor];

    _errorMessage = errorMessage;

    if ([_errorMessage length] > 0) {
        [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:@""];
    } else {
        self.lineView.backgroundColor = [[UIColor alloc] initWithHexString:@"#1D1D26" alpha:0.05];

        [self.registrationWrapper setRegistrationErrorMessage:self.errorMessage instructionMessage:self.instructionMessage];
    }

    [self.registrationWrapper layoutIfNeeded];
    [self setNeedsLayout];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField isEqual:self.textInputView] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = self.placeholder;
    }
    else if([textField isEqual:self.textInputView] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    return YES;
}


@end
