//
//  OEXRegistrationFieldPasswordController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldPasswordController.h"
#import "OEXRegistrationFieldPasswordView.h"
#import "OEXRegistrationFieldValidator.h"

@interface OEXRegistrationFieldPasswordController ()
@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong) OEXRegistrationFieldPasswordView* view;
@end

@implementation OEXRegistrationFieldPasswordController
- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field {
    self = [super init];
    if(self) {
        self.field = field;
        self.view = [[OEXRegistrationFieldPasswordView alloc] init];
        self.view.instructionMessage = field.instructions;
        self.view.placeholder = field.label;
    }
    return self;
}

- (NSString*)currentValue {
    return [[self.view currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)takeValue:(NSString*)value {
    [self.view takeValue:value];
}

- (BOOL)hasValue {
    return [self currentValue] && ![[self currentValue] isEqualToString:@""];
}

- (void)handleError:(NSString*)errorMsg {
    [self.view setErrorMessage:errorMsg];
}

- (BOOL)isValidInput {

    if ( ![self strongPassword:[self currentValue]] ) {
        [self handleError:@"Must be 8 characters and a mix of letters and numbers,\nupper/lower cases or special characters"];
        return NO;
    }
    return YES;
}

-  (UIView*)accessibleInputField {
    return self.view.textInputView;
}

- (BOOL)strongPassword:(NSString *)yourText
{
    BOOL strongPwd = NO;

    //Checking length
    if([yourText length] < 8)
        return NO;

    //Checking uppercase characters
    NSCharacterSet *charSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSRange range = [yourText rangeOfCharacterFromSet:charSet];

    BOOL hasUppercase = YES;
    if(range.location == NSNotFound)
        hasUppercase = NO;

    //Checking lowercase characters
    charSet = [NSCharacterSet lowercaseLetterCharacterSet];
    range = [yourText rangeOfCharacterFromSet:charSet];

    BOOL hasLowercase = YES;
    if(range.location == NSNotFound)
        hasLowercase = NO;

    charSet = [NSCharacterSet
               characterSetWithCharactersInString:@"0123456789"];
    range = [yourText rangeOfCharacterFromSet:charSet];

    BOOL hasNumbers = YES;
    if(range.location == NSNotFound)
        hasNumbers = NO;

    NSString *specialCharacterString = @"!~`@#$%^&*-+();:={}[],.<>?\\/\"\'";
    charSet = [NSCharacterSet
               characterSetWithCharactersInString:specialCharacterString];
    range = [yourText rangeOfCharacterFromSet:charSet];

    BOOL hasSymbols = YES;
    if(range.location == NSNotFound)
        hasSymbols = NO;

    if ( (hasLowercase || hasUppercase) && hasNumbers ) {
        strongPwd = YES;
    }
    else if ( hasLowercase && hasUppercase ) {
        strongPwd = YES;
    }
    else if ( (hasLowercase || hasUppercase) && hasSymbols ) {
        strongPwd = YES;
    }

    return strongPwd;
}

@end
