//
//  EventsTableView.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EventsTableView.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "AppDelegate.h"
#import "FontAwesome.h"
#import "URLHandler.h"
#import "ImageViewController.h"
#import "PastebinViewController.h"
#import "YouTubeViewController.h"
#import "EditConnectionViewController.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "IRCCloudSafariViewController.h"
#import "AvatarsDataSource.h"
#import "ImageCache.h"

#if TARGET_IPHONE_SIMULATOR
//Private API for testing force touch from https://gist.github.com/jamesfinley/7e2009dd87b223c69190
@interface UIPreviewForceInteractionProgress : NSObject

- (void)endInteraction:(BOOL)arg1;

@end

@interface UIPreviewInteractionController : NSObject

@property (nonatomic, readonly) UIPreviewForceInteractionProgress *interactionProgressForPresentation;

- (BOOL)startInteractivePreviewAtLocation:(CGPoint)point inView:(UIView *)view;
- (void)cancelInteractivePreview;
- (void)commitInteractivePreview;

@end

@interface _UIViewControllerPreviewSourceViewRecord : NSObject <UIViewControllerPreviewing>

@property (nonatomic, readonly) UIPreviewInteractionController *previewInteractionController;

@end

void WFSimulate3DTouchPreview(id<UIViewControllerPreviewing> previewer, CGPoint sourceLocation) {
    /*_UIViewControllerPreviewSourceViewRecord *record = (_UIViewControllerPreviewSourceViewRecord *)previewer;
     UIPreviewInteractionController *interactionController = record.previewInteractionController;
     [interactionController startInteractivePreviewAtLocation:sourceLocation inView:record.sourceView];
     
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     [interactionController.interactionProgressForPresentation endInteraction:YES];
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     [interactionController commitInteractivePreview];
     //[interactionController cancelInteractivePreview];
     });
     });*/
}
#endif

int __timestampWidth;
BOOL __24hrPref = NO;
BOOL __secondsPref = NO;
BOOL __timeLeftPref = NO;
BOOL __nickColorsPref = NO;
BOOL __hideJoinPartPref = NO;
BOOL __expandJoinPartPref = NO;
BOOL __avatarsOffPref = NO;
BOOL __chatOneLinePref = NO;
BOOL __norealnamePref = NO;
BOOL __monospacePref = NO;
BOOL __disableInlineFilesPref = NO;
BOOL __disableBigEmojiPref = NO;
BOOL __disableCodeSpanPref = NO;
BOOL __disableCodeBlockPref = NO;
BOOL __disableQuotePref = NO;
int __smallAvatarHeight;
int __largeAvatarHeight = 32;

extern BOOL __compact;
extern UIImage *__socketClosedBackgroundImage;

@interface EventsTableCell : UITableViewCell {
    UIImageView *_avatar;
    UILabel *_timestamp;
    LinkLabel *_message;
    LinkLabel *_nickname;
    int _type;
    UIView *_socketClosedBar;
    UILabel *_accessory;
    UIView *_topBorder;
    UIView *_bottomBorder;
    UIView *_quoteBorder;
    UIView *_codeBlockBackground;
    float _timestampPosition;
    float _accessoryOffset;
    UIColor *_messageTextColor;
    UIActivityIndicatorView *_spinner;
    UIView *_thumbbackground;
    UIImageView *_thumbnail;
    UILabel *_filename, *_mimeTypr, *_extension;
    float _thumbnailWidth, _thumbnailHeight, _messageWidth;
    BOOL _emojiOnly;
}
@property int type;
@property float timestampPosition, accessoryOffset, thumbnailWidth, thumbnailHeight, messageWidth;
@property (readonly) UILabel *timestamp, *accessory, *filename, *mimeType, *extension;
@property (readonly) LinkLabel *message, *nickname;
@property (readonly) UIImageView *avatar, *thumbnail;
@property (readonly) UIActivityIndicatorView *spinner;
@property (readonly) UIView *quoteBorder, *codeBlockBackground;
@property UIColor *messageTextColor;
@property BOOL emojiOnly;
@end

@implementation EventsTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _type = 0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        _codeBlockBackground = [[UIView alloc] initWithFrame:CGRectZero];
        _codeBlockBackground.hidden = YES;
        [self.contentView addSubview:_codeBlockBackground];

        _socketClosedBar = [[UIView alloc] initWithFrame:CGRectZero];
        _socketClosedBar.hidden = YES;
        [self.contentView addSubview:_socketClosedBar];
        
        _thumbbackground = [[UIView alloc] initWithFrame:CGRectZero];
        _thumbbackground.hidden = YES;
        [self.contentView addSubview:_thumbbackground];
        
        _filename = [[UILabel alloc] init];
        _filename.textColor = [UIColor linkColor];
        _filename.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        _filename.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_filename];
        
        _mimeType = [[UILabel alloc] init];
        _mimeType.textColor = [UIColor messageTextColor];
        _mimeType.font = [UIFont systemFontOfSize:FONT_SIZE];
        _mimeType.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_mimeType];
        
        _extension = [[UILabel alloc] init];
        _extension.textColor = [UIColor whiteColor];
        _extension.backgroundColor = [UIColor blueColor];
        _extension.font = [UIFont boldSystemFontOfSize:FONT_SIZE * 1.5];
        _extension.textAlignment = NSTextAlignmentCenter;
        _extension.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:_extension];
        
        _timestamp = [[UILabel alloc] init];
        _timestamp.backgroundColor = [UIColor clearColor];
        _timestamp.textColor = [UIColor timestampColor];
        _timestamp.textAlignment = NSTextAlignmentCenter;
        _timestamp.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:_timestamp];
        
        _nickname = [[LinkLabel alloc] init];
        _nickname.backgroundColor = [UIColor clearColor];
        _nickname.textColor = [UIColor timestampColor];
        _nickname.font = [ColorFormatter timestampFont];
        _nickname.numberOfLines = 1;
        _nickname.lineBreakMode = NSLineBreakByTruncatingTail;
        _nickname.userInteractionEnabled = YES;
        _nickname.baselineAdjustment = UIBaselineAdjustmentNone;
        [self.contentView addSubview:_nickname];
        
        _message = [[LinkLabel alloc] init];
        _message.backgroundColor = [UIColor clearColor];
        _message.textColor = [UIColor messageTextColor];
        _message.numberOfLines = 0;
        _message.lineBreakMode = NSLineBreakByWordWrapping;
        _message.userInteractionEnabled = YES;
        _message.baselineAdjustment = UIBaselineAdjustmentNone;
        [self.contentView addSubview:_message];
        
        _accessory = [[UILabel alloc] initWithFrame:CGRectZero];
        _accessory.hidden = YES;
        _accessory.textAlignment = NSTextAlignmentCenter;
        _accessory.baselineAdjustment = UIBaselineAdjustmentNone;
        _accessory.textColor = [UIColor expandCollapseIndicatorColor];
        [self.contentView addSubview:_accessory];
        
        _avatar = [[UIImageView alloc] init];
        [self.contentView addSubview:_avatar];
        
        _thumbnail = [[UIImageView alloc] init];
        [self.contentView addSubview:_thumbnail];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [_spinner sizeToFit];
        [self.contentView addSubview:_spinner];
        
        _topBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _topBorder.hidden = YES;
        [self.contentView addSubview:_topBorder];
        
        _bottomBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomBorder.hidden = YES;
        [self.contentView addSubview:_bottomBorder];
        
        _quoteBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _quoteBorder.hidden = YES;
        [self.contentView addSubview:_quoteBorder];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.contentView.bounds;
    _topBorder.frame = CGRectMake(0,0,frame.size.width, 1);
    _bottomBorder.frame = CGRectMake(0,frame.size.height - 3,frame.size.width, 3);
    _thumbbackground.hidden = YES;
    _extension.hidden = YES;
    _filename.hidden = YES;
    _mimeType.hidden = YES;
    _message.numberOfLines = 0;
    
    if(_type == ROW_TIMESTAMP) {
        _topBorder.backgroundColor = [UIColor timestampTopBorderColor];
        _topBorder.hidden = NO;
        
        _bottomBorder.backgroundColor = [UIColor timestampBottomBorderColor];
        _bottomBorder.hidden = NO;
    } else {
        _topBorder.hidden = _bottomBorder.hidden = YES;
    }
    
    if(_type == ROW_MESSAGE || _type == ROW_ME_MESSAGE || _type == ROW_SOCKETCLOSED || _type == ROW_FAILED || _type == ROW_THUMBNAIL || _type == ROW_FILE) {
        frame.origin.x = (__timeLeftPref || (!__avatarsOffPref && !__chatOneLinePref))?6:16;
        frame.origin.y = __compact ? 0 : (FONT_SIZE > 13 ? 2 : 1);
        frame.size.height -= __compact ? 4 : 0;
        frame.size.width -= frame.origin.x + 6;
        if(!__chatOneLinePref && !__avatarsOffPref) {
            _avatar.frame = CGRectMake(
                                       frame.origin.x + 4,
                                       frame.origin.y + (FONT_SIZE > 13 ? (__compact ? 3 : 2) : (__compact ? 2 : 1)),
                                       __largeAvatarHeight,
                                       __largeAvatarHeight
                                       );
            frame.origin.x += _avatar.frame.size.width + 13;
            frame.size.width -= _avatar.frame.size.width + 17;
        }
        if(_type == ROW_MESSAGE && !__chatOneLinePref && _nickname.attributedText.length) {
            frame.origin.y += 2;
            frame.size.height -= 2;
            [_nickname sizeToFit];
            _nickname.frame = CGRectMake(frame.origin.x + (__timeLeftPref?__timestampWidth:0), frame.origin.y, _nickname.frame.size.width, _nickname.frame.size.height);
            frame.origin.y += _nickname.frame.size.height;
            frame.size.height -= _nickname.frame.size.height;
            if(__timeLeftPref) {
                frame.origin.x += 4;
                frame.size.width -= 4;
            }
            _nickname.hidden = NO;
        } else {
            _nickname.hidden = YES;
        }
        [_accessory sizeToFit];
        if(_type == ROW_SOCKETCLOSED) {
            frame.size.height -= (FONT_SIZE-2);
            _socketClosedBar.frame = CGRectMake(0,self.contentView.bounds.size.height - (FONT_SIZE-2), self.contentView.bounds.size.width, (FONT_SIZE-2));
            _socketClosedBar.hidden = NO;
            _socketClosedBar.backgroundColor = [UIColor socketClosedBackgroundColor];
            _accessory.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y + 2 + _accessoryOffset, _accessory.frame.size.width, _accessory.frame.size.height);
        } else if(_type == ROW_FAILED) {
            frame.size.width -= 20;
            _accessory.frame = CGRectMake(frame.origin.x + frame.size.width + 6, frame.origin.y + 1, _accessory.frame.size.width, _accessory.frame.size.height);
        } else {
            _socketClosedBar.hidden = YES;
            _accessory.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y + 2 + _accessoryOffset, _accessory.frame.size.width, _accessory.frame.size.height);
        }
        [_timestamp sizeToFit];
        _timestamp.frame = CGRectMake(frame.origin.x + (__timeLeftPref?0:(frame.size.width - __timestampWidth)), frame.origin.y + _timestampPosition, __timestampWidth, _timestamp.frame.size.height);
        _timestamp.hidden = _message.hidden = (_type == ROW_SOCKETCLOSED && _message.text.length == 0);
        _timestamp.textAlignment = __timeLeftPref?NSTextAlignmentCenter:NSTextAlignmentRight;
        
        if(_type == ROW_THUMBNAIL) {
            _thumbbackground.backgroundColor = [UIColor bufferBackgroundColor];
            if(__timeLeftPref) {
                float width = frame.size.width - 16 - __timestampWidth;
                if(width < _thumbnailWidth + 16)
                    width = _thumbnailWidth + 16;
                _thumbbackground.frame = CGRectMake(frame.origin.x + __timestampWidth + 6, frame.origin.y + 2, width, frame.size.height - (__compact?2:8));
                _thumbnail.frame = CGRectMake(frame.origin.x + 14 + __timestampWidth, frame.origin.y + 8, _thumbnailWidth, _thumbnailHeight);
            } else {
                float width = frame.size.width - 16 - __timestampWidth;
                if(width < _thumbnailWidth + 16)
                    width = _thumbnailWidth + 16;
                _thumbbackground.frame = CGRectMake(frame.origin.x, frame.origin.y + 1, width, frame.size.height - (__compact?2:8));
                if(_thumbnail.image)
                    _thumbnail.frame = CGRectMake(frame.origin.x + 8, frame.origin.y + 8, _thumbnailWidth, _thumbnailHeight);
            }
            _thumbbackground.hidden = NO;
            _timestamp.hidden = YES;
            frame.origin.x += 8;
            frame.origin.y += _thumbnailHeight + 10;
            frame.size.height -= _thumbnailHeight - 8;
            _spinner.center = self.contentView.center;
            _spinner.hidden = (_thumbnail.image != nil);
            if(!_spinner.hidden && !_spinner.isAnimating)
                [_spinner startAnimating];
            if(_filename.text.length) {
                _filename.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y, frame.size.width - 30 - __timestampWidth, FONT_SIZE + 2);
                _filename.hidden = NO;
                frame.origin.y += FONT_SIZE + 2;
                frame.size.height -= FONT_SIZE + 2;
            }
            _mimeType.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y, frame.size.width - 30 - __timestampWidth, FONT_SIZE + 2);
            _mimeType.hidden = NO;
            _message.hidden = YES;
        } else if(_type == ROW_FILE) {
            _thumbbackground.backgroundColor = [UIColor bufferBackgroundColor];
            if(__timeLeftPref) {
                _thumbbackground.frame = CGRectMake(frame.origin.x + __timestampWidth + 6, frame.origin.y + 2, frame.size.width - 10 - __timestampWidth, frame.size.height - (__compact?2:8));
            } else {
                _thumbbackground.frame = CGRectMake(frame.origin.x, frame.origin.y + 1, frame.size.width - 10 - __timestampWidth, frame.size.height - (__compact?2:8));
            }
            _thumbbackground.hidden = NO;
            
            _extension.frame = CGRectMake(_thumbbackground.frame.origin.x + 8, frame.origin.y + 8, _thumbbackground.frame.size.height - 16, _thumbbackground.frame.size.height - 16);
            _extension.hidden = NO;
            
            frame.origin.x += _extension.frame.size.width + 16;
            frame.size.width -= _extension.frame.size.width + 32;
            
            _timestamp.hidden = YES;
            
            _filename.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y + 6, frame.size.width - 4 - __timestampWidth, FONT_SIZE + 2);
            _filename.hidden = NO;
            frame.origin.y += FONT_SIZE + 8;
            frame.size.height -= FONT_SIZE + 8;
            _mimeType.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y, frame.size.width - 4 - __timestampWidth, FONT_SIZE + 2);
            _mimeType.hidden = NO;
            frame.origin.y += FONT_SIZE + 2;
            frame.size.height -= FONT_SIZE + 2;
            
            _message.font = _mimeType.font = [UIFont systemFontOfSize:FONT_SIZE - 2];
            _message.numberOfLines = 1;
        }
        
        if(!_quoteBorder.hidden) {
            _quoteBorder.frame = CGRectMake(frame.origin.x+ (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y + 2, 3, frame.size.height - 4);
            frame.origin.x += 12;
            frame.size.width -= 12;
        }

        if(!_codeBlockBackground.hidden) {
            frame.origin.x += 4;
            frame.size.width -= 8;
            frame.origin.y += 4;
            frame.size.height -= 8;
        }
        
        if(_messageWidth == 0) {
            _messageWidth = frame.size.width - 4 - __timestampWidth;
        }
        
        _message.frame = CGRectMake(frame.origin.x + (__timeLeftPref?(__timestampWidth + 4):0), frame.origin.y - 0.5, _messageWidth, floorf([_message sizeThatFits:CGSizeMake(_messageWidth, CGFLOAT_MAX)].height) + 1);
        _codeBlockBackground.frame = CGRectMake(_message.frame.origin.x - 4, _message.frame.origin.y - 2, _message.frame.size.width + 8, frame.size.height + 2);
        if(!__avatarsOffPref && (__chatOneLinePref || _type == ROW_ME_MESSAGE) && !_avatar.hidden) {
            _avatar.frame = CGRectMake(
                                       frame.origin.x + (__timeLeftPref ? (__timestampWidth + 4) : 0),
                                       frame.origin.y + (_emojiOnly ? __smallAvatarHeight : 0) + ( __monospacePref ? (__compact ? 0 : 0.5) : roundf((__smallAvatarHeight+3)/10) ),
                                       __smallAvatarHeight,
                                       __smallAvatarHeight
                                       );
        }
    } else {
        if(_type == ROW_BACKLOG) {
            frame.origin.y = frame.size.height / 2;
            frame.size.height = 1;
        } else if(_type == ROW_LASTSEENEID) {
            _socketClosedBar.backgroundColor = [UIColor timestampColor];
            _socketClosedBar.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height / 2, frame.size.width, 1);
            if(!__avatarsOffPref && !__chatOneLinePref) {
                frame.origin.x += __largeAvatarHeight + 16;
                frame.size.width -= __largeAvatarHeight + 16;
                self.contentView.frame = frame;
            }
            int width = [_timestamp.text sizeWithAttributes:@{NSFontAttributeName:_timestamp.font}].width + 12;
            frame.origin.x = (frame.size.width - width) / 2;
            frame.size.width = width;
        }
        _timestamp.textAlignment = NSTextAlignmentCenter;
        _timestamp.frame = frame;
        _timestamp.hidden = NO;
        if(_type != ROW_THUMBNAIL)
            _message.hidden = YES;
        _socketClosedBar.hidden = (_type != ROW_LASTSEENEID);
        _spinner.hidden = _thumbnail.hidden = YES;
        [_spinner stopAnimating];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation EventsTableView

- (id)init {
    self = [super init];
    if (self) {
        _conn = [NetworkConnection sharedInstance];
        _lock = [[NSRecursiveLock alloc] init];
        _ready = NO;
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _data = [[NSMutableArray alloc] init];
        _expandedSectionEids = [[NSMutableDictionary alloc] init];
        _collapsedEvents = [[CollapsedEvents alloc] init];
        _unseenHighlightPositions = [[NSMutableArray alloc] init];
        _filePropsCache = [[NSMutableDictionary alloc] init];
        _closedPreviews = [[NSMutableSet alloc] init];
        _buffer = nil;
        _eidToOpen = -1;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _conn = [NetworkConnection sharedInstance];
        _lock = [[NSRecursiveLock alloc] init];
        _ready = NO;
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _data = [[NSMutableArray alloc] init];
        _expandedSectionEids = [[NSMutableDictionary alloc] init];
        _collapsedEvents = [[CollapsedEvents alloc] init];
        _unseenHighlightPositions = [[NSMutableArray alloc] init];
        _filePropsCache = [[NSMutableDictionary alloc] init];
        _closedPreviews = [[NSMutableSet alloc] init];
        _buffer = nil;
        _eidToOpen = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _rowCache = [[NSMutableDictionary alloc] init];
    
    if(!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,_tableView.frame.size.width,20)];
        _headerView.autoresizesSubviews = YES;
        UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        a.center = _headerView.center;
        [a startAnimating];
        [_headerView addSubview:a];
    }
    
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [self.view addSubview:_tableView];
    }
    
    _tableView.scrollsToTop = NO;
    _tableView.estimatedRowHeight = 0;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;
    lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [_tableView addGestureRecognizer:lp];
    _topUnreadView.backgroundColor = [UIColor unreadBlueColor];
    _bottomUnreadView.backgroundColor = [UIColor unreadBlueColor];
    [_backlogFailedButton setBackgroundImage:[[UIImage imageNamed:@"sendbg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateNormal];
    [_backlogFailedButton setBackgroundImage:[[UIImage imageNamed:@"sendbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateHighlighted];
    [_backlogFailedButton setTitleColor:[UIColor unreadBlueColor] forState:UIControlStateNormal];
    [_backlogFailedButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_backlogFailedButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _backlogFailedButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [_backlogFailedButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]];
    
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor contentBackgroundColor];
    
    if([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        __previewer = [self registerForPreviewingWithDelegate:self sourceView:_tableView];
        [__previewer.previewingGestureRecognizerForFailureRelationship addTarget:self action:@selector(_3DTouchChanged:)];
    }
    
#if TARGET_IPHONE_SIMULATOR
    //UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_test3DTouch:)];
    //t.delegate = self;
    //[_tableView addGestureRecognizer:t];
#endif
}

#if TARGET_IPHONE_SIMULATOR
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return YES;
    else
        return ([self previewingContext:__previewer viewControllerForLocation:[touch locationInView:_tableView]] != nil);
}

- (void)_test3DTouch:(UITapGestureRecognizer *)r {
    WFSimulate3DTouchPreview(__previewer, [r locationInView:_tableView]);
}
#endif

-(void)_3DTouchChanged:(UIGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        MainViewController *mainViewController = [(AppDelegate *)([UIApplication sharedApplication].delegate) mainViewController];
        mainViewController.isShowingPreview = NO;
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if(!_data.count)
        return nil;
    MainViewController *mainViewController = [(AppDelegate *)([UIApplication sharedApplication].delegate) mainViewController];
    EventsTableCell *cell = [_tableView cellForRowAtIndexPath:[_tableView indexPathForRowAtPoint:location]];
    _previewingRow = [_tableView indexPathForRowAtPoint:location].row;
    Event *e = [_data objectAtIndex:_previewingRow];
    
    NSURL *url;
    if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE) {
        NSString *extension = [e.entities objectForKey:@"extension"];
        if(!extension.length)
            extension = [@"." stringByAppendingString:[[e.entities objectForKey:@"mime_type"] substringFromIndex:[[e.entities objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1]];
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [_file_url_template relativeStringWithVariables:@{@"id":[e.entities objectForKey:@"id"]} error:nil], [[e.entities objectForKey:@"mime_type"] substringToIndex:5], extension]];
    } else {
        NSTextCheckingResult *r = [cell.message linkAtPoint:[_tableView convertPoint:location toView:cell.message]];
        url = r.URL;
    }
    mainViewController.isShowingPreview = YES;
    
    if([URLHandler isImageURL:url]) {
        previewingContext.sourceRect = cell.frame;
        ImageViewController *i = [[ImageViewController alloc] initWithURL:url];
        i.preferredContentSize = self.view.window.bounds.size;
        i.previewing = YES;
        lp.enabled = NO;
        lp.enabled = YES;
        return i;
    } else if([URLHandler isYouTubeURL:url]) {
        previewingContext.sourceRect = cell.frame;
        YouTubeViewController *y = [[YouTubeViewController alloc] initWithURL:url];
        [y loadViewIfNeeded];
        y.preferredContentSize = y.player.bounds.size;
        y.toolbar.hidden = YES;
        lp.enabled = NO;
        lp.enabled = YES;
        return y;
    } else if([url.scheme hasPrefix:@"irccloud-paste-"]) {
        previewingContext.sourceRect = cell.frame;
        PastebinViewController *pvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"PastebinViewController"];
        [pvc setUrl:[NSURL URLWithString:[url.absoluteString substringFromIndex:15]]];
        lp.enabled = NO;
        lp.enabled = YES;
        return pvc;
    } else if([url.pathExtension.lowercaseString isEqualToString:@"mov"] || [url.pathExtension.lowercaseString isEqualToString:@"mp4"] || [url.pathExtension.lowercaseString isEqualToString:@"m4v"] || [url.pathExtension.lowercaseString isEqualToString:@"3gp"] || [url.pathExtension.lowercaseString isEqualToString:@"quicktime"]) {
        previewingContext.sourceRect = cell.frame;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        AVPlayerViewController *player = [[AVPlayerViewController alloc] init];
        player.player = [[AVPlayer alloc] initWithURL:url];
        player.modalPresentationStyle = UIModalPresentationCurrentContext;
        player.preferredContentSize = self.view.window.bounds.size;
        return player;
    } else if([SFSafariViewController class] && [url.scheme hasPrefix:@"http"]) {
        previewingContext.sourceRect = cell.frame;
        IRCCloudSafariViewController *s = [[IRCCloudSafariViewController alloc] initWithURL:url];
        s.modalPresentationStyle = UIModalPresentationCurrentContext;
        s.preferredContentSize = self.view.window.bounds.size;
        return s;
    }
    
    _previewingRow = -1;
    mainViewController.isShowingPreview = NO;
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    MainViewController *mainViewController = [(AppDelegate *)([UIApplication sharedApplication].delegate) mainViewController];
    mainViewController.isShowingPreview = NO;
    if([viewControllerToCommit isKindOfClass:[ImageViewController class]]) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        appDelegate.window.backgroundColor = [UIColor blackColor];
        appDelegate.window.rootViewController = viewControllerToCommit;
        [appDelegate.window insertSubview:appDelegate.slideViewController.view belowSubview:appDelegate.window.rootViewController.view];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [viewControllerToCommit didMoveToParentViewController:nil];
    } else if([viewControllerToCommit isKindOfClass:[YouTubeViewController class]]) {
        viewControllerToCommit.modalPresentationStyle = UIModalPresentationCustom;
        ((YouTubeViewController *)viewControllerToCommit).toolbar.hidden = NO;
        [self.slidingViewController presentViewController:viewControllerToCommit animated:NO completion:nil];
    } else if([viewControllerToCommit isKindOfClass:[UINavigationController class]]) {
        ((UINavigationController *)viewControllerToCommit).navigationBarHidden = NO;
        [((UINavigationController *)viewControllerToCommit).topViewController didMoveToParentViewController:nil];
        [self.slidingViewController presentViewController:viewControllerToCommit animated:YES completion:nil];
    } else if([viewControllerToCommit isKindOfClass:[PastebinViewController class]]) {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:viewControllerToCommit];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        [self.slidingViewController presentViewController:nc animated:YES completion:nil];
    } else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
        [self.slidingViewController presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    UIPreviewAction *deleteAction = [UIPreviewAction actionWithTitle:@"Delete" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSString *title = [_buffer.type isEqualToString:@"console"]?@"Delete Connection":@"Clear History";
        NSString *msg;
        if([_buffer.type isEqualToString:@"console"]) {
            msg = @"Are you sure you want to remove this connection?";
        } else if([_buffer.type isEqualToString:@"channel"]) {
            msg = [NSString stringWithFormat:@"Are you sure you want to clear your history in %@?", _buffer.name];
        } else {
            msg = [NSString stringWithFormat:@"Are you sure you want to clear your history with %@?", _buffer.name];
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            if([_buffer.type isEqualToString:@"console"]) {
                [_conn deleteServer:_buffer.cid handler:nil];
            } else {
                [_conn deleteBuffer:_buffer.bid cid:_buffer.cid handler:nil];
            }
        }]];
        
        if(((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController.presentedViewController)
            [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController dismissViewControllerAnimated:NO completion:nil];
        
        [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController presentViewController:alert animated:YES completion:nil];
    }];
    
    UIPreviewAction *archiveAction = [UIPreviewAction actionWithTitle:@"Archive" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [_conn archiveBuffer:_buffer.bid cid:_buffer.cid handler:nil];
    }];
    
    UIPreviewAction *unarchiveAction = [UIPreviewAction actionWithTitle:@"Unarchive" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [_conn unarchiveBuffer:_buffer.bid cid:_buffer.cid handler:nil];
    }];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if([_buffer.type isEqualToString:@"console"]) {
        if([_server.status isEqualToString:@"disconnected"]) {
            [items addObject:[UIPreviewAction actionWithTitle:@"Reconnect" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [_conn reconnect:_buffer.cid handler:nil];
            }]];
            [items addObject:deleteAction];
        } else {
            [items addObject:[UIPreviewAction actionWithTitle:@"Disconnect" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [_conn disconnect:_buffer.cid msg:nil handler:nil];
            }]];
            
        }
        [items addObject:[UIPreviewAction actionWithTitle:@"Edit Connection" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [ecv setServer:_buffer.cid];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            
            if(((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController.presentedViewController)
                [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController dismissViewControllerAnimated:NO completion:nil];
            
            [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController presentViewController:nc animated:YES completion:nil];
        }]];
    } else if([_buffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
            [items addObject:[UIPreviewAction actionWithTitle:@"Leave" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [_conn part:_buffer.name msg:nil cid:_buffer.cid handler:nil];
            }]];
            [items addObject:[UIPreviewAction actionWithTitle:@"Invite to Channel" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController _setSelectedBuffer:_buffer];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", _server.name, _server.hostname, _server.port] message:@"Invite to channel" delegate:((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController cancelButtonTitle:@"Cancel" otherButtonTitles:@"Invite", nil];
                alertView.tag = 4;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alertView textFieldAtIndex:0].delegate = ((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController;
                [alertView textFieldAtIndex:0].placeholder = @"nickname";
                [alertView textFieldAtIndex:0].tintColor = [UIColor blackColor];
                [alertView show];
            }]];
        } else {
            [items addObject:[UIPreviewAction actionWithTitle:@"Rejoin" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [_conn join:_buffer.name key:nil cid:_buffer.cid handler:nil];
            }]];
            if(_buffer.archived) {
                [items addObject:unarchiveAction];
            } else {
                [items addObject:archiveAction];
            }
            [items addObject:deleteAction];
        }
    } else {
        if(_buffer.archived) {
            [items addObject:unarchiveAction];
        } else {
            [items addObject:archiveAction];
        }
        [items addObject:deleteAction];
    }
    
    return items;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[EventsDataSource sharedInstance] clearHeightCache];
    [_tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogCompleted:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogFailed:)
                                                 name:kIRCCloudBacklogFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerClosed:)
                                                 name:ECSlidingViewTopDidReset object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_data.count && _buffer.scrolledUp) {
        _bottomRow = [[[_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset)] lastObject] row];
        if(_bottomRow >= _data.count)
            _bottomRow = _data.count - 1;
    } else {
        _bottomRow = -1;
    }
}

-(void)drawerClosed:(NSNotification *)n {
    if(self.slidingViewController.underLeftViewController)
        [self scrollViewDidScroll:_tableView];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    _ready = NO;
    _tableView.hidden = YES;
    _stickyAvatar.hidden = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if(_data.count && _buffer.scrolledUp)
            _bottomRow = [[[_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset)] lastObject] row];
        else
            _bottomRow = -1;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _ready = YES;
        [self clearCachedHeights];
        [self updateUnread];
        [self scrollViewDidScroll:_tableView];
        _tableView.hidden = NO;
    }];
}

-(void)uncacheFile:(NSString *)fileID {
    @synchronized (_filePropsCache) {
        if(fileID)
            [_filePropsCache removeObjectForKey:fileID];
    }
}

-(void)closePreview:(Event *)event {
    [_closedPreviews addObject:@(event.eid)];
    [self refresh];
}

-(void)clearCachedHeights {
    if(_ready) {
        if([_data count]) {
            [_lock lock];
            for(Event *e in _data) {
                e.height = 0;
            }
            [_lock unlock];
            _ready = NO;
            [_tableView reloadData];
            if(_bottomRow >= 0 && _bottomRow < [_tableView numberOfRowsInSection:0]) {
                [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_bottomRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                _bottomRow = -1;
            } else {
                [self _scrollToBottom];
            }
            _ready = YES;
        }
    }
}

- (IBAction)loadMoreBacklogButtonPressed:(id)sender {
    if(_conn.ready) {
        _requestingBacklog = YES;
        [_conn cancelPendingBacklogRequests];
        [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid completion:nil];
        _tableView.tableHeaderView = _headerView;
    }
}

- (void)backlogFailed:(NSNotification *)notification {
    if(_buffer && [notification.object bid] == _buffer.bid) {
        _requestingBacklog = NO;
        _tableView.tableHeaderView = _backlogFailedView;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Unable to download chat history. Please try again shortly.");
    }
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(_buffer && [notification.object bid] == _buffer.bid) {
        if([[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid] == nil) {
            NSLog(@"This buffer contains no events, switching to backlog failed header view");
            _tableView.tableHeaderView = _backlogFailedView;
            return;
        }
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Download complete.");
    }
    if(notification.object == nil || [notification.object bid] == -1 || (_buffer && [notification.object bid] == _buffer.bid && _requestingBacklog)) {
        NSLog(@"Backlog loaded in current buffer, will find and remove the last seen EID marker");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(_buffer.scrolledUp) {
                NSLog(@"Table was scrolled up, adjusting scroll offset");
                [_lock lock];
                int row = 0;
                NSInteger toprow = [_tableView indexPathForRowAtPoint:CGPointMake(0,_buffer.savedScrollOffset)].row;
                if(_tableView.tableHeaderView != nil)
                    row++;
                for(Event *event in _data) {
                    if((event.rowType == ROW_LASTSEENEID && [[EventsDataSource sharedInstance] unreadStateForBuffer:_buffer.bid lastSeenEid:_buffer.last_seen_eid type:_buffer.type] == 0) || event.rowType == ROW_BACKLOG) {
                        if(toprow > row) {
                            NSLog(@"Adjusting scroll offset");
                            _buffer.savedScrollOffset -= 26;
                        }
                    }
                    if(++row > toprow)
                        break;
                }
                [_lock unlock];
                for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid]) {
                    if(event.rowType == ROW_LASTSEENEID) {
                        NSLog(@"removing the last seen EID marker");
                        [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                        NSLog(@"removed!");
                        break;
                    }
                }
            }
            NSLog(@"Rebuilding the message table");
            [self refresh];
        }];
    }
}

- (void)_sendHeartbeat {
    if(_data.count && _topUnreadView.alpha == 0 && _bottomUnreadView.alpha == 0 && [UIApplication sharedApplication].applicationState == UIApplicationStateActive && ![NetworkConnection sharedInstance].notifier && [self.slidingViewController topViewHasFocus] && !_requestingBacklog && _conn.state == kIRCCloudStateConnected) {
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
        NSTimeInterval eid = _buffer.scrolledUpFrom;
        if(eid <= 0) {
            Event *last;
            for(NSInteger i = events.count - 1; i >= 0; i--) {
                last = [events objectAtIndex:i];
                if(!last.pending && last.rowType != ROW_LASTSEENEID)
                    break;
            }
            if(!last.pending) {
                eid = last.eid;
            }
        }
        if(eid >= 0 && eid >= _buffer.last_seen_eid) {
            [_conn heartbeat:_buffer.bid cid:_buffer.cid bid:_buffer.bid lastSeenEid:eid handler:nil];
            _buffer.last_seen_eid = eid;
        }
    }
    _heartbeatTimer = nil;
}

- (void)sendHeartbeat {
    if(!_heartbeatTimer)
        _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_sendHeartbeat) userInfo:nil repeats:NO];
}

- (void)handleEvent:(NSNotification *)notification {
    IRCCloudJSONObject *o;
    Event *e;
    Buffer *b;
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventHeartbeatEcho:
            [self updateUnread];
            if(_maxEid <= _buffer.last_seen_eid) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _topUnreadView.alpha = 0;
                [UIView commitAnimations];
            }
            break;
        case kIRCEventMakeBuffer:
            b = notification.object;
            if(_buffer.bid == -1 && b.cid == _buffer.cid && [[b.name lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) {
                _buffer = b;
                [self refresh];
            }
            break;
        case kIRCEventChannelTopic:
        case kIRCEventJoin:
        case kIRCEventPart:
        case kIRCEventNickChange:
        case kIRCEventQuit:
        case kIRCEventKick:
        case kIRCEventChannelMode:
        case kIRCEventUserMode:
        case kIRCEventUserChannelMode:
            o = notification.object;
            if(o.bid == _buffer.bid) {
                e = [[EventsDataSource sharedInstance] event:o.eid buffer:o.bid];
                if(e)
                    [self insertEvent:e backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventSelfDetails:
        case kIRCEventBufferMsg:
            e = notification.object;
            if(e.bid == _buffer.bid) {
                if(((e.from && [[e.from lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) || (e.nick && [[e.nick lowercaseString] isEqualToString:[_buffer.name lowercaseString]])) && e.reqId == -1) {
                    [_lock lock];
                    for(int i = 0; i < _data.count; i++) {
                        e = [_data objectAtIndex:i];
                        if(e.pending) {
                            if(i > 0) {
                                Event *p = [_data objectAtIndex:i-1];
                                if(p.rowType == ROW_TIMESTAMP) {
                                    [_data removeObject:p];
                                    i--;
                                }
                            }
                            [_data removeObject:e];
                            i--;
                        }
                    }
                    [_lock unlock];
                } else if(e.reqId != -1) {
                    CLS_LOG(@"Searching for pending message matching reqid %i", e.reqId);
                    int reqid = e.reqId;
                    [_lock lock];
                    for(int i = 0; i < _data.count; i++) {
                        e = [_data objectAtIndex:i];
                        if(e.reqId == reqid && (e.pending || e.rowType == ROW_FAILED)) {
                            CLS_LOG(@"Found at position %i", i);
                            if(i>0) {
                                Event *p = [_data objectAtIndex:i-1];
                                if(p.rowType == ROW_TIMESTAMP) {
                                    CLS_LOG(@"Removing timestamp row");
                                    [_data removeObject:p];
                                    i--;
                                }
                            }
                            CLS_LOG(@"Removing pending event");
                            [_data removeObject:e];
                            i--;
                        }
                    }
                    [_lock unlock];
                    CLS_LOG(@"Finished");
                }
                [self insertEvent:notification.object backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventSetIgnores:
            [self refresh];
            break;
        case kIRCEventUserInfo:
            for(Event *e in _data) {
                e.formatted = nil;
                e.timestamp = nil;
                e.formattedNick = nil;
                e.formattedRealname = nil;
                e.height = 0;
            }
            [self refresh];
            break;
        default:
            break;
    }
}

- (void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped {
    @synchronized(self) {
        BOOL colors = NO;
        if(!event.isSelf && __nickColorsPref)
            colors = YES;
        
        if(_minEid == 0)
            _minEid = event.eid;
        if(event.eid == _buffer.min_eid) {
            _tableView.tableHeaderView = nil;
        }
        if(event.eid < _earliestEid || _earliestEid == 0)
            _earliestEid = event.eid;
        
        NSTimeInterval eid = event.eid;
        NSString *type = event.type;
        if([type hasPrefix:@"you_"]) {
            type = [type substringFromIndex:4];
        }
        
        if([type isEqualToString:@"joined_channel"] || [type isEqualToString:@"parted_channel"] || [type isEqualToString:@"nickchange"] || [type isEqualToString:@"quit"] || [type isEqualToString:@"user_channel_mode"]|| [type isEqualToString:@"socket_closed"] || [type isEqualToString:@"connecting_failed"] || [type isEqualToString:@"connecting_cancelled"]) {
            _collapsedEvents.showChan = ![_buffer.type isEqualToString:@"channel"];
            if(__hideJoinPartPref && ![type isEqualToString:@"socket_closed"] && ![type isEqualToString:@"connecting_failed"] && ![type isEqualToString:@"connecting_cancelled"]) {
                [_lock lock];
                for(Event *e in _data) {
                    if(e.eid == event.eid) {
                        [_data removeObject:e];
                        break;
                    }
                }
                [_lock unlock];
                if(!backlog)
                    [_tableView reloadData];
                return;
            }
            
            [_formatter setDateFormat:@"DDD"];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:event.time];
            
            if(__expandJoinPartPref)
                [_expandedSectionEids removeAllObjects];
            
            if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
                Event *last = [[EventsDataSource sharedInstance] event:_lastCollapsedEid buffer:_buffer.bid];
                if(last) {
                    if(![last.type isEqualToString:@"socket_closed"] && ![last.type isEqualToString:@"connecting_failed"] && ![last.type isEqualToString:@"connecting_cancelled"])
                        _currentCollapsedEid = -1;
                }
            } else {
                Event *last = [[EventsDataSource sharedInstance] event:_lastCollapsedEid buffer:_buffer.bid];
                if(last) {
                    if([last.type isEqualToString:@"socket_closed"] || [last.type isEqualToString:@"connecting_failed"] || [last.type isEqualToString:@"connecting_cancelled"])
                        _currentCollapsedEid = -1;
                }
            }
            
            if(_currentCollapsedEid == -1 || ![[_formatter stringFromDate:date] isEqualToString:_lastCollpasedDay] || __expandJoinPartPref || [event.type isEqualToString:@"you_parted_channel"]) {
                [_collapsedEvents clear];
                _currentCollapsedEid = eid;
                _lastCollpasedDay = [_formatter stringFromDate:date];
            }
            
            if(!_collapsedEvents.showChan)
                event.chan = _buffer.name;
            
            if(![_collapsedEvents addEvent:event]) {
                [_collapsedEvents clear];
            }
            
            event.color = [UIColor collapsedRowTextColor];
            event.bgColor = [UIColor contentBackgroundColor];
            
            NSString *msg;
            if([_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) {
                CollapsedEvents *c = [[CollapsedEvents alloc] init];
                c.showChan = _collapsedEvents.showChan;
                c.server = _server;
                [c addEvent:event];
                msg = [c collapse];
                if(!nextIsGrouped) {
                    NSString *groupMsg = [_collapsedEvents collapse];
                    if(groupMsg == nil && [type isEqualToString:@"nickchange"])
                        groupMsg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO], BOLD];
                    if(groupMsg == nil && [type isEqualToString:@"user_channel_mode"]) {
                        if(event.from.length > 0)
                            groupMsg = [NSString stringWithFormat:@"%c%@%c was set to: %c%@%c by %c%@%c", BOLD, event.nick, BOLD, BOLD, event.diff, BOLD, BOLD, [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO], BOLD];
                        else
                            groupMsg = [NSString stringWithFormat:@"%@ was set to: %c%@%c by the server %c%@%c", event.nick, BOLD, event.diff, BOLD, BOLD, event.server, BOLD];
                    }
                    Event *heading = [[Event alloc] init];
                    heading.cid = event.cid;
                    heading.bid = event.bid;
                    heading.eid = _currentCollapsedEid - 1;
                    heading.groupMsg = [NSString stringWithFormat:@"%@%@",_groupIndent,groupMsg];
                    heading.color = [UIColor timestampColor];
                    heading.bgColor = [UIColor contentBackgroundColor];
                    heading.formattedMsg = nil;
                    heading.formatted = nil;
                    heading.linkify = NO;
                    [self _addItem:heading eid:_currentCollapsedEid - 1];
                    if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
                        Event *last = [[EventsDataSource sharedInstance] event:_lastCollapsedEid buffer:_buffer.bid];
                        if(last) {
                            if(last.msg.length == 0)
                                [_data removeObject:last];
                            else
                                last.rowType = ROW_MESSAGE;
                        }
                        event.rowType = ROW_SOCKETCLOSED;
                    }
                }
                event.timestamp = nil;
            } else {
                msg = (nextIsGrouped && _currentCollapsedEid != event.eid)?@"":[_collapsedEvents collapse];
            }
            if(msg == nil && [type isEqualToString:@"nickchange"])
                msg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO], BOLD];
            if(msg == nil && [type isEqualToString:@"user_channel_mode"]) {
                if(event.from.length > 0)
                    msg = [NSString stringWithFormat:@"%c%@%c was set to: %c%@%c by %c%@%c", BOLD, event.nick, BOLD, BOLD, event.diff, BOLD, BOLD, [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO], BOLD];
                else
                    msg = [NSString stringWithFormat:@"%@ was set to: %c%@%c by the server %c%@%c", event.nick, BOLD, event.diff, BOLD, BOLD, event.server, BOLD];
                _currentCollapsedEid = eid;
            }
            if([_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) {
                msg = [NSString stringWithFormat:@"%@%@", _groupIndent, msg];
            } else {
                if(eid != _currentCollapsedEid)
                    msg = [NSString stringWithFormat:@"%@%@", _groupIndent, msg];
                eid = _currentCollapsedEid;
            }
            event.groupMsg = msg;
            event.formattedMsg = nil;
            event.formatted = nil;
            event.linkify = NO;
            _lastCollapsedEid = event.eid;
            if(([_buffer.type isEqualToString:@"console"] && ![type isEqualToString:@"socket_closed"] && ![type isEqualToString:@"connecting_failed"] && ![type isEqualToString:@"connecting_cancelled"]) || [event.type isEqualToString:@"you_parted_channel"]) {
                _currentCollapsedEid = -1;
                _lastCollapsedEid = -1;
                [_collapsedEvents clear];
            }
            
        } else {
            _currentCollapsedEid = -1;
            _lastCollapsedEid = -1;
            [_collapsedEvents clear];
            
            if(!event.formatted.length || !event.formattedMsg.length) {
                if((__chatOneLinePref || ![event isMessage]) && [event.from length] && event.rowType != ROW_THUMBNAIL && event.rowType != ROW_FILE) {
                    event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:colors defaultColor:[UIColor isDarkTheme]?@"ffffff":@"142b43"], event.msg];
                } else {
                    event.formattedMsg = event.msg;
                }
            }
        }
        
        if(event.ignoreMask.length && [event isMessage]) {
            if((!_buffer || ![_buffer.type isEqualToString:@"conversation"]) && [_server.ignore match:event.ignoreMask]) {
                if(_topUnreadView.alpha == 0 && _bottomUnreadView.alpha == 0)
                    [self sendHeartbeat];
                return;
            }
        }
        
        if(!event.formatted) {
            if([type isEqualToString:@"channel_mode"] && event.nick.length > 0) {
                if(event.nick.length)
                    event.formattedMsg = [NSString stringWithFormat:@"%@ by %@", event.msg, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO]];
                else if(event.server.length)
                    event.formattedMsg = [NSString stringWithFormat:@"%@ by the server %c%@%c", event.msg, BOLD, event.server, CLEAR];
            } else if([type isEqualToString:@"buffer_me_msg"]) {
                event.formattedMsg = [NSString stringWithFormat:@"— %c%@ %@", ITALICS, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:colors], event.msg];
                event.rowType = ROW_ME_MESSAGE;
            } else if([type isEqualToString:@"notice"] || [type isEqualToString:@"buffer_msg"]) {
                Server *s = [[ServersDataSource sharedInstance] getServer:event.cid];
                if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_OPER]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[_collapsedEvents formatNick:@"Opers" mode:s.MODE_OPER colorize:NO],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_OWNER]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[_collapsedEvents formatNick:@"Owners" mode:s.MODE_OWNER colorize:NO],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_ADMIN]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[_collapsedEvents formatNick:@"Admins" mode:s.MODE_ADMIN colorize:NO],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_OP]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[_collapsedEvents formatNick:@"Ops" mode:s.MODE_OP colorize:NO],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_HALFOP]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[_collapsedEvents formatNick:@"Half Ops" mode:s.MODE_HALFOP colorize:NO],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_VOICED]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[_collapsedEvents formatNick:@"Voiced" mode:s.MODE_VOICED colorize:NO],BOLD];
                else
                    event.formattedMsg = @"";
                
                if([type isEqualToString:@"notice"]) {
                    if([_buffer.type isEqualToString:@"console"] && event.toChan && event.chan.length) {
                        event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%c%@%c: %@", BOLD, event.chan, BOLD, event.msg];
                    } else if([_buffer.type isEqualToString:@"console"] && event.isSelf && event.nick.length) {
                        event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%c%@%c: %@", BOLD, event.nick, BOLD, event.msg];
                    } else {
                        event.formattedMsg = [event.formattedMsg stringByAppendingString:event.msg];
                    }
                } else {
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:event.msg];
                }
                if(event.from.length && __chatOneLinePref && event.rowType != ROW_THUMBNAIL && event.rowType != ROW_FILE) {
                    if(!__disableQuotePref && event.formattedMsg.length > 0 && [event.formattedMsg hasPrefix:@">"]) {
                        Event *e1 = event.copy;
                        e1.eid = event.eid + ++event.childEventCount;
                        e1.timestamp = @"";
                        e1.formattedMsg = event.formattedMsg;
                        e1.parent = event.eid;
                        [self _addItem:e1 eid:e1.eid];
                        event.formattedMsg = [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:colors];
                    } else {
                        event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:colors], event.formattedMsg];
                    }
                }
            } else if([type isEqualToString:@"kicked_channel"]) {
                event.formattedMsg = [NSString stringWithFormat:@"%c%@← ", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString];
                if([event.type hasPrefix:@"you_"])
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:@"You"];
                else
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%@%c", event.oldNick, CLEAR];
                if([event.type hasPrefix:@"you_"])
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:@" were"];
                else
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:@" was"];
                if(event.hostmask && event.hostmask.length)
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by %@", [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO]];
                else
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by the server %c%@%@%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, event.nick, CLEAR];
                if(event.msg.length > 0 && ![event.msg isEqualToString:event.nick])
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@": %@", event.msg];
            } else if([type isEqualToString:@"channel_mode_list_change"]) {
                if(event.from.length == 0) {
                    if(event.nick.length)
                        event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO], event.msg];
                    else if(event.server.length)
                        event.formattedMsg = [NSString stringWithFormat:@"The server %c%@%c %@", BOLD, event.server, CLEAR, event.msg];
                }
            } else if([type isEqualToString:@"user_chghost"]) {
                event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO], event.msg];
            } else if([type isEqualToString:@"channel_name_change"]) {
                if(event.from.length) {
                    event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:colors], event.msg];
                } else {
                    NSString *from = @"The server ";
                    if(event.server.length)
                        from = [from stringByAppendingFormat:@"%@ ",event.server];
                    event.formattedMsg = [NSString stringWithFormat:@"%@%@", from, event.msg];
                }
            }
        }
        
        if(!__disableCodeBlockPref && event.rowType == ROW_MESSAGE && event.formattedMsg.length) {
            static NSRegularExpression *_pattern = nil;
            if(!_pattern) {
                NSString *pattern = @"```([\\s\\S]+?)```(?=(?!`)[\\W\\s\\n]|$)";
                _pattern = [NSRegularExpression
                            regularExpressionWithPattern:pattern
                            options:NSRegularExpressionCaseInsensitive
                            error:nil];
            }
            
            NSString *msg = event.formattedMsg;
            BOOL pending = event.pending;
            event.pending = NO;
            NSArray *matches = [_pattern matchesInString:msg options:0 range:NSMakeRange(0, msg.length)];
            if(matches.count) {
                NSUInteger start = 0;
                
                for(NSTextCheckingResult *result in matches) {
                    NSString *lastChunk = @"";
                    if(result.range.location)
                        lastChunk = [msg substringWithRange:NSMakeRange(start, result.range.location - start)];
                    if([lastChunk hasPrefix:@" "] && lastChunk.length > 1)
                        lastChunk = [lastChunk substringFromIndex:1];
                    if(start > 0) {
                        Event *e = [event copy];
                        e.eid = event.eid + ++event.childEventCount;
                        e.formattedMsg = lastChunk;
                        e.timestamp = @"";
                        e.parent = event.eid;
                        e.isHeader = NO;
                        e.pending = pending;
                        [self _addItem:e eid:e.eid];
                    } else {
                        event.formattedMsg = lastChunk;
                    }
                    if(result.range.location == 0 && !__chatOneLinePref) {
                        event.formattedMsg = [msg substringWithRange:NSMakeRange(result.range.location + 3, result.range.length - 6)];
                        event.isCodeBlock = YES;
                        event.color = [UIColor codeSpanForegroundColor];
                        event.monospace = YES;
                    } else {
                        Event *e = [event copy];
                        e.eid = event.eid + ++event.childEventCount;
                        e.formattedMsg = [msg substringWithRange:NSMakeRange(result.range.location + 3, result.range.length - 6)];
                        e.timestamp = @"";
                        e.parent = event.eid;
                        e.isCodeBlock = YES;
                        e.isHeader = NO;
                        e.color = [UIColor codeSpanForegroundColor];
                        e.monospace = YES;
                        e.pending = pending;
                        [self _addItem:e eid:e.eid];
                    }
                    start = result.range.location + result.range.length;
                }
                if(start < msg.length) {
                    Event *e = [event copy];
                    e.eid = event.eid + ++event.childEventCount;
                    e.formattedMsg = [msg substringWithRange:NSMakeRange(start, msg.length - start)];
                    if([e.formattedMsg hasPrefix:@" "] && e.formattedMsg.length > 1)
                        e.formattedMsg = [e.formattedMsg substringFromIndex:1];
                    e.timestamp = @"";
                    e.parent = event.eid;
                    e.isHeader = NO;
                    e.pending = pending;
                    if(e.formattedMsg.length)
                        [self _addItem:e eid:e.eid];
                }
                event.pending = pending;
            }
        } else {
            event.isCodeBlock = NO;
        }
        
        [self _addItem:event eid:eid];
        if(!backlog && !event.formatted && event.formattedMsg.length > 0) {
            [self _format:event];
        }
        
        if(!backlog) {
            [_tableView reloadData];
            if(!_buffer.scrolledUp) {
                [self scrollToBottom];
                [self _scrollToBottom];
                if(_topUnreadView.alpha == 0)
                    [self sendHeartbeat];
            } else if(!event.isSelf && [event isImportant:_buffer.type]) {
                _newMsgs++;
                if(event.isHighlight)
                    _newHighlights++;
                [self updateUnread];
                [self scrollViewDidScroll:_tableView];
            }
        }
        
        if(!__disableInlineFilesPref) {
            NSTimeInterval entity_eid = event.eid;
            for(NSDictionary *entity in [event.entities objectForKey:@"files"]) {
                entity_eid = event.eid + ++event.childEventCount;
                if([_closedPreviews containsObject:@(entity_eid)])
                    continue;
                
                @synchronized (_filePropsCache) {
                    NSDictionary *properties = [_filePropsCache objectForKey:[entity objectForKey:@"id"]];
                    if(properties) {
                        [self insertEvent:[self entity:event eid:entity_eid properties:properties] backlog:backlog nextIsGrouped:NO];
                    } else {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSDictionary *properties = [_conn propertiesForFile:[entity objectForKey:@"id"]];
                            if(properties) {
                                @synchronized (_filePropsCache) {
                                    [_filePropsCache setObject:properties forKey:[entity objectForKey:@"id"]];
                                }
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [self insertEvent:[self entity:event eid:entity_eid properties:properties] backlog:NO nextIsGrouped:NO];
                                }];
                            }
                        });
                    }
                }
            }
            if(_buffer.last_seen_eid == event.eid)
                _buffer.last_seen_eid = entity_eid;
        }
    }
}

-(Event *)entity:(Event *)parent eid:(NSTimeInterval)eid properties:(NSDictionary *)properties {
    Event *e1 = [[Event alloc] init];
    e1.cid = parent.cid;
    e1.bid = parent.bid;
    e1.eid = eid;
    e1.from = parent.from;
    e1.nick = parent.nick;
    e1.isSelf = parent.isSelf;
    e1.fromMode = parent.fromMode;
    e1.realname = parent.realname;
    e1.hostmask = parent.hostmask;
    e1.parent = parent.eid;
    if([[properties objectForKey:@"mime_type"] hasPrefix:@"image/"] && ![[properties objectForKey:@"mime_type"] isEqualToString:@"image/webp"])
        e1.rowType = ROW_THUMBNAIL;
    else
        e1.rowType = ROW_FILE;
    
    int bytes = [[properties objectForKey:@"size"] intValue];
    if(bytes < 1024) {
        e1.msg = [NSString stringWithFormat:@"%lu B", (unsigned long)bytes];
    } else {
        int exp = (int)(log(bytes) / log(1024));
        e1.msg = [NSString stringWithFormat:@"%.1f %cB", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1]];
    }
    e1.bgColor = e1.isSelf?[UIColor selfBackgroundColor]:parent.bgColor;
    if([parent.type isEqualToString:@"buffer_me_msg"])
        e1.type = @"buffer_msg";
    else
        e1.type = parent.type;
    e1.entities = properties;
    
    return e1;
}

-(void)updateTopUnread:(NSInteger)firstRow {
    if(!_topUnreadView)
        return;
    int highlights = 0;
    for(NSNumber *pos in _unseenHighlightPositions) {
        if([pos intValue] > firstRow)
            break;
        highlights++;
    }
    NSString *msg = @"";
    if(highlights) {
        if(highlights == 1)
            msg = @"mention and ";
        else
            msg = @"mentions and ";
        _topHighlightsCountView.count = [NSString stringWithFormat:@"%i", highlights];
        _topHighlightsCountView.hidden = NO;
        _topUnreadLabelXOffsetConstraint.constant = _topHighlightsCountView.intrinsicContentSize.width + 2;
    } else {
        _topHighlightsCountView.hidden = YES;
        _topUnreadLabelXOffsetConstraint.constant = 0;
    }
    if(_lastSeenEidPos == 0 && firstRow < _data.count) {
        int seconds;
        if(firstRow < 0)
            seconds = (_earliestEid - _buffer.last_seen_eid) / 1000000;
        else
            seconds = ([[_data objectAtIndex:firstRow] eid] - _buffer.last_seen_eid) / 1000000;
        if(seconds < 0) {
            _topUnreadView.alpha = 0;
        } else {
            int minutes = seconds / 60;
            int hours = minutes / 60;
            int days = hours / 24;
            if(days) {
                if(days == 1)
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i day of unread messages", days];
                else
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i days of unread messages", days];
            } else if(hours) {
                if(hours == 1)
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i hour of unread messages", hours];
                else
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i hours of unread messages", hours];
            } else if(minutes) {
                if(minutes == 1)
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i minute of unread messages", minutes];
                else
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i minutes of unread messages", minutes];
            } else {
                if(seconds == 1)
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i second of unread messages", seconds];
                else
                    _topUnreadLabel.text = [msg stringByAppendingFormat:@"%i seconds of unread messages", seconds];
            }
        }
    } else {
        if(firstRow - _lastSeenEidPos == 1) {
            _topUnreadLabel.text = [msg stringByAppendingFormat:@"%li unread message", (long)(firstRow - _lastSeenEidPos)];
        } else if(firstRow - _lastSeenEidPos > 0) {
            _topUnreadLabel.text = [msg stringByAppendingFormat:@"%li unread messages", (long)(firstRow - _lastSeenEidPos)];
        } else {
            _topUnreadView.alpha = 0;
        }
    }
}

-(void)updateUnread {
    if(!_bottomUnreadView)
        return;
    NSString *msg = @"";
    if(_newHighlights) {
        if(_newHighlights == 1)
            msg = @"mention";
        else
            msg = @"mentions";
        _bottomHighlightsCountView.count = [NSString stringWithFormat:@"%li", (long)_newHighlights];
        _bottomHighlightsCountView.hidden = NO;
        _bottomUnreadLabelXOffsetConstraint.constant = _bottomHighlightsCountView.intrinsicContentSize.width + 2;
    } else {
        _bottomHighlightsCountView.hidden = YES;
        _bottomUnreadLabelXOffsetConstraint.constant = _bottomHighlightsCountView.intrinsicContentSize.width + 2;
    }
    if(_newMsgs - _newHighlights > 0) {
        if(_newHighlights)
            msg = [msg stringByAppendingString:@" and "];
        if(_newMsgs - _newHighlights == 1)
            msg = [msg stringByAppendingFormat:@"%li unread message", (long)(_newMsgs - _newHighlights)];
        else
            msg = [msg stringByAppendingFormat:@"%li unread messages", (long)(_newMsgs - _newHighlights)];
    }
    if(msg.length) {
        _bottomUnreadLabel.text = msg;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        _bottomUnreadView.alpha = 1;
        [UIView commitAnimations];
    }
}

-(void)_addItem:(Event *)e eid:(NSTimeInterval)eid {
    if(!e)
        return;
    @synchronized(self) {
        [_lock lock];
        NSInteger insertPos = -1;
        NSString *lastDay = nil;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:e.time];
        if(!e.timestamp) {
            if(__24hrPref) {
                if(__secondsPref)
                    [_formatter setDateFormat:@"HH:mm:ss"];
                else
                    [_formatter setDateFormat:@"HH:mm"];
            } else if(__secondsPref) {
                [_formatter setDateFormat:@"h:mm:ss a"];
            } else {
                [_formatter setDateFormat:@"h:mm a"];
            }
            
            e.timestamp = [_formatter stringFromDate:date];
        }
        if(!e.day) {
            [_formatter setDateFormat:@"DDD"];
            e.day = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:e.time]];
        }
        if(e.groupMsg && !e.formattedMsg) {
            e.formattedMsg = e.groupMsg;
            e.formatted = nil;
            e.height = 0;
        }
        e.groupEid = _currentCollapsedEid;
        
        if(eid > _maxEid || _data.count == 0 || (eid == e.eid && [e compare:[_data objectAtIndex:_data.count - 1]] == NSOrderedDescending)) {
            //Message at bottom
            if(_data.count) {
                lastDay = ((Event *)[_data objectAtIndex:_data.count - 1]).day;
            }
            _maxEid = eid;
            [_data addObject:e];
            insertPos = _data.count - 1;
        } else if(_minEid > eid) {
            //Message on top
            if(_data.count > 1) {
                lastDay = ((Event *)[_data objectAtIndex:1]).day;
                if(![lastDay isEqualToString:e.day]) {
                    //Insert above the dateline
                    [_data insertObject:e atIndex:0];
                    insertPos = 0;
                } else {
                    //Insert below the dateline
                    [_data insertObject:e atIndex:1];
                    insertPos = 1;
                }
            } else {
                [_data insertObject:e atIndex:0];
                insertPos = 0;
            }
        } else {
            int i = 0;
            for(Event *e1 in _data) {
                if(e1.rowType != ROW_TIMESTAMP && [e compare:e1] == NSOrderedAscending && e.eid == eid) {
                    //Insert the message
                    if(i > 0 && ((Event *)[_data objectAtIndex:i - 1]).rowType != ROW_TIMESTAMP) {
                        lastDay = ((Event *)[_data objectAtIndex:i - 1]).day;
                        [_data insertObject:e atIndex:i];
                        insertPos = i;
                        break;
                    } else {
                        //There was a dateline above our insertion point
                        lastDay = e1.day;
                        if(![lastDay isEqualToString:e.day]) {
                            if(i > 1) {
                                lastDay = ((Event *)[_data objectAtIndex:i - 2]).day;
                            } else {
                                //We're above the first dateline, so we'll need to put a new one on top
                                lastDay = nil;
                            }
                            [_data insertObject:e atIndex:i-1];
                            insertPos = i-1;
                        } else {
                            //Insert below the dateline
                            [_data insertObject:e atIndex:i];
                            insertPos = i;
                        }
                        break;
                    }
                } else if(e1.rowType != ROW_TIMESTAMP && (e1.eid == eid || e1.groupEid == eid)) {
                    //Replace the message
                    lastDay = e.day;
                    [_data removeObjectAtIndex:i];
                    [_data insertObject:e atIndex:i];
                    insertPos = i;
                    break;
                }
                i++;
            }
        }
        
        if(insertPos == -1) {
            CLS_LOG(@"Couldn't insert EID: %f MSG: %@", eid, e.formattedMsg);
            [_lock unlock];
            return;
        }
        
        [_rowCache removeObjectForKey:@(insertPos)];
        
        if(eid > _buffer.last_seen_eid && e.isHighlight) {
            [_unseenHighlightPositions addObject:@(insertPos)];
            [_unseenHighlightPositions sortUsingSelector:@selector(compare:)];
        }
        
        if(eid < _minEid || _minEid == 0)
            _minEid = eid;
        
        if(![lastDay isEqualToString:e.day]) {
            [_formatter setDateFormat:@"EEEE, MMMM dd, yyyy"];
            Event *d = [[Event alloc] init];
            d.type = TYPE_TIMESTMP;
            d.rowType = ROW_TIMESTAMP;
            d.eid = eid;
            d.groupEid = -1;
            d.timestamp = [_formatter stringFromDate:date];
            d.bgColor = [UIColor timestampBackgroundColor];
            d.day = e.day;
            [_data insertObject:d atIndex:insertPos++];
        }
        
        if(insertPos > 0) {
            Event *prev = [_data objectAtIndex:insertPos - 1];
            if(prev.rowType == ROW_LASTSEENEID)
                prev = [_data objectAtIndex:insertPos - 2];
            e.isHeader = !__chatOneLinePref && (e.groupEid < 1 && [e isMessage] && (![prev.type isEqualToString:e.type] || ![prev.from isEqualToString:e.from]));
            e.height = 0;
        }
        
        if(insertPos < _data.count - 1) {
            Event *next = [_data objectAtIndex:insertPos + 1];
            if(![e isMessage] && e.rowType != ROW_LASTSEENEID) {
                next.isHeader = (next.groupEid < 1 && [next isMessage]);
                next.height = 0;
                [_rowCache removeObjectForKey:@(insertPos + 1)];
            }
            if([next.type isEqualToString:e.type] && [next.from isEqualToString:e.from]) {
                e.isHeader = NO;
                e.height = 0;
            }
        }
        
        [_lock unlock];
    }
}

-(Buffer *)buffer {
    return _buffer;
}

-(void)setBuffer:(Buffer *)buffer {
    _ready = NO;
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    _requestingBacklog = NO;
    if(buffer != _buffer) {
        _bottomRow = -1;
        [[ImageCache sharedInstance] clear];
    }
    if(_buffer && _buffer.scrolledUp) {
        NSLog(@"Table was scrolled up, adjusting scroll offset");
        [_lock lock];
        int row = 0;
        NSInteger toprow = [_tableView indexPathForRowAtPoint:CGPointMake(0,_buffer.savedScrollOffset)].row;
        if(_tableView.tableHeaderView != nil)
            row++;
        for(Event *event in _data) {
            if((event.rowType == ROW_LASTSEENEID && [[EventsDataSource sharedInstance] unreadStateForBuffer:_buffer.bid lastSeenEid:_buffer.last_seen_eid type:_buffer.type] == 0) || event.rowType == ROW_BACKLOG) {
                if(toprow > row) {
                    NSLog(@"Adjusting scroll offset");
                    _buffer.savedScrollOffset -= 26;
                }
            }
            if(++row > toprow)
                break;
        }
        [_lock unlock];
    }
    if(_buffer && buffer.bid != _buffer.bid) {
        for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:buffer.bid]) {
            if(event.rowType == ROW_LASTSEENEID) {
                [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                break;
            }
            event.formatted = nil;
            event.timestamp = nil;
        }
        _topUnreadView.alpha = 0;
        _bottomUnreadView.alpha = 0;
    }
    _buffer = buffer;
    if(buffer)
        _server = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    else
        _server = nil;
    _earliestEid = 0;
    [_expandedSectionEids removeAllObjects];
    [self refresh];
}

- (void)_scrollToBottom {
    [_lock lock];
    _scrollTimer = nil;
    _buffer.scrolledUp = NO;
    _buffer.scrolledUpFrom = -1;
    if(_data.count) {
        if(_tableView.contentSize.height > (_tableView.frame.size.height - _tableView.contentInset.top - _tableView.contentInset.bottom))
            [_tableView setContentOffset:CGPointMake(0, (_tableView.contentSize.height - _tableView.frame.size.height) + _tableView.contentInset.bottom)];
        else
            [_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top)];
        if([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
            [self scrollViewDidScroll:_tableView];
    }
    [_lock unlock];
}

- (void)scrollToBottom {
    [_scrollTimer invalidate];
    
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_scrollToBottom) userInfo:nil repeats:NO];
}

- (void)refresh {
    @synchronized(self) {
        __24hrPref = NO;
        __secondsPref = NO;
        __timeLeftPref = NO;
        __nickColorsPref = NO;
        __hideJoinPartPref = NO;
        __expandJoinPartPref = NO;
        __avatarsOffPref = NO;
        __chatOneLinePref = NO;
        __norealnamePref = NO;
        __monospacePref = NO;
        __disableInlineFilesPref = NO;
        __compact = NO;
        __disableBigEmojiPref = NO;
        __disableCodeSpanPref = NO;
        __disableCodeBlockPref = NO;
        __disableQuotePref = NO;
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        if(prefs) {
            __monospacePref = [[prefs objectForKey:@"font"] isEqualToString:@"mono"];
            __nickColorsPref = [[prefs objectForKey:@"nick-colors"] boolValue];
            __secondsPref = [[prefs objectForKey:@"time-seconds"] boolValue];
            __24hrPref = [[prefs objectForKey:@"time-24hr"] boolValue];
            __timeLeftPref = [[NSUserDefaults standardUserDefaults] boolForKey:@"time-left"];
            __avatarsOffPref = [[NSUserDefaults standardUserDefaults] boolForKey:@"avatars-off"];
            __chatOneLinePref = [[NSUserDefaults standardUserDefaults] boolForKey:@"chat-oneline"];
            if(!__chatOneLinePref && !__avatarsOffPref)
                __timeLeftPref = NO;
            __norealnamePref = [[NSUserDefaults standardUserDefaults] boolForKey:@"chat-norealname"];
            __compact = [[prefs objectForKey:@"ascii-compact"] boolValue];
            __disableBigEmojiPref = [[prefs objectForKey:@"emoji-nobig"] boolValue];
            __disableCodeSpanPref = [[prefs objectForKey:@"chat-nocodespan"] boolValue];
            __disableCodeBlockPref = [[prefs objectForKey:@"chat-nocodeblock"] boolValue];
            __disableQuotePref = [[prefs objectForKey:@"chat-noquote"] boolValue];

            NSDictionary *hiddenMap;
            
            if([_buffer.type isEqualToString:@"channel"]) {
                hiddenMap = [prefs objectForKey:@"channel-hideJoinPart"];
            } else {
                hiddenMap = [prefs objectForKey:@"buffer-hideJoinPart"];
            }
            
            if([[prefs objectForKey:@"hideJoinPart"] boolValue] || (hiddenMap && [[hiddenMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])) {
                __hideJoinPartPref = YES;
            }
            
            NSDictionary *expandMap;
            
            if([_buffer.type isEqualToString:@"channel"]) {
                expandMap = [prefs objectForKey:@"channel-expandJoinPart"];
            } else if([_buffer.type isEqualToString:@"console"]) {
                expandMap = [prefs objectForKey:@"buffer-expandDisco"];
            } else {
                expandMap = [prefs objectForKey:@"buffer-expandJoinPart"];
            }
            
            if([[prefs objectForKey:@"expandJoinPart"] boolValue] || (expandMap && [[expandMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]))
                __expandJoinPartPref = YES;
            
            NSDictionary *disableFilesMap;
            
            if([_buffer.type isEqualToString:@"channel"]) {
                disableFilesMap = [prefs objectForKey:@"channel-files-disableinline"];
            } else {
                disableFilesMap = [prefs objectForKey:@"buffer-files-disableinline"];
            }
            
            if([[prefs objectForKey:@"files-disableinline"] boolValue] || (disableFilesMap && [[disableFilesMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]))
                __disableInlineFilesPref = YES;
            
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"inlineWifiOnly"] && ![NetworkConnection sharedInstance].isWifi)
                __disableInlineFilesPref = YES;
        }
        __largeAvatarHeight = MIN(32, roundf(FONT_SIZE * 2) + (__compact ? 1 : 6));
        if(__monospacePref)
            _groupIndent = @"  ";
        else
            _groupIndent = @"    ";
        _tableView.backgroundColor = [UIColor contentBackgroundColor];
        _headerView.backgroundColor = [UIColor contentBackgroundColor];
        _backlogFailedView.backgroundColor = [UIColor contentBackgroundColor];
        [_loadMoreBacklog setTitleColor:[UIColor isDarkTheme]?[UIColor navBarSubheadingColor]:[UIColor unreadBlueColor] forState:UIControlStateNormal];
        [_loadMoreBacklog setTitleShadowColor:[UIColor contentBackgroundColor] forState:UIControlStateNormal];
        _loadMoreBacklog.backgroundColor = [UIColor contentBackgroundColor];
        
        _linkAttributes = [UIColor linkAttributes];
        _lightLinkAttributes = [UIColor lightLinkAttributes];
        
        __socketClosedBackgroundImage = nil;
        [UIColor socketClosedBackgroundColor];
        
        [_lock lock];
        [_scrollTimer invalidate];
        _ready = NO;
        NSInteger oldPosition = (_requestingBacklog && _data.count && [_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset)].count)?[[[_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset)] objectAtIndex: 0] row]:-1;
        NSTimeInterval backlogEid = (_requestingBacklog && _data.count && oldPosition < _data.count)?[[_data objectAtIndex:oldPosition] groupEid]-1:0;
        if(backlogEid < 1)
            backlogEid = (_requestingBacklog && _data.count && oldPosition < _data.count)?[[_data objectAtIndex:oldPosition] eid]-1:0;
        
        [_data removeAllObjects];
        @synchronized (_rowCache) {
            [_rowCache removeAllObjects];
        }
        _minEid = _maxEid = _earliestEid = _newMsgs = _newHighlights = 0;
        _lastSeenEidPos = -1;
        _currentCollapsedEid = 0;
        _lastCollpasedDay = @"";
        [_collapsedEvents clear];
        _collapsedEvents.server = _server;
        [_unseenHighlightPositions removeAllObjects];
        _hiddenAvatarRow = -1;
        _stickyAvatar.hidden = YES;
        __smallAvatarHeight = roundf(FONT_SIZE) + 1;
        if (__smallAvatarHeight % 2) {
            __smallAvatarHeight += 1;
        }
        
        if(!_buffer) {
            [_lock unlock];
            _tableView.tableHeaderView = nil;
            [_tableView reloadData];
            return;
        }
        
        if(_conn.state == kIRCCloudStateConnected)
            [[NetworkConnection sharedInstance] cancelIdleTimer]; //This may take a while
        UIFont *f = __monospacePref?[ColorFormatter monoTimestampFont]:[ColorFormatter timestampFont];
        __timestampWidth = [@"88:88" sizeWithAttributes:@{NSFontAttributeName:f}].width;
        if(__secondsPref)
            __timestampWidth += [@":88" sizeWithAttributes:@{NSFontAttributeName:f}].width;
        if(!__24hrPref)
            __timestampWidth += [@" AM" sizeWithAttributes:@{NSFontAttributeName:f}].width;
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 11)
            __timestampWidth += 4;
        
        _file_url_template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"file_uri_template"] error:nil];
        _paste_url_template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"pastebin_uri_template"] error:nil];
        
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
        if(events.count) {
            for(Event *e in events) {
                if(e.childEventCount) {
                    e.formatted = nil;
                    e.formattedMsg = nil;
                }
                [self insertEvent:e backlog:true nextIsGrouped:false];
            }
            _tableView.tableHeaderView = nil;
        }
        
        if(backlogEid > 0) {
            Event *e = [[Event alloc] init];
            e.eid = backlogEid;
            e.type = TYPE_BACKLOG;
            e.rowType = ROW_BACKLOG;
            e.formattedMsg = nil;
            e.bgColor = [UIColor contentBackgroundColor];
            [self _addItem:e eid:backlogEid];
            e.timestamp = nil;
        }
        
        if(_buffer.last_seen_eid == 0 && _data.count > 1) {
            _lastSeenEidPos = 1;
        } else if((_minEid > 0 && _minEid >= _buffer.last_seen_eid) || (_data.count == 0 && _buffer.last_seen_eid > 0)) {
            _lastSeenEidPos = 0;
        } else {
            Event *e = [[Event alloc] init];
            e.cid = _buffer.cid;
            e.bid = _buffer.bid;
            e.type = TYPE_LASTSEENEID;
            e.rowType = ROW_LASTSEENEID;
            e.formattedMsg = nil;
            e.bgColor = [UIColor contentBackgroundColor];
            e.timestamp = @"New Messages";
            _lastSeenEidPos = _data.count - 1;
            NSEnumerator *i = [_data reverseObjectEnumerator];
            Event *event = [i nextObject];
            while(event) {
                if(event.eid <= _buffer.last_seen_eid && event.rowType != ROW_LASTSEENEID)
                    break;
                e.eid = event.eid - 1;
                event = [i nextObject];
                _lastSeenEidPos--;
            }
            if(_lastSeenEidPos != _data.count - 1 && !event.isSelf && !event.pending) {
                if(_lastSeenEidPos > 0 && [[_data objectAtIndex:_lastSeenEidPos - 1] rowType] == ROW_TIMESTAMP)
                    _lastSeenEidPos--;
                if(_lastSeenEidPos > 0) {
                    for(Event *event in events) {
                        if(event.rowType == ROW_LASTSEENEID) {
                            [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                            [_data removeObject:event];
                            break;
                        }
                    }
                    [[EventsDataSource sharedInstance] addEvent:e];
                    [self _addItem:e eid:e.eid];
                    e.groupEid = -1;
                }
            } else {
                _lastSeenEidPos = -1;
            }
        }
        
        _backlogFailedView.frame = _headerView.frame = CGRectMake(0,0,_headerView.frame.size.width, 60);
        
        [_tableView reloadData];
        
        if(events.count)
            _earliestEid = ((Event *)[events objectAtIndex:0]).eid;
        if(events.count && _earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected && _conn.ready && _tableView.contentSize.height > _tableView.bounds.size.height) {
            _tableView.tableHeaderView = _headerView;
        } else if((!_data.count || _earliestEid > _buffer.min_eid) && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected && _conn.ready) {
            _tableView.tableHeaderView = _backlogFailedView;
        } else {
            _tableView.tableHeaderView = nil;
        }
        
        @try {
            if(_requestingBacklog && backlogEid > 0 && _buffer.scrolledUp) {
                int markerPos = -1;
                for(Event *e in _data) {
                    if(e.eid == backlogEid)
                        break;
                    markerPos++;
                }
                if(markerPos < [_tableView numberOfRowsInSection:0])
                    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:markerPos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            } else if(_eidToOpen > 0) {
                if(_eidToOpen <= _maxEid) {
                    int i = 0;
                    for(Event *e in _data) {
                        if(e.eid == _eidToOpen) {
                            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                            _buffer.scrolledUpFrom = [[_data objectAtIndex:[[[_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset)] lastObject] row]] eid];
                            break;
                        }
                        i++;
                    }
                    _eidToOpen = -1;
                } else {
                    if(!_buffer.scrolledUp)
                        _buffer.scrolledUpFrom = -1;
                }
            } else if(_buffer.scrolledUp && _buffer.savedScrollOffset > 0) {
                if((_buffer.savedScrollOffset + _tableView.tableHeaderView.bounds.size.height) < _tableView.contentSize.height - _tableView.bounds.size.height) {
                    _tableView.contentOffset = CGPointMake(0, (_buffer.savedScrollOffset + _tableView.tableHeaderView.bounds.size.height));
                } else {
                    [self _scrollToBottom];
                    [self scrollToBottom];
                }
            } else if(!_buffer.scrolledUp || (_data.count && _scrollTimer)) {
                [self _scrollToBottom];
                [self scrollToBottom];
            }
        } @catch (NSException *e) {
            NSLog(@"Unable to set scroll position: %@", e);
        }
        
        if(_data.count == 0 && _buffer.bid != -1 && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected && [UIApplication sharedApplication].applicationState == UIApplicationStateActive && _conn.ready && !_requestingBacklog) {
            _tableView.tableHeaderView = _backlogFailedView;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSArray *rows = [_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset)];
            if(_data.count && rows.count) {
                NSInteger firstRow = [[rows objectAtIndex:0] row];
                NSInteger lastRow = [[rows lastObject] row];
                Event *e = ((_lastSeenEidPos+1) < _data.count)?[_data objectAtIndex:_lastSeenEidPos+1]:nil;
                if(e && ((_lastSeenEidPos > 0 && firstRow > _lastSeenEidPos) || _lastSeenEidPos == 0) && e.eid >= _buffer.last_seen_eid) {
                    if(_topUnreadView.alpha == 0) {
                        [UIView beginAnimations:nil context:nil];
                        [UIView setAnimationDuration:0.1];
                        _topUnreadView.alpha = 1;
                        [UIView commitAnimations];
                    }
                    [self updateTopUnread:firstRow];
                } else if(lastRow < _lastSeenEidPos) {
                    for(Event *e in _data) {
                        if(_buffer.last_seen_eid > 0 && e.eid > _buffer.last_seen_eid && !e.isSelf && e.rowType != ROW_LASTSEENEID && [e isImportant:_buffer.type]) {
                            _newMsgs++;
                            if(e.isHighlight)
                                _newHighlights++;
                        }
                    }
                } else {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    _topUnreadView.alpha = 0;
                    [UIView commitAnimations];
                }
                _requestingBacklog = NO;
            } else if(_earliestEid > _buffer.last_seen_eid) {
                if(_topUnreadView.alpha == 0) {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    _topUnreadView.alpha = 1;
                    [UIView commitAnimations];
                }
                [self updateTopUnread:-1];
            }
            
            [self updateUnread];
            _ready = YES;
            [self scrollViewDidScroll:_tableView];
            [_tableView flashScrollIndicators];
            
            if(_buffer.deferred && _conn.state == kIRCCloudStateConnected && _conn.ready) {
                [self loadMoreBacklogButtonPressed:nil];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    @synchronized (_rowCache) {
        [_rowCache removeAllObjects];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [_lock lock];
    NSInteger count = _data.count;
    [_lock unlock];
    return count;
}

- (void)_format:(Event *)e {
    @synchronized (e) {
        NSArray *links;
        [_lock lock];
        if(!__disableBigEmojiPref) {
            NSMutableString *msg = [[e.msg stripIRCFormatting] mutableCopy];
            if(msg) {
                [ColorFormatter emojify:msg];
                e.isEmojiOnly = [ColorFormatter emojiOnly:msg];
            }
        } else {
            e.isEmojiOnly = NO;
        }
        if(e.from.length)
            e.formattedNick = [ColorFormatter format:[_collapsedEvents formatNick:e.from mode:e.fromMode colorize:(__nickColorsPref && !e.isSelf) defaultColor:[UIColor isDarkTheme]?@"ffffff":@"142b43"] defaultColor:e.color mono:__monospacePref linkify:NO server:nil links:nil];
        if([e.realname isKindOfClass:[NSString class]] && e.realname.length) {
            e.formattedRealname = [ColorFormatter format:e.realname defaultColor:[UIColor collapsedRowTextColor] mono:__monospacePref linkify:YES server:_server links:&links];
            e.realnameLinks = links;
            links = nil;
        }
        if(!__disableQuotePref && e.rowType == ROW_MESSAGE && e.formattedMsg.length > 1 && [e.formattedMsg hasPrefix:@">"]) {
            e.formattedMsg = [e.formattedMsg substringFromIndex:1];
            e.isQuoted = YES;
        } else {
            e.isQuoted = NO;
        }
        if(e.groupEid < 0 && (e.from.length || e.rowType == ROW_ME_MESSAGE) && !__avatarsOffPref && (__chatOneLinePref || e.rowType == ROW_ME_MESSAGE) && e.rowType != ROW_THUMBNAIL && e.rowType != ROW_FILE && e.parent == 0)
            e.formatted = [ColorFormatter format:[NSString stringWithFormat:(__monospacePref || e.monospace)?@"   %@":@"     %@",e.formattedMsg] defaultColor:e.color mono:__monospacePref || e.monospace linkify:e.linkify server:_server links:&links largeEmoji:e.isEmojiOnly codeSpans:!__disableCodeSpanPref];
        else
            e.formatted = [ColorFormatter format:e.formattedMsg defaultColor:e.color mono:__monospacePref || e.monospace linkify:e.linkify server:_server links:&links largeEmoji:e.isEmojiOnly codeSpans:!__disableCodeSpanPref];
        
        if(e.formatted.length) {
            NSMutableAttributedString *padded = e.formatted.mutableCopy;
            [padded appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            e.formattedPadded = padded;
        }
        
        if([e.entities objectForKey:@"files"] || [e.entities objectForKey:@"pastes"]) {
            NSMutableArray *mutableLinks = links.mutableCopy;
            for(int i = 0; i < mutableLinks.count; i++) {
                NSTextCheckingResult *r = [mutableLinks objectAtIndex:i];
                if(r.resultType == NSTextCheckingTypeLink) {
                    for(NSDictionary *file in [e.entities objectForKey:@"files"]) {
                        NSString *url = [_file_url_template relativeStringWithVariables:@{@"id":[file objectForKey:@"id"]} error:nil];
                        if(([[file objectForKey:@"mime_type"] hasPrefix:@"image/"] || [[file objectForKey:@"mime_type"] hasPrefix:@"video/"]) && ([r.URL.absoluteString isEqualToString:url] || [r.URL.absoluteString hasPrefix:[url stringByAppendingString:@"/"]])) {
                            NSString *extension = [file objectForKey:@"extension"];
                            if(!extension.length)
                                extension = [@"." stringByAppendingString:[[file objectForKey:@"mime_type"] substringFromIndex:[[file objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1]];
                            r = [NSTextCheckingResult linkCheckingResultWithRange:r.range URL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", url, [[file objectForKey:@"mime_type"] substringToIndex:5], extension]]];
                            [mutableLinks setObject:r atIndexedSubscript:i];
                        }
                    }
                    for(NSDictionary *paste in [e.entities objectForKey:@"pastes"]) {
                        NSString *url = [_paste_url_template relativeStringWithVariables:@{@"id":[paste objectForKey:@"id"]} error:nil];
                        if(([r.URL.absoluteString isEqualToString:url] || [r.URL.absoluteString hasPrefix:[url stringByAppendingString:@"/"]])) {
                            r = [NSTextCheckingResult linkCheckingResultWithRange:r.range URL:[NSURL URLWithString:[NSString stringWithFormat:@"irccloud-paste-%@?id=%@&own_paste=%@", url, [paste objectForKey:@"id"], [paste objectForKey:@"own_paste"]]]];
                            [mutableLinks setObject:r atIndexedSubscript:i];
                        }
                    }
                }
            }
            links = mutableLinks;
        }
        e.links = links;
        
        if(e.from.length && e.msg.length) {
            e.accessibilityLabel = [NSString stringWithFormat:@"Message from %@: at %@", e.from, e.timestamp];
            e.accessibilityValue = [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string];
        } else if([e.type isEqualToString:@"buffer_me_msg"]) {
            e.accessibilityLabel = [NSString stringWithFormat:@"Action: at %@", e.timestamp];
            e.accessibilityValue = [NSString stringWithFormat:@"%@ %@", e.nick, [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]];
        } else if(e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE) {
            NSMutableString *s = [[[ColorFormatter format:e.formattedMsg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string] mutableCopy];
            if(s.length > 1) {
                [s replaceOccurrencesOfString:@"→" withString:@"" options:0 range:NSMakeRange(0, 1)];
                [s replaceOccurrencesOfString:@"←" withString:@"" options:0 range:NSMakeRange(0, 1)];
                [s replaceOccurrencesOfString:@"⇐" withString:@"" options:0 range:NSMakeRange(0, 1)];
                [s replaceOccurrencesOfString:@"•" withString:@"" options:0 range:NSMakeRange(0, s.length)];
                [s replaceOccurrencesOfString:@"↔" withString:@"" options:0 range:NSMakeRange(0, 1)];
                
                if([e.type hasSuffix:@"nickchange"])
                    [s replaceOccurrencesOfString:@"→" withString:@"changed their nickname to" options:0 range:NSMakeRange(0, s.length)];
            }
            e.accessibilityLabel = [NSString stringWithFormat:@"Status message: at %@", e.timestamp];
            e.accessibilityValue = s;
        }
        
        if((e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE || e.rowType == ROW_FAILED || e.rowType == ROW_SOCKETCLOSED) && e.groupEid > 0 && (e.groupEid != e.eid || [_expandedSectionEids objectForKey:@(e.groupEid)])) {
            NSMutableString *s = [[[ColorFormatter format:e.formattedMsg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string] mutableCopy];
            [s replaceOccurrencesOfString:@"→" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"←" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"⇐" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"•" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"↔" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            if([s rangeOfString:@"."].location != NSNotFound)
                [s replaceCharactersInRange:[s rangeOfString:@"."] withString:@""];
            e.accessibilityValue = s;
        }
        [self _calculateHeight:e];
        [_lock unlock];
    }
}

- (void)_calculateHeight:(Event *)e {
    if(e.rowType == ROW_THUMBNAIL) {
        float width = self.tableView.bounds.size.width/2;
        if(![[e.entities objectForKey:@"properties"] objectForKey:@"width"] || ![[e.entities objectForKey:@"properties"] objectForKey:@"height"]) {
            UIImage *img = [[ImageCache sharedInstance] imageForFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)];
            if(img) {
                NSMutableDictionary *entities = [e.entities mutableCopy];
                [entities setObject:@{@"width":@(img.size.width), @"height":@(img.size.height)} forKey:@"properties"];
                e.entities = entities;
                e.height = ceilf([[[e.entities objectForKey:@"properties"] objectForKey:@"height"] floatValue]) + (__compact?18:24);
            } else {
                e.height = 64;
            }
        } else {
            if(width > [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue])
                width = [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue];
            float ratio = width / [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue];
            e.height = ceilf([[[e.entities objectForKey:@"properties"] objectForKey:@"height"] floatValue] * ratio) + (__compact?18:24);
        }
        e.height += FONT_SIZE + 2;
        if([[e.entities objectForKey:@"name"] length])
            e.height += FONT_SIZE + 2;
    } else if(e.rowType == ROW_FILE) {
        e.height = FONT_SIZE * 3 + (__compact?24:30);
    } else {
        float avatarWidth = (__avatarsOffPref || __chatOneLinePref)?0:(__largeAvatarHeight+17);
        float estimatedWidth = _tableView.frame.size.width - 4 - __timestampWidth - avatarWidth - ((e.rowType == ROW_FAILED)?20:0);
        estimatedWidth -= (__timeLeftPref || (!__avatarsOffPref && !__chatOneLinePref))?12:22;
        if(__timeLeftPref && !__chatOneLinePref && __avatarsOffPref)
            estimatedWidth -= 4;
        
        if(!__disableQuotePref && e.isQuoted)
            estimatedWidth -= 12;
        
        if(e.isCodeBlock)
            estimatedWidth -= 8;
        
        static LinkLabel *message = nil;
        if(!message) {
            message = [[LinkLabel alloc] init];
            message.backgroundColor = [UIColor clearColor];
            message.textColor = [UIColor messageTextColor];
            message.numberOfLines = 0;
            message.lineBreakMode = NSLineBreakByWordWrapping;
            message.userInteractionEnabled = YES;
            message.baselineAdjustment = UIBaselineAdjustmentNone;
        }
        message.attributedText = e.formatted;
        
        e.height = floorf([message sizeThatFits:CGSizeMake(estimatedWidth, CGFLOAT_MAX)].height + ((e.rowType == ROW_SOCKETCLOSED)?(FONT_SIZE-2):0));
        if(!__compact)
            e.height += MESSAGE_LINE_PADDING;
        else
            e.height += 2;
        e.timestampPosition = [ColorFormatter messageFont:__monospacePref].ascender - (__monospacePref?[ColorFormatter monoTimestampFont].ascender:[ColorFormatter timestampFont].ascender);
        e.estimatedWidth = estimatedWidth;
        
        if(!__chatOneLinePref && e.isHeader && e.formattedNick.length) {
            e.height += [LinkLabel heightOfString:e.formattedNick constrainedToWidth:estimatedWidth] + (__compact?2:MESSAGE_LINE_PADDING);
            if(e.height < __largeAvatarHeight + (__compact?1:MESSAGE_LINE_PADDING))
                e.height = __largeAvatarHeight + (__compact?1:MESSAGE_LINE_PADDING);
        }
        
        if(e.isCodeBlock)
            e.height += 8;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [_lock lock];
    if(indexPath.row >= _data.count) {
        CLS_LOG(@"Requested height for out of bounds row, refreshing");
        [_lock unlock];
        [self refresh];
        return 0;
    }
    Event *e = [_data objectAtIndex:indexPath.row];
    [_lock unlock];
    @synchronized (e) {
        if(e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE || e.rowType == ROW_SOCKETCLOSED || e.rowType == ROW_FAILED || e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE) {
            if(e.rowType == ROW_SOCKETCLOSED && e.formattedMsg.length == 0) {
                return (FONT_SIZE-2);
            } else if(e.formatted != nil && e.height > 0) {
                //NSLog(@"MSG: %@ Height: %f", e.msg, e.height);
                return e.height;
            } else if(!e.formatted && e.formattedMsg.length > 0) {
                [self _format:e];
                //NSLog(@"MSG: %@ Height: %f", e.msg, e.height);
                return e.height;
            } else if(e.height == 0 && e.formatted) {
                [self _calculateHeight:e];
                //NSLog(@"MSG: %@ Height: %f", e.msg, e.height);
                return e.height;
            }
        } else if(e.rowType == ROW_LASTSEENEID) {
            return __compact?FONT_SIZE:26;
        } else if(e.rowType == ROW_BACKLOG) {
            return __compact?4:26;
        }
    }
    return 26;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized (_rowCache) {
        EventsTableCell *cell = [_rowCache objectForKey:@(indexPath.row)];
        if(!cell)
            cell = [[EventsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [_rowCache setObject:cell forKey:@(indexPath.row)];
        [_lock lock];
        if([indexPath row] >= _data.count) {
            CLS_LOG(@"Requested out of bounds row, refreshing");
            cell.type = ROW_MESSAGE;
            cell.message.text = @"";
            cell.timestamp.text = @"";
            cell.accessory.hidden = YES;
            [_lock unlock];
            [self refresh];
            return cell;
        }
        Event *e = [_data objectAtIndex:indexPath.row];
        [_lock unlock];
        if(!e.formatted && e.formattedMsg.length > 0) {
            [self _format:e];
            if(e.formatted) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [_tableView reloadData];
                }];
                CLS_LOG(@"Event was formatted during cellForRowAtIndexPath, reloading table heights");
            }
        }
        cell.type = e.rowType;
        cell.backgroundView = nil;
        cell.backgroundColor = nil;
        cell.contentView.backgroundColor = e.bgColor;
        if(e.isHeader) {
            NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithAttributedString:e.formattedNick];
            if(e.formattedRealname && ([e.realname isKindOfClass:[NSString class]] && ![e.realname.lowercaseString isEqualToString:e.from.lowercaseString]) && !__norealnamePref) {
                [s appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
                [s appendAttributedString:e.formattedRealname];
            }
            cell.nickname.attributedText = s;
            cell.avatar.hidden = __avatarsOffPref || (indexPath.row == _hiddenAvatarRow);
            cell.quoteBorder.hidden = YES;
        } else {
            cell.nickname.text = nil;
            cell.avatar.hidden = !((__chatOneLinePref || e.rowType == ROW_ME_MESSAGE) && !__avatarsOffPref && e.parent == 0 && e.groupEid < 1);
            cell.quoteBorder.hidden = !e.isQuoted;
            cell.quoteBorder.backgroundColor = [UIColor quoteBorderColor];
        }
        if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE) {
            cell.avatar.image = nil;
        } else {
            float avatarHeight = __avatarsOffPref?0:((__chatOneLinePref || e.rowType == ROW_ME_MESSAGE)?__smallAvatarHeight:__largeAvatarHeight);
            if(e.from.length && !__avatarsOffPref) {
                cell.avatar.image = [[[AvatarsDataSource sharedInstance] getAvatar:e.from bid:e.bid] getImage:avatarHeight isSelf:e.isSelf];
            } else if(e.rowType == ROW_ME_MESSAGE && !__avatarsOffPref && e.nick.length) {
                cell.avatar.image = [[[AvatarsDataSource sharedInstance] getAvatar:e.nick bid:e.bid] getImage:__smallAvatarHeight isSelf:e.isSelf];
            } else {
                cell.avatar.image = nil;
            }
        }
        cell.timestamp.font = __monospacePref?[ColorFormatter monoTimestampFont]:[ColorFormatter timestampFont];
        cell.message.linkDelegate = self;
        cell.nickname.linkDelegate = self;
        cell.timestampPosition = e.timestampPosition;
        cell.accessory.font = [ColorFormatter awesomeFont];
        cell.accessory.textColor = [UIColor expandCollapseIndicatorColor];
        cell.accessoryOffset = 0;
        cell.accessibilityLabel = e.accessibilityLabel;
        cell.accessibilityValue = e.accessibilityValue;
        cell.accessibilityHint = nil;
        cell.accessibilityElementsHidden = NO;
        cell.messageWidth = e.estimatedWidth;
        
        if(cell.messageTextColor != e.color || ![cell.message.attributedText.string isEqualToString:e.formattedPadded.string]) {
            cell.messageTextColor = e.color;
            cell.message.attributedText = e.formattedPadded;
            
            if((e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE || e.rowType == ROW_FAILED || e.rowType == ROW_SOCKETCLOSED) && e.groupEid > 0 && (e.groupEid != e.eid || [_expandedSectionEids objectForKey:@(e.groupEid)])) {
                if([_expandedSectionEids objectForKey:@(e.groupEid)]) {
                    if(e.groupEid == e.eid + 1) {
                        cell.accessory.text = FA_MINUS_SQUARE_O;
                        cell.contentView.backgroundColor = [UIColor collapsedHeadingBackgroundColor];
                        cell.accessibilityLabel = [NSString stringWithFormat:@"Expanded status messages heading. at %@", e.timestamp];
                        cell.accessibilityHint = @"Collapses this group";
                    } else {
                        cell.accessory.text = FA_ANGLE_RIGHT;
                        cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
                        cell.accessibilityLabel = [NSString stringWithFormat:@"Expanded status message. at %@", e.timestamp];
                        cell.accessibilityHint = @"Collapses this group";
                        cell.accessoryOffset = -1;
                    }
                } else {
                    cell.accessory.text = FA_PLUS_SQUARE_O;
                    cell.accessibilityLabel = [NSString stringWithFormat:@"Collapsed status messages. at %@", e.timestamp];
                    cell.accessibilityHint = @"Expands this group";
                }
                cell.accessory.hidden = NO;
            } else if(e.rowType == ROW_FAILED) {
                cell.accessory.hidden = NO;
                cell.accessory.text = FA_EXCLAMATION_TRIANGLE;
                cell.accessory.textColor = [UIColor networkErrorColor];
            } else {
                cell.accessory.hidden = YES;
            }
            
            if(e.links.count) {
                if(e.pending || [e.color isEqual:[UIColor timestampColor]])
                    cell.message.linkAttributes = _lightLinkAttributes;
                else
                    cell.message.linkAttributes = _linkAttributes;
                @try {
                    for(NSTextCheckingResult *result in e.links) {
                        if(result.resultType == NSTextCheckingTypeLink) {
                            if(result.URL)
                                [cell.message addLinkWithTextCheckingResult:result];
                        } else {
                            NSString *url = [[e.formatted attributedSubstringFromRange:result.range] string];
                            if(![url hasPrefix:@"irc"]) {
                                CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                                if(url_escaped != NULL) {
                                    url = [NSString stringWithFormat:@"irc://%i/%@", _server.cid, url_escaped];
                                    CFRelease(url_escaped);
                                }
                            }
                            NSURL *u = [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]];
                            if(u)
                                [cell.message addLinkToURL:u withRange:result.range];
                        }
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"An exception occured while setting the links, the table is probably being reloaded: %@", exception);
                }
            }
            if(cell.nickname.text.length && e.realnameLinks.count) {
                cell.nickname.linkAttributes = _lightLinkAttributes;
                @try {
                    for(NSTextCheckingResult *result in e.realnameLinks) {
                        if(result.resultType == NSTextCheckingTypeLink) {
                            if(result.URL)
                                [cell.nickname addLinkToURL:result.URL withRange:NSMakeRange(result.range.location + e.formattedNick.length + 1, result.range.length)];
                        } else {
                            NSString *url = [[e.formattedRealname attributedSubstringFromRange:result.range] string];
                            if(![url hasPrefix:@"irc"]) {
                                CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                                if(url_escaped != NULL) {
                                    url = [NSString stringWithFormat:@"irc://%i/%@", _server.cid, url_escaped];
                                    CFRelease(url_escaped);
                                }
                            }
                            NSURL *u = [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]];
                            if(u)
                                [cell.nickname addLinkToURL:u withRange:NSMakeRange(result.range.location + e.formattedNick.length + 1, result.range.length)];
                        }
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"An exception occured while setting the links, the table is probably being reloaded: %@", exception);
                }
            }
        }
        if(e.rowType == ROW_LASTSEENEID)
            cell.timestamp.text = @"New Messages";
        else
            cell.timestamp.text = e.timestamp;
        if(e.rowType == ROW_TIMESTAMP) {
            cell.timestamp.font = [ColorFormatter messageFont:__monospacePref];
            cell.timestamp.textColor = [UIColor messageTextColor];
        } else if(e.isHighlight && !e.isSelf) {
            cell.timestamp.textColor = [UIColor highlightTimestampColor];
        } else if(e.rowType == ROW_FAILED || [e.bgColor isEqual:[UIColor errorBackgroundColor]]) {
            cell.timestamp.textColor = [UIColor networkErrorColor];
        } else {
            cell.timestamp.textColor = [UIColor timestampColor];
        }
        if(e.rowType == ROW_BACKLOG) {
            cell.timestamp.backgroundColor = [UIColor backlogDividerColor];
            cell.accessibilityElementsHidden = YES;
        } else if(e.rowType == ROW_LASTSEENEID) {
            cell.timestamp.backgroundColor = [UIColor contentBackgroundColor];
        } else {
            cell.timestamp.backgroundColor = [UIColor clearColor];
        }
        if(e.rowType == ROW_THUMBNAIL) {
            float width = self.tableView.bounds.size.width/2;
            if([[[e.entities objectForKey:@"properties"] objectForKey:@"width"] intValue] && [[[e.entities objectForKey:@"properties"] objectForKey:@"height"] intValue]) {
                if(width > [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue])
                    width = [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue];
                float ratio = width / [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue];
                cell.thumbnailWidth = ceilf([[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue] * ratio);
                cell.thumbnailHeight = ceilf([[[e.entities objectForKey:@"properties"] objectForKey:@"height"] floatValue] * ratio);
            } else {
                cell.thumbnailWidth = width;
                cell.thumbnailHeight = 48;
            }
            cell.mimeType.text = [NSString stringWithFormat:@"%@ • %@", [e.entities objectForKey:@"mime_type"], e.msg];
            cell.thumbnail.image = [[ImageCache sharedInstance] imageForFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)];
            cell.spinner.hidden = (cell.thumbnail.image != nil);
            if(!cell.thumbnail.image) {
                if(![[NSFileManager defaultManager] fileExistsAtPath:[[ImageCache sharedInstance] pathForFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)].path]) {
                    [[ImageCache sharedInstance] fetchFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale) completionHandler:^(UIImage *img) {
                        if(img) {
                            if(![[e.entities objectForKey:@"properties"] objectForKey:@"width"] || ![[e.entities objectForKey:@"properties"] objectForKey:@"height"]) {
                                NSMutableDictionary *entities = [e.entities mutableCopy];
                                [entities setObject:@{@"width":@(img.size.width), @"height":@(img.size.height)} forKey:@"properties"];
                                e.entities = entities;
                            }
                            [self _calculateHeight:e];
                        } else {
                            e.rowType = ROW_FILE;
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.tableView reloadData];
                        }];
                    }];
                } else {
                    e.rowType = ROW_FILE;
                    cell.thumbnailWidth = 0;
                    cell.thumbnailHeight = 0;
                    cell.spinner.hidden = YES;
                }
            } else if(![[e.entities objectForKey:@"properties"] objectForKey:@"height"]) {
                NSMutableDictionary *entities = [e.entities mutableCopy];
                [entities setObject:@{@"width":@(cell.thumbnail.image.size.width), @"height":@(cell.thumbnail.image.size.height)} forKey:@"properties"];
                e.entities = entities;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSLog(@"Image dimensions were missing, reloading table");
                    [self _calculateHeight:e];
                    [self.tableView reloadData];
                }];
            }
        } else {
            cell.thumbnail.image = nil;
            cell.thumbnailWidth = 0;
            cell.thumbnailHeight = 0;
            cell.spinner.hidden = YES;
        }
        
        if(e.rowType == ROW_FILE) {
            NSString *extension = [e.entities objectForKey:@"extension"];
            if(extension.length)
                extension = [extension substringFromIndex:1];
            else
                extension = [[e.entities objectForKey:@"mime_type"] substringFromIndex:[[e.entities objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1];
            
            cell.extension.text = extension.uppercaseString;
            cell.mimeType.text = [e.entities objectForKey:@"mime_type"];
            cell.spinner.hidden = YES;
        }
        
        cell.filename.text = [e.entities objectForKey:@"name"];
        cell.emojiOnly = e.isEmojiOnly;
        cell.codeBlockBackground.backgroundColor = [UIColor codeSpanBackgroundColor];
        cell.codeBlockBackground.hidden = !e.isCodeBlock;
        return cell;
    }
}

- (void)LinkLabel:(LinkLabel *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:result.URL];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

-(IBAction)dismissButtonPressed:(id)sender {
    if(_topUnreadView.alpha) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        _topUnreadView.alpha = 0;
        [UIView commitAnimations];
        [self sendHeartbeat];
    }
}

-(IBAction)topUnreadBarClicked:(id)sender {
    if(_topUnreadView.alpha) {
        if(!_buffer.scrolledUp) {
            _buffer.scrolledUpFrom = [[_data lastObject] eid];
            _buffer.scrolledUp = YES;
        }
        if(_lastSeenEidPos > 0) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            _topUnreadView.alpha = 0;
            [UIView commitAnimations];
            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSeenEidPos+1 inSection:0] atScrollPosition: UITableViewScrollPositionTop animated: YES];
            [self scrollViewDidScroll:_tableView];
            [self sendHeartbeat];
        } else {
            if(_tableView.tableHeaderView == _backlogFailedView)
                [self loadMoreBacklogButtonPressed:nil];
            [_tableView setContentOffset:CGPointMake(0,0) animated:YES];
        }
    }
}

-(IBAction)bottomUnreadBarClicked:(id)sender {
    if(_bottomUnreadView.alpha) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        _bottomUnreadView.alpha = 0;
        [UIView commitAnimations];
        if(_data.count) {
            if(_tableView.contentSize.height > (_tableView.frame.size.height - _tableView.contentInset.top - _tableView.contentInset.bottom))
                [_tableView setContentOffset:CGPointMake(0, (_tableView.contentSize.height - _tableView.frame.size.height) + _tableView.contentInset.bottom) animated:YES];
            else
                [_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];
        }
        _buffer.scrolledUp = NO;
        _buffer.scrolledUpFrom = -1;
    }
}

#pragma mark - Table view delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_delegate dismissKeyboard];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!_ready || !_buffer || _requestingBacklog || [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        _stickyAvatar.hidden = YES;
        if(_hiddenAvatarRow != -1) {
            EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
            cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
            _hiddenAvatarRow = -1;
        }
        return;
    }
    
    if(_previewingRow) {
        EventsTableCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_previewingRow inSection:0]];
        __previewer.sourceRect = cell.frame;
    }
    
    UITableView *tableView = _tableView;
    NSInteger firstRow = -1;
    NSInteger lastRow = -1;
    NSArray *rows = [tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(tableView.bounds, tableView.contentInset)];
    if(rows.count) {
        firstRow = [[rows objectAtIndex:0] row];
        lastRow = [[rows lastObject] row];
    } else {
        _stickyAvatar.hidden = YES;
        if(_hiddenAvatarRow != -1) {
            EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
            cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
            _hiddenAvatarRow = -1;
        }
    }
    
    if(tableView.tableHeaderView == _headerView && _minEid > 0 && _buffer && _buffer.bid != -1 && (_buffer.scrolledUp || !_data.count || (_data.count && firstRow == 0 && lastRow == _data.count - 1))) {
        if(_conn.state == kIRCCloudStateConnected && scrollView.contentOffset.y < _headerView.frame.size.height && _conn.ready) {
            CLS_LOG(@"The table scrolled and the loading header became visible, requesting more backlog");
            _requestingBacklog = YES;
            [_conn cancelPendingBacklogRequests];
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid completion:nil];
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Downloading more chat history");
            _stickyAvatar.hidden = YES;
            if(_hiddenAvatarRow != -1) {
                EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
                cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
                _hiddenAvatarRow = -1;
            }
            return;
        }
    }
    
    if(rows.count && _topUnreadView) {
        if(_data.count) {
            if(lastRow < _data.count)
                _buffer.savedScrollOffset = floorf(tableView.contentOffset.y - tableView.tableHeaderView.bounds.size.height);
            
            if(floorf(tableView.contentOffset.y) >= floorf(tableView.contentSize.height - (tableView.bounds.size.height - tableView.contentInset.top - tableView.contentInset.bottom))) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _bottomUnreadView.alpha = 0;
                [UIView commitAnimations];
                _newMsgs = 0;
                _newHighlights = 0;
                _buffer.scrolledUp = NO;
                _buffer.scrolledUpFrom = -1;
                _buffer.savedScrollOffset = -1;
                [self sendHeartbeat];
            } else if (!_buffer.scrolledUp && (lastRow+1) < _data.count) {
                _buffer.scrolledUpFrom = [[_data objectAtIndex:lastRow+1] eid];
                _buffer.scrolledUp = YES;
            }
            
            if(_lastSeenEidPos >= 0) {
                if(_lastSeenEidPos > 0 && firstRow < _lastSeenEidPos + 1) {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    _topUnreadView.alpha = 0;
                    [UIView commitAnimations];
                    [self sendHeartbeat];
                } else {
                    [self updateTopUnread:firstRow];
                }
            }
            
            if(tableView.tableHeaderView != _headerView && _earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && firstRow > 0 && lastRow < _data.count && _conn.state == kIRCCloudStateConnected)
                tableView.tableHeaderView = _headerView;
        }
    }
    
    if(rows.count && !__chatOneLinePref && !__avatarsOffPref && scrollView.contentOffset.y > _headerView.frame.size.height) {
        int offset = ((_topUnreadView.alpha == 0)?0:_topUnreadView.bounds.size.height);
        NSUInteger i = firstRow;
        CGRect rect;
        NSIndexPath *topIndexPath;
        do {
            topIndexPath = [NSIndexPath indexPathForRow:i++ inSection:0];
            rect = [_tableView convertRect:[_tableView rectForRowAtIndexPath:topIndexPath] toView:_tableView.superview];
        } while(i < _data.count && rect.origin.y + rect.size.height <= offset - 1);
        Event *e = [_data objectAtIndex:firstRow];
        if((e.groupEid < 1 && e.from.length && [e isMessage]) || e.rowType == ROW_LASTSEENEID) {
            float groupHeight = rect.size.height;
            for(i = firstRow; i < _data.count - 1 && i < firstRow + 4; i++) {
                e = [_data objectAtIndex:i];
                if(e.rowType == ROW_LASTSEENEID)
                    e = [_data objectAtIndex:i-1];
                NSUInteger next = i+1;
                Event *e1 = [_data objectAtIndex:next];
                if(e1.rowType == ROW_LASTSEENEID) {
                    next++;
                    e1 = [_data objectAtIndex:next];
                }
                if([e.from isEqualToString:e1.from] && e1.groupEid < 1 && !e1.isHeader) {
                    rect = [_tableView convertRect:[_tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:next inSection:0]] toView:_tableView.superview];
                    groupHeight += rect.size.height;
                } else {
                    break;
                }
            }
            if(e.from.length && !(((Event *)[_data objectAtIndex:firstRow]).rowType == ROW_LASTSEENEID && groupHeight == 26) && (!e.isHeader || groupHeight > __largeAvatarHeight + 14)) {
                _stickyAvatarYOffsetConstraint.constant = rect.origin.y + rect.size.height - (__largeAvatarHeight + (__compact?1:2));
                if(_stickyAvatarYOffsetConstraint.constant >= offset + (__compact?1:2))
                    _stickyAvatarYOffsetConstraint.constant = offset + (__compact?1:2);
                if(_hiddenAvatarRow != topIndexPath.row) {
                    _stickyAvatar.image = [[[AvatarsDataSource sharedInstance] getAvatar:e.from bid:e.bid] getImage:__largeAvatarHeight isSelf:e.isSelf];
                    _stickyAvatar.hidden = NO;
                    if(_hiddenAvatarRow != -1) {
                        EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
                        cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
                    }
                    EventsTableCell *cell = [_rowCache objectForKey:@(topIndexPath.row)];
                    cell.avatar.hidden = YES;
                    _hiddenAvatarRow = topIndexPath.row;
                }
            } else {
                _stickyAvatar.hidden = YES;
                if(_hiddenAvatarRow != -1) {
                    EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
                    cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
                    _hiddenAvatarRow = -1;
                }
            }
        } else {
            _stickyAvatar.hidden = YES;
            if(_hiddenAvatarRow != -1) {
                EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
                cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
                _hiddenAvatarRow = -1;
            }
        }
    } else {
        _stickyAvatar.hidden = YES;
        if(_hiddenAvatarRow != -1) {
            EventsTableCell *cell = [_rowCache objectForKey:@(_hiddenAvatarRow)];
            cell.avatar.hidden = !((Event *)[_data objectAtIndex:_hiddenAvatarRow]).isHeader;
            _hiddenAvatarRow = -1;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.row < _data.count) {
        NSTimeInterval group = ((Event *)[_data objectAtIndex:indexPath.row]).groupEid;
        if(group > 0) {
            int count = 0;
            for(Event *e in _data) {
                if(e.groupEid == group)
                    count++;
            }
            if(count > 1 || [((Event *)[_data objectAtIndex:indexPath.row]).groupMsg hasPrefix:_groupIndent]) {
                if([_expandedSectionEids objectForKey:@(group)])
                    [_expandedSectionEids removeObjectForKey:@(group)];
                else if(((Event *)[_data objectAtIndex:indexPath.row]).eid != group)
                    [_expandedSectionEids setObject:@(YES) forKey:@(group)];
                for(Event *e in _data) {
                    e.timestamp = nil;
                    e.formatted = nil;
                }
                if(!_buffer.scrolledUp) {
                    _buffer.scrolledUpFrom = [[_data lastObject] eid];
                    _buffer.scrolledUp = YES;
                }
                _buffer.savedScrollOffset = floorf(_tableView.contentOffset.y - _tableView.tableHeaderView.bounds.size.height);
                [self refresh];
            }
        } else if(indexPath.row < _data.count) {
            Event *e = [_data objectAtIndex:indexPath.row];
            if([e.type isEqualToString:@"channel_invite"])
                [_conn join:e.oldNick key:nil cid:e.cid handler:nil];
            else if([e.type isEqualToString:@"callerid"])
                [_conn say:[NSString stringWithFormat:@"/accept %@", e.nick] to:nil cid:e.cid handler:nil];
            else if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE) {
                NSString *extension = [e.entities objectForKey:@"extension"];
                if(!extension.length)
                    extension = [@"." stringByAppendingString:[[e.entities objectForKey:@"mime_type"] substringFromIndex:[[e.entities objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1]];
                [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [_file_url_template relativeStringWithVariables:@{@"id":[e.entities objectForKey:@"id"]} error:nil], [[e.entities objectForKey:@"mime_type"] substringToIndex:5], extension]]];
            } else
                [_delegate rowSelected:e];
        }
    }
}

-(void)clearLastSeenMarker {
    [_lock lock];
    for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid]) {
        if(event.rowType == ROW_LASTSEENEID) {
            [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
            break;
        }
    }
    for(Event *event in _data) {
        if(event.rowType == ROW_LASTSEENEID) {
            [_data removeObject:event];
            break;
        }
    }
    [_lock unlock];
    [_tableView reloadData];
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:_tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                Event *e = [_data objectAtIndex:indexPath.row];
                EventsTableCell *c = (EventsTableCell *)[_tableView cellForRowAtIndexPath:indexPath];
                NSURL *url;
                if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE)
                    url = [NSURL URLWithString:[e.entities objectForKey:@"url"]];
                else
                    url = [c.message linkAtPoint:[gestureRecognizer locationInView:c.message]].URL;
                if(url) {
                    if([url.scheme hasPrefix:@"irc"] && [url.host intValue] > 0 && url.path && url.path.length > 1) {
                        Server *s = [[ServersDataSource sharedInstance] getServer:[url.host intValue]];
                        if(s != nil) {
                            if(s.ssl > 0)
                                url = [NSURL URLWithString:[NSString stringWithFormat:@"ircs://%@%@", s.hostname, [url.path stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                            else
                                url = [NSURL URLWithString:[NSString stringWithFormat:@"irc://%@%@", s.hostname, [url.path stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                        }
                    } else if([url.scheme hasPrefix:@"irccloud-paste-"]) {
                        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", [url.scheme substringFromIndex:15], url.host, url.path]];
                    }
                }
                [_delegate rowLongPressed:[_data objectAtIndex:indexPath.row] rect:[_tableView rectForRowAtIndexPath:indexPath] link:url.absoluteString];
            }
        }
    }
}

-(NSString *)YUNoHeartbeat {
    if(!_ready)
        return @"Events table view not ready";
    if(!_buffer)
        return @"No buffer";
    if(_requestingBacklog)
        return @"Currently requesting backlog";
    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        return @"Application state not active";
    if(!_topUnreadView)
        return @"Can't find top chatter bar";
    if(_topUnreadView.alpha != 0)
        return @"Top chatter bar is visible";
    if(_bottomUnreadView.alpha != 0)
        return @"Bottom chatter bar is visible";
    if([NetworkConnection sharedInstance].notifier)
        return @"Connected as a notifier socket";
    if(![self.slidingViewController topViewHasFocus])
        return @"A drawer is open";
    if(_conn.state != kIRCCloudStateConnected)
        return @"Websocket not in Connected state";
    if(_lastSeenEidPos == 0)
        return @"New Messages marker is above the loaded backlog";
    UITableView *tableView = _tableView;
    NSInteger firstRow = -1;
    NSInteger lastRow = -1;
    NSArray *rows = [tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(tableView.bounds, tableView.contentInset)];
    if(rows.count) {
        firstRow = [[rows objectAtIndex:0] row];
        lastRow = [[rows lastObject] row];
    } else {
        return @"Empty table view";
    }
    if(_lastSeenEidPos > 0 && firstRow >= _lastSeenEidPos)
        return @"New Messages marker is above the current visible range";
    NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
    NSTimeInterval eid = _buffer.scrolledUpFrom;
    if(eid <= 0) {
        Event *last;
        for(NSInteger i = events.count - 1; i >= 0; i--) {
            last = [events objectAtIndex:i];
            if(!last.pending && last.rowType != ROW_LASTSEENEID)
                break;
        }
        if(!last.pending) {
            eid = last.eid;
        }
    }
    if(eid < 0 || eid < _buffer.last_seen_eid)
        return @"eid <= last_seen_eid";
    if(floorf(tableView.contentOffset.y) >= floorf(tableView.contentSize.height - (tableView.bounds.size.height - tableView.contentInset.top - tableView.contentInset.bottom)))
        return @"This channel should be marked as read";
    else
        return @"Table view is not scrolled to the bottom";
}

-(CGRect)rectForEvent:(Event *)event {
    int i = 0;
    for(Event *e in _data) {
        if(event == e)
            break;
        i++;
    }
    if(i < _data.count) {
        return [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    } else {
        return CGRectZero;
    }
}
@end

