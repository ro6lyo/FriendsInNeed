//
//  FINSignalDetailsVC.m
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsVC.h"
#import "FINDataManager.h"
#import "FINSignalDetailsCell.h"
#import "FINSignalDetailsCommentCell.h"
#import "FINGlobalConstants.pch"
#import "FINComment.h"
#import "FINError.h"
#import "FINLoginVC.h"
#import "Help_A_Paw-Swift.h"
#import <SDWebImage/UIImageView+WebCache.h>


#define kTitleIndex     0
#define kAuthorIndex    1
#define kDateIndex      2

#define kTitleLabel     @"Title"
#define kAuthorLabel    @"Author"
#define kDateLabel      @"Date"

#define kCellIdentifierGeneral          @"GeneralCell"
#define kCellIdentifierDetails          @"DetailsCell"
#define kCellIdentifierStatus           @"StatusCell"
#define kCellIdentifierComment          @"CommentCell"
#define kCellIdentifierCommentStatus    @"CommentStatusCell"
#define kCellIdentifierLoading          @"LoadingCell"



enum {
    kSectionIndexDetails,
    kSectionIndexStatusHeader,
    kSectionIndexStatus,
    kSectionIndexCommentsHeader,
    kSectionIndexComments,
    kSectionIndexCount
};

enum {
    kCellIndexStatusSelected = 0,
    kCellIndexStatus0 = 0,
    kCellIndexStatus1,
    kCellIndexStatus2,
};


#define kCellIdentifierTitle    @"TitleCell"
#define kCellIdentifierAuthor   @"AuthorCell"
#define kCellIdentifierDate     @"DateCell"

@interface FINSignalDetailsVC () <UITableViewDataSource, UITableViewDelegate,imageTappableDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *addCommentView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *addCommentBlurBackground1;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *addCommentBlurBackground2;
@property (weak, nonatomic) IBOutlet UITextField *addCommentTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addCommentLC;
@property (weak, nonatomic) IBOutlet UIButton *sendCommentButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sendCommentLoadingIndicator;

@property (strong, nonatomic) FINAnnotation *annotation;
@property (strong, nonatomic) NSMutableArray *comments;
@property (assign, nonatomic) BOOL statusIsExpanded;
@property (assign, nonatomic) NSUInteger status;
@property (assign, nonatomic) CGFloat keyboardHeight;
@property (assign, nonatomic) BOOL keyboardIsShown;
@property (assign, nonatomic) BOOL commentsAreLoaded;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation FINSignalDetailsVC

- (FINSignalDetailsVC *)initWithAnnotation:(FINAnnotation *)annotation
{
    self = [self init];
    
    _annotation = annotation;
    _status = _annotation.signal.status;
    _comments = [NSMutableArray new];
    _commentsAreLoaded = NO;
    
    _dateFormatter = [NSDateFormatter new];
    [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    return self;
}

- (void)getComments
{
    [[FINDataManager sharedManager] getCommentsForSignal:_annotation.signal completion:^(NSArray *comments, FINError *error) {
        
        _commentsAreLoaded = YES;
        if (!error)
        {
            _comments = [NSMutableArray new];
            [_comments addObjectsFromArray:comments];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionIndexComments] withRowAnimation:UITableViewRowAnimationFade];
            //            [self determineIfAddCommentShadowShouldBeVisible];
        }
        else
        {
            [self showAlertForError:error];
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getComments];
    
    _tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, _addCommentView.frame.size.height, 0.0f);
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierDetails];
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCommentCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierComment];
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsStatusChangeCommentCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierCommentStatus];
    
    self.navigationItem.title = NSLocalizedString(@"Signals Details",nil);
    
    _toolbar.layer.shadowColor = [UIColor colorWithRed:255.0f/255.0f green:150.0f/255.0f blue:66.0f/255.0f alpha:0.5f].CGColor;
    _toolbar.layer.shadowOpacity = 1.0f;
    _toolbar.layer.shadowOffset = (CGSize){0.0f, 2.0f};
       
    _addCommentView.layer.shadowOffset = CGSizeMake(0, -2);
    _addCommentView.layer.shadowColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_close_x_white"] style:UIBarButtonItemStylePlain target:self action:@selector(onCloseButton:)];
    
    self.navigationItem.leftBarButtonItem = backButton;
    
    _statusIsExpanded = NO;
    
    UITapGestureRecognizer* cGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerTap:)];
    cGR.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:cGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Fix a problem with UIVisualEffectView in iOS 10
    // http://stackoverflow.com/questions/39671408/uivisualeffectview-in-ios-10
    [UIView animateWithDuration:0.3 animations:^{
        _addCommentBlurBackground1.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _addCommentBlurBackground1.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

    }];
    
    // Temporarily commented because it interferes with the blur view
//    [self determineIfAddCommentShadowShouldBeVisible];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - Gesture Recognizers
- (void)onContainerTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // End editing only if tap was outside of add comment view
        CGPoint tap = [sender locationInView:self.view];
        if (CGRectContainsPoint(_addCommentView.frame, tap) == NO)
        {
            [self.view endEditing:YES];
        }
    }
}

#pragma mark - TableView data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionIndexCount;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    [self determineIfAddCommentShadowShouldBeVisible];
}

- (void)determineIfAddCommentShadowShouldBeVisible
{
    CGFloat keyboardCompensation;
    if (_keyboardIsShown)
    {
        keyboardCompensation = _keyboardHeight;
    }
    else
    {
        keyboardCompensation = 0.0f;
    }
    
    if ((_tableView.contentOffset.y + _tableView.frame.size.height - _addCommentView.frame.size.height - keyboardCompensation) >= _tableView.contentSize.height)
    {
        _addCommentView.layer.shadowOpacity = 0.0f;
    }
    else
    {
        _addCommentView.layer.shadowOpacity = 1.0f;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    if ( (section == kSectionIndexStatus) && (_statusIsExpanded) )
    {
        rows = 3;
    }
    else if (section == kSectionIndexComments)
    {
        if (_commentsAreLoaded)
        {
            rows = _comments.count;
        }
        else
        {
            rows = 1;
        }
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case kSectionIndexDetails:
        {
            FINSignalDetailsCell *detailsCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierDetails];
            
            detailsCell.backgroundColor = [UIColor clearColor];
            detailsCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [detailsCell setTitle:_annotation.signal.title];
            [detailsCell setAuthor:_annotation.signal.authorName];
            [detailsCell setPhoneNumber:_annotation.signal.authorPhone];
            [detailsCell setDate:[_dateFormatter stringFromDate:_annotation.signal.date]];
            if (_annotation.signal.photoUrl)
            {
                detailsCell.delegate = self;
                [self imageGetterFrom:_annotation.signal.photoUrl forCell:detailsCell];
            }
            
            
            cell = detailsCell;
            
            break;
        }
        case kSectionIndexStatusHeader:
        {
            UITableViewCell *statusLabelCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierGeneral];
            if (!statusLabelCell)
            {
                statusLabelCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierGeneral];
                statusLabelCell.backgroundColor = [UIColor clearColor];
                statusLabelCell.selectionStyle = UITableViewCellSelectionStyleNone;
                statusLabelCell.indentationLevel = 0;
                statusLabelCell.textLabel.textColor = [UIColor grayColor];
            }
            
            statusLabelCell.textLabel.text = NSLocalizedString(@"Status",nil);
            
            cell = statusLabelCell;
            break;
        }
        case kSectionIndexStatus:
        {
            UITableViewCell *statusCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierStatus];
            if (!statusCell)
            {
                statusCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierStatus];
                statusCell.backgroundColor = [UIColor clearColor];
                statusCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            UIImage *statusImage;
            NSString *statusString;
            
            if (_statusIsExpanded == NO)
            {
                statusCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_dropdown"]];
                
                statusImage = [FINStatusHelper getStatusImageForCode:_status];
                statusString = [FINStatusHelper getStatusNameForCode:_status];
            }
            else
            {
                statusImage = [FINStatusHelper getStatusImageForCode:indexPath.row];
                statusString = [FINStatusHelper getStatusNameForCode:indexPath.row];
                
                if (_status == indexPath.row)
                {
                    statusCell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else
                {
                    statusCell.accessoryType = UITableViewCellAccessoryNone;
                }
                statusCell.accessoryView = nil;
            }
            [statusCell.imageView setImage:statusImage];
            if (_status == 3) {
                UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [indicator startAnimating];
                [statusCell.imageView addSubview:indicator];
                indicator.frame = CGRectMake(0, 0, 35, 35);
               // [indicator setCenter:statusCell.imageView .center];
            }

            statusCell.textLabel.text = statusString;
            
            cell = statusCell;
            break;
        }
        case kSectionIndexCommentsHeader:
        {
            UITableViewCell *commentsLabelCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierGeneral];
            if (!commentsLabelCell)
            {
                commentsLabelCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierGeneral];
                commentsLabelCell.backgroundColor = [UIColor clearColor];
                commentsLabelCell.selectionStyle = UITableViewCellSelectionStyleNone;
                commentsLabelCell.indentationLevel = 0;
                commentsLabelCell.textLabel.textColor = [UIColor grayColor];
            }
            
            commentsLabelCell.textLabel.text = NSLocalizedString(@"Comments",nil);
            
            cell = commentsLabelCell;
            break;
        }
            
        default:
        {
            if (_commentsAreLoaded)
            {
                FINComment *comment = _comments[indexPath.row];
                
                UITableViewCell<FINSignalDetailsCommentCellProtocol> *commentCell;
                NSString *commentText;
                
                if ([comment.type isEqualToString:@"status_change"])
                {
                    commentCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierCommentStatus];
                    
                    NSInteger newStatusCode = [FINDataManager getNewStatusCodeFromStatusChangedComment:comment.text];
                    NSString *newStatusString = [FINStatusHelper getStatusNameForCode:newStatusCode];
                    commentText = [NSString stringWithFormat:NSLocalizedString(@"%@ changed the status to\n\'%@\'", nil), comment.author.name, newStatusString];
                    
                    [(FINSignalDetailsStatusChangeCommentCell *)commentCell setStatusImage:[FINStatusHelper getStatusImageForCode:newStatusCode]];
                } 
                else
                {
                    commentCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierComment];
                    
                    [(FINSignalDetailsCommentCell *)commentCell setAuthor:comment.author.name];
                    
                    commentText = comment.text;
                }
                
                
                commentCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                [commentCell setCommentText:commentText];
                [commentCell setDate:[_dateFormatter stringFromDate:comment.created]];
                
                cell = commentCell;
            }
            else
            {
                UITableViewCell *loadingCommentsCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierLoading];
                if (!loadingCommentsCell)
                {
                    loadingCommentsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierLoading];
                    loadingCommentsCell.backgroundColor = [UIColor clearColor];
                    loadingCommentsCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    // Create a loading indicator
                    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activityIndicator startAnimating];
                    // Place it in the center
                    CGRect indicatorFrame = activityIndicator.frame;
                    indicatorFrame.origin.x = (self.view.frame.size.width - indicatorFrame.size.width) / 2;
                    activityIndicator.frame = indicatorFrame;
                    // Add it to the cell
                    [loadingCommentsCell addSubview:activityIndicator];
                }
                
                cell = loadingCommentsCell;
            }
            break;
        }
            
            break;
    }
    
    return cell;
}
// Code dublication with finMapVc
-(void) imageGetterFrom:(NSURL *)url forCell:(FINSignalDetailsCell *)cell {
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:url
                      options:0
                     progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {}
                    completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                        if (image && finished) {
                            [cell setPhoto:image];
                        }
                    }];
    
}
/**
 ...
 */
- (void)prepareCellFor:(UITableView *)tableView AtIndexPath:(NSIndexPath *)indexPath;
{
    UITableViewCell *oldStatusCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_status inSection:indexPath.section]];
    oldStatusCell.accessoryType = UITableViewCellAccessoryNone;
    
    UITableViewCell *newStatusCell = [tableView cellForRowAtIndexPath:indexPath];
    newStatusCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    float height;
    switch (indexPath.section) {
        case kSectionIndexDetails:
            height = 150.0f;
            break;
        case kSectionIndexStatus:
            height = 55.0f;
            break;
        case kSectionIndexComments:
        {
            if (_commentsAreLoaded)
            {
                FINComment *comment = _comments[indexPath.row];
                NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:comment.text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
                CGRect rect = [attributedText boundingRectWithSize:(CGSize){self.view.frame.size.width - (15 * 2), 150} options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
                height = ceilf(rect.size.height) + 55;
            }
            else 
            {
                height = 44.0f;
            }
            break;
        }
            
        default:
            height = 44.0f;
            break;
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionIndexStatus)
    {
        if ([[FINDataManager sharedManager] userIsLogged] == NO)
        {
            [self showLoginScreen];
            return;
        }
        
        if (_statusIsExpanded)
        {
            if (_status != indexPath.row)
            {
                NSUInteger currentStatus = _status;
                [self prepareCellFor:tableView AtIndexPath:indexPath];
                _status = 3;
                
                [[FINDataManager sharedManager] setStatus:indexPath.row forSignal:_annotation.signal completion:^(FINError *error) {
                    if (error != nil) {
                        [self prepareCellFor:tableView AtIndexPath:indexPath];
                        _status = currentStatus;
                        _annotation.signal.status = currentStatus;
                        [self performSelector:@selector(reloadStatusSection) withObject:nil afterDelay:0.1];
                        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                                style:UIAlertActionStyleDefault
                                                                              handler:^(UIAlertAction * action) {}];
        
                        [self showAlertViewControllerWithTitle:NSLocalizedString(@"Ooops!",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Something went wrong! Possible problem:\n%@",nil), error.message] actions: [NSArray arrayWithObjects:defaultAction, nil]];
                        [self.delegate refreshAnnotation:_annotation];
                    }
                    else {
                        _status = indexPath.row;
                        [self performSelector:@selector(reloadStatusSection) withObject:nil afterDelay:0.1];
                        [self getComments];
                    }
                }];
            }
            
            _statusIsExpanded = !_statusIsExpanded;
            [self performSelector:@selector(reloadStatusSection) withObject:nil afterDelay:0.1];
        }
        else
        {
            _statusIsExpanded = !_statusIsExpanded;
            [self performSelector:@selector(reloadStatusSection) withObject:nil afterDelay:0.0];
        }
    }
}

- (void)reloadStatusSection
{
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionIndexStatus] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)onCloseButton:(id)sender
{
    [self.delegate refreshAnnotation:_annotation];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)onAddCommentButton:(id)sender
{
    if ([[FINDataManager sharedManager] userIsLogged] == NO)
    {
        [self.view endEditing:YES];
        [self showLoginScreen];
        return;
    }
    
    BOOL inputValidation = [InputValidator validateGeneralInputFor:@[_addCommentTextField] message:NSLocalizedString(@"Please enter a comment", nil) parent:self];
    if (!inputValidation)
    {
        return;
    }
    
    [_addCommentTextField resignFirstResponder];

    [self setSendingCommentMode];
    [[FINDataManager sharedManager] saveComment:_addCommentTextField.text forSigna:_annotation.signal completion:^(FINComment *comment, FINError *error) {
        
        [self resetSendingCommentMode];
        
        if (!error)
        {
            [_comments addObject:comment];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_comments indexOfObject:comment] inSection:kSectionIndexComments];
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            
            _addCommentTextField.text = @"";
        }
        else
        {
            [self showAlertForError:error];
        }
    }];
}

- (void)setSendingCommentMode
{
    _sendCommentButton.hidden = YES;
    [_sendCommentLoadingIndicator startAnimating];
}

- (void)resetSendingCommentMode
{
    _sendCommentButton.hidden = NO;
    [_sendCommentLoadingIndicator stopAnimating];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _addCommentTextField)
    {
        [self onAddCommentButton:_sendCommentButton];
    }
    
    return YES;
}

#pragma mark - Keyboard show/hide management
- (void)keyboardWillShow:(NSNotification *)note
{
    // If keyboard is already shown there's nothing to do
    if (_keyboardIsShown)
    {
        return;
    }
    
    // Get the keyboard height
    CGRect keyboardFrame;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardFrame];
    _keyboardHeight = keyboardFrame.size.height;
    
    // Extend the table view so it can be scrolled all the way
    UIEdgeInsets insets = _tableView.contentInset;
    insets.bottom += _keyboardHeight;
    _tableView.contentInset = insets;
    //Check if current device is iphone X, then compestate bottom constrant so the view is just on top
    NSInteger addOn = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        if (screenSize.height == 812.0f)
            addOn = 40;
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        
        // Move the comment view above the keyboard
        CGRect frame = _addCommentView.frame;
        frame.origin.y -= _keyboardHeight;
        _addCommentView.frame = frame;
        
        // Modify its bottom constraint, too
        _addCommentLC.constant = _keyboardHeight-addOn;
        [_addCommentView setNeedsLayout];
    }];
    
    _keyboardIsShown = YES;
//    [self determineIfAddCommentShadowShouldBeVisible];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    // Get the keyboard height
    CGRect keyboardFrame;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardFrame];
    _keyboardHeight = keyboardFrame.size.height;
    
    // Restore original table view insets
    UIEdgeInsets insets = _tableView.contentInset;
    insets.bottom -= _keyboardHeight;
    _tableView.contentInset = insets;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        // Return comment and table views to their original state
        CGRect frame = _addCommentView.frame;
        frame.origin.y += _keyboardHeight;
        _addCommentView.frame = frame;
        
        _addCommentLC.constant = 0.0f;
        [_addCommentView setNeedsLayout];
    }];
    
    _keyboardIsShown = NO;
//    [self determineIfAddCommentShadowShouldBeVisible];
}


- (void)showAlertForError:(FINError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Ooops!",nil)
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"Something went wrong! Possible problem:\n%@",nil), error.message]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
}

- (void)showLoginScreen
{
    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:loginVC animated:YES completion:^{}];
}

- (void)imageTapped:(UIImage *)image {
    FINSignalPhotoVC *signalPhotoVC = [[FINSignalPhotoVC alloc] init];
    [signalPhotoVC injectWithImg:image];
    signalPhotoVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self.navigationController presentViewController:signalPhotoVC animated:YES completion:nil];
}

@end
