//
//  GVRTransitionView.m
//  edX
//
//  Created by Suman Roy on 15/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import "GVRTransitionCounterView.h"
#import "OEXStyles.h"
#import <Masonry/Masonry.h>

@interface GVRTransitionCounterView ()

@property (nonatomic, strong) UILabel *countTimerLabel;
@property (nonatomic, strong) UILabel *transitionMessage;
@property (nonatomic, strong) UIImageView *cardboardView;
@property (nonatomic, strong) UIImageView *arrowView;
@property (nonatomic, strong) UIImageView *phoneView;
@property (nonatomic, strong) NSTimer *countDownTimer;
@property (nonatomic, strong) void (^timerCompletionBlock)(void);
@property (nonatomic) int timerLimit;
@property (nonatomic) int timerCount;

@end

@implementation GVRTransitionCounterView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.countTimerLabel = [[ UILabel alloc ] init ];
        [ self.countTimerLabel setFont: [UIFont systemFontOfSize:130] ];
        [ self.countTimerLabel setTextColor: [ UIColor colorWithRed:0.0 green:253.0/255.0 blue:190.0/255.0 alpha:1.0] ];
        [ self.countTimerLabel setText:@"10" ];
        
        self.transitionMessage = [[ UILabel alloc ] init ];
        [ self.transitionMessage setFont: [[ OEXStyles sharedStyles ] raleWayOfSize:20 ] ];
        [ self.transitionMessage setTextColor: [ UIColor whiteColor ] ];
		[ self.transitionMessage setText:@"Place your device\ninto the VR Viewing Device" ];
        [ self.transitionMessage setNumberOfLines:0 ];
		[ self.transitionMessage setTextAlignment:NSTextAlignmentCenter ];
        [ self.transitionMessage setLineBreakMode: NSLineBreakByWordWrapping ];

		self.arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Arrow"]];
		[self addSubview:self.arrowView];

		self.cardboardView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"virtual-reality"]];
		[self addSubview:self.cardboardView];

		self.phoneView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"smartphone"]];
		[self addSubview:self.phoneView];


        [ self setHidden:true ];
        self.backgroundColor = [[ UIColor blackColor ] colorWithAlphaComponent:0.75 ];
        
        [ self addSubview:self.countTimerLabel ];
        [ self bringSubviewToFront: self.countTimerLabel ];
        
        [ self addSubview:self.transitionMessage ];
        [ self bringSubviewToFront: self.transitionMessage ];
        
        UITapGestureRecognizer *dismissTap = [[ UITapGestureRecognizer alloc ] initWithTarget:self action:@selector(dismissView) ];
        [ self addGestureRecognizer:dismissTap ];
        
    }
    return self;
}

+ (BOOL)requiresConstraintBasedLayout {
    
    return true;
}

- (void)updateConstraints {
    
    [ self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.superview);
    } ];
    
    [ self.countTimerLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY).offset(-55);
    } ];
    
    [ self.transitionMessage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
		make.top.equalTo(self.countTimerLabel.mas_bottom);
    } ];

	[ self.arrowView mas_remakeConstraints:^(MASConstraintMaker *make) {
		make.centerX.equalTo(self.mas_centerX).offset(10.0);
		make.top.equalTo(self.transitionMessage.mas_bottom).offset(29);
	} ];

	[ self.cardboardView mas_remakeConstraints:^(MASConstraintMaker *make) {
		make.trailing.equalTo(self.arrowView.mas_leading).offset(-5);
		make.top.equalTo(self.transitionMessage.mas_bottom).offset(24);
	} ];

	[ self.phoneView mas_remakeConstraints:^(MASConstraintMaker *make) {
		make.leading.equalTo(self.arrowView.mas_trailing).offset(5);
		make.top.equalTo(self.transitionMessage.mas_bottom).offset(23);
	} ];


    [ super updateConstraints ];
}

- (void) startCountdownFrom: (int)timer withCompletion:( void (^) () )completion{
    self.timerCompletionBlock = completion;
    self.timerLimit = timer;
    self.timerCount = 0;
    self.countTimerLabel.text = [ NSString stringWithFormat:@"%d", timer ];
    self.countDownTimer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCountdownLabel) userInfo:NULL repeats:true ];
    
}

-(void)updateCountdownLabel {
    
    ++self.timerCount;
    if ( self.timerCount == self.timerLimit ){
        
        [ self.countDownTimer invalidate ];
        self.timerCompletionBlock();
    } else {
         self.countTimerLabel.text = [ NSString stringWithFormat:@"%d", self.timerLimit - self.timerCount ];
    }
    
}

-(void)dismissView {
    
    if( self.countDownTimer.valid ){
        [ self.countDownTimer invalidate ];
        [ self setHidden:true ];
    }
    
}

@end
