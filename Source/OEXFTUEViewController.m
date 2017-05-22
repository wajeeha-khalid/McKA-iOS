//
//  OEXFTUEViewController.m
//  edX
//
//  Created by Naveen Katari on 23/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "OEXFTUEViewController.h"
#import "OEXPageContentViewController.h"
#import "edX-Swift.h"

#import "OEXRouter.h"

@interface OEXFTUEViewController ()<UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate>{
    NSUInteger currentIndex;
}
@property (weak, nonatomic) IBOutlet UIPageControl *welcomePageControl;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *pageControllerHolderView;
@property (strong, nonatomic) NSArray *slides;
@property (strong, nonatomic) NSArray *slidesText;
@property (nonatomic, weak) NSTimer *slidesScrollTimer;
@property (weak, nonatomic) IBOutlet UIView *signInContainerView;
@property (strong, nonatomic) RouterEnvironment* environment;
@property (weak, nonatomic) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation OEXFTUEViewController

- (id)initWithEnvironment:(RouterEnvironment*)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    currentIndex = 0;
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    self.slides = @[@"FTUE1",
                    @"FTUE2",
                    @"FTUE3",
                    @"FTUE4",
                    @"FTUE5"
                    ];
    self.slidesText = @[@"Build your management and leadership skills, learning from leading global experts",               @"Immerse yourself in the sites of innovation, as if you were there, and experience the latest management hacks",
                        @"Learn on your own terms, whenever you have a slice of time, wherever you are",
                        @"Apply your insights in the real world and practice in real time",
                        @"Join the conversation with your cohort and receive guidance from your teaching assistants"];
    OEXPageContentViewController *startingViewController = [self viewControllerAtIndex:currentIndex];
    NSArray *viewControllers;
    if (startingViewController) {
        viewControllers = @[startingViewController];
    }else{
        viewControllers = @[[OEXPageContentViewController new]];
    }
    
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    
    self.pageControllerHolderView.frame = self.pageViewController.view.frame;
    [self addChildViewController:_pageViewController];
    [_pageControllerHolderView addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    for (UIView *view in self.pageViewController.view.subviews ) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scroll = (UIScrollView *)view;
            self.scrollView = scroll;
            self.scrollView.delegate = self;

        }
    }
    [self.view bringSubviewToFront:_welcomePageControl];
    [self.view bringSubviewToFront:self.signInContainerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (OEXPageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
//    if ((index <= 0) || (index >= [self.slides count] - 1)) {
//        self.scrollView.bounces = NO;
//    }
//    else{
//        self.scrollView.bounces = YES;
//    }
    
    OEXPageContentViewController *pageContentViewController = [[OEXPageContentViewController alloc]initWithNibName:@"OEXPageContentViewController" bundle:nil];
    
    pageContentViewController.imageName = self.slides[index];
    pageContentViewController.tutorialText = self.slidesText[index];
    pageContentViewController.pageIndex = index;
    return pageContentViewController;
}

#pragma mark -
#pragma mark - Page View Controller DataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((OEXPageContentViewController *) viewController).pageIndex;
    
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((OEXPageContentViewController *) viewController).pageIndex;
    
    index++;
    if (index == [self.slides count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}
#pragma mark -
#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    OEXPageContentViewController *currentViewController = pageViewController.viewControllers[0];
    currentIndex = (int)currentViewController.pageIndex;
    [_welcomePageControl setCurrentPage:currentIndex];
}
- (IBAction)signInButtonAction:(id)sender {
     [self.environment.router showLoginScreenFromController:self completion:nil];
}
- (IBAction)registerButtonAction:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:FTUE];

     [self.environment.router showSignUpScreenFromController:self completion:nil];
}

#pragma mark - Scroll View delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width) {
        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
    else if (currentIndex == self.slides.count-1 && scrollView.contentOffset.x > scrollView.bounds.size.width) {
        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width) {
        *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
     else if (currentIndex == self.slides.count-1 && scrollView.contentOffset.x >= scrollView.bounds.size.width) {
        *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
}


@end
