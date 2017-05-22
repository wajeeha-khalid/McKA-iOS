//
//  OEXDownloadViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXDownloadViewController.h"

#import "edX-Swift.h"

#import "NSString+OEXFormatting.h"
#import "OEXAppDelegate.h"
#import "OEXCustomLabel.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadTableCell.h"
#import "OEXOpenInBrowserViewController.h"
#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXCustomButton.h"

#define RECENT_DOWNLOADEDVIEW_HEIGHT 76

@interface OEXDownloadViewController ()

@property(strong, nonatomic) NSMutableArray* downloads;
@property(strong, nonatomic) OEXInterface* edxInterface;
@property (strong, nonatomic) IBOutlet UITableView* table_Downloads;
@property (strong, nonatomic) IBOutlet OEXCustomButton *btn_View;
@property (strong, nonatomic) NSNumberFormatter* percentFormatter;
@property (nonatomic,assign) BOOL isAudioType;

@end

@implementation OEXDownloadViewController

- (IBAction)navigateToDownloadedVideos {
    [[OEXRouter sharedRouter] showMyVideos];
}

#pragma mark - REACHABILITY

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadEndedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self downloadCompleteNotification:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    // Do any additional setup after loading the view.
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Downloads setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    //Initialize Downloading arr
    self.downloads = [[NSMutableArray alloc] init];

    _edxInterface = [OEXInterface sharedInterface];

    [self reloadDownloads];
    // set the custom navigation view properties
    self.title = [Strings downloads];

    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:OEXDownloadEndedNotification object:nil];
    
    [self.btn_View setClipsToBounds:true];
    self.percentFormatter = [[NSNumberFormatter alloc] init];
    self.percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    
}

- (void)reloadDownloads {
    [self.downloads removeAllObjects];

	NSArray* array = [NSArray array];
	array = [array arrayByAddingObjectsFromArray:[_edxInterface coursesAndVideosForDownloadState:OEXDownloadStatePartial]];
	array = [array arrayByAddingObjectsFromArray:[_edxInterface coursesAndAudiosForDownloadState:OEXDownloadStatePartial]];
    
    NSMutableDictionary* duplicationAvoidingDict = [[NSMutableDictionary alloc] init];

    for(NSDictionary* dict in array) {
		NSArray* downloads = [NSArray array];
		downloads = [downloads arrayByAddingObjectsFromArray:[dict objectForKey:CAV_KEY_VIDEOS]];
		downloads = [downloads arrayByAddingObjectsFromArray:[dict objectForKey:CAV_KEY_AUDIOS]];

        for(id<OEXDownloadInterface> download in downloads) {
            if(download.downloadProgress < OEXMaxDownloadProgress) {
                [self.downloads addObject:download];
                if (download != nil && download.summary != nil) {
                    NSString* key = download.summary.url;
                    self.isAudioType = NO;
                    if (key) {
                        duplicationAvoidingDict[key] = @"object";
                    }
                }
            }
        }
    }

    [self.table_Downloads reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.downloads count];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 78;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXDownloadTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CellDownloads" forIndexPath:indexPath];

    [self configureCell:cell forIndexPath:indexPath];
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)configureCell:(OEXDownloadTableCell*)cell forIndexPath:(NSIndexPath*)indexPath
{
	if([self.downloads count] <= indexPath.row) {
		return;
	}

	id<OEXDownloadInterface> download = [self.downloads objectAtIndex:indexPath.row];
	
	
	NSString* downloadName = download.summary.name;
	if([downloadName length] == 0) {
		downloadName = @"(Untitled)";
	}
	cell.lbl_title.text = downloadName;
	
	
	NSString *downloadUrlString = download.summary.url;
	
	
	dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
				   {
					   AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:downloadUrlString] options:nil];
					   CMTime duration = sourceAsset.duration;
					   
					   NSUInteger durationSeconds = (long)CMTimeGetSeconds(duration);
					   NSUInteger dHours = floor(durationSeconds / 3600);
					   NSUInteger dMinutes = floor(durationSeconds % 3600 / 60);
					   NSUInteger dSeconds = floor(durationSeconds % 3600 % 60);

					   dispatch_async(dispatch_get_main_queue(), ^{
						   if(durationSeconds == 0) {
							   cell.lbl_time.text = @"NA";
						   }
						   else {

							   if(dHours > 0)
							   {
								   cell.lbl_time.text   = [NSString stringWithFormat:@"%lu:%02lu:%02lu",(unsigned long)dHours, (unsigned long)dMinutes, (unsigned long)dSeconds];
							   }
							   else
							   {
								   cell.lbl_time.text   = [NSString stringWithFormat:@"%02lu:%02lu",(unsigned long)dMinutes, (unsigned long)dSeconds];
							   }
						   }
					   });
				   });

	
	
	float result = (([download.size doubleValue] / 1024) / 1024);
	cell.lbl_totalSize.text = [NSString stringWithFormat:@"%.2fMB", result];
	float progress = (float)download.downloadProgress;
	[cell.progressView setProgress:progress];
	//
	cell.btn_cancel.tag = indexPath.row;
	cell.btn_cancel.accessibilityLabel = [Strings cancel];
	
	[cell.btn_cancel addTarget:self action:@selector(btnCancelPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	cell.accessibilityLabel = [self downloadStatusAccessibilityLabelForVideoName:downloadName percentComplete:(progress / OEXMaxDownloadProgress)];
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(OEXDownloadTableCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    float progress = 0.0;
	id<OEXDownloadInterface> download = [self.downloads objectAtIndex:indexPath.row];
	progress = (float)download.downloadProgress / OEXMaxDownloadProgress;

    [cell.progressView setProgress:progress];
}

- (void)downloadProgressNotification:(NSNotification*)notification {
    NSDictionary* progress = (NSDictionary*)notification.userInfo;
    NSURLSessionTask* task = [progress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
    NSString* url = [task.originalRequest.URL absoluteString];
    
	for(id<OEXDownloadInterface> download in self.downloads) {
		if([download.summary.url isEqualToString:url] || [download.summary.url containsString:url]) {
			[self updateProgressForVisibleRows];
			break;
		}
	}
}

- (void)downloadCompleteNotification:(NSNotification*)notification {
}

/// Update progress for visible rows

- (NSString*)downloadStatusAccessibilityLabelForVideoName:(NSString*)video percentComplete:(double)percentage {
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterPercentStyle;
    NSString* formatted = [formatter stringFromNumber:@(percentage)];
    return [Strings accessibilityDownloadViewCell:video percentComplete:formatted](percentage);
}

- (void)updateProgressForVisibleRows {
    NSArray* array = [self.table_Downloads visibleCells];

    BOOL needReload = NO;

	if(![self.table_Downloads isDecelerating] || ![self.table_Downloads isDragging]) {
		for(OEXDownloadTableCell* cell in array) {
			NSIndexPath* indexPath = [self.table_Downloads indexPathForCell:cell];
			id<OEXDownloadInterface> download = [self.downloads objectAtIndex:indexPath.row];
			float progress = download.downloadProgress;
			cell.progressView.progress = progress / OEXMaxDownloadProgress;
			if(progress == OEXMaxDownloadProgress) {
				needReload = YES;
			}
			float result = (([download.size doubleValue] / 1024) / 1024);
			cell.lbl_totalSize.text = [NSString stringWithFormat:@"%.2fMB", result];


			cell.accessibilityLabel = [self downloadStatusAccessibilityLabelForVideoName:download.summary.name percentComplete:(progress / OEXMaxDownloadProgress)];
		}
	}

	if(needReload) {
		[self.downloads removeAllObjects];
		[self reloadDownloads];
	}
}

- (IBAction)btnCancelPressed:(UIButton*)button {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
     OEXInterface* edxInterface = [OEXInterface sharedInterface];

	if(indexPath.row >= [self.downloads count]) {
		return;
	}

	id<OEXDownloadInterface> download = [self.downloads objectAtIndex:indexPath.row];

	[self.table_Downloads beginUpdates];
	[self.table_Downloads deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
	[self.downloads removeObjectAtIndex:indexPath.row];
	[self.table_Downloads endUpdates];
	[self.table_Downloads reloadData];

	if ([download type] == OEXDownloadTypeAudio) {
		[edxInterface cancelDownloadForAudio:download completionHandler:^(BOOL success){
			dispatch_async(dispatch_get_main_queue(), ^{
				download.downloadState = OEXDownloadStateNew;
			});
		}];
	} else {
		[edxInterface cancelDownloadForVideo:download completionHandler:^(BOOL success){
			dispatch_async(dispatch_get_main_queue(), ^{
				download.downloadState = OEXDownloadStateNew;
			});
		}];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

@end
