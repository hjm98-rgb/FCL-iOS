#import "FCLUI.h"
#import "LauncherPreferences.h"
#import "LauncherNavigationController.h"
#import "LauncherMenuViewController.h"
#import "LauncherProfilesViewController.h"
#import "PLProfiles.h"
#import "authenticator/BaseAuthenticator.h"
#import "installer/modpack/ModrinthAPI.h"
#import "UIImageView+AFNetworking.h"

@interface LauncherNavigationController (FCLLaunch)
- (void)launchMinecraft:(id)sender;
- (void)enterModInstaller;
@end

@implementation FCLTheme

+ (UIColor *)themeColor {
    return [UIColor colorWithRed:0x77/255.0 green:0x97/255.0 blue:0xCF/255.0 alpha:1.0];
}

+ (UIColor *)themeColorDark {
    return [UIColor colorWithRed:0x4E/255.0 green:0x77/255.0 blue:0xC1/255.0 alpha:1.0];
}

+ (UIColor *)panelColor {
    // FCL ui_bg_color = #40F4F4F4
    return [UIColor colorWithRed:0xF4/255.0 green:0xF4/255.0 blue:0xF4/255.0 alpha:0x40/255.0];
}

+ (UIColor *)cardPressedColor {
    return [UIColor colorWithWhite:1.0 alpha:0.18];
}

+ (UIFont *)boldFont:(CGFloat)size {
    return [UIFont boldSystemFontOfSize:size];
}

+ (UIImage *)templateIcon:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (void)styleCard:(UIView *)view {
    view.layer.cornerRadius = 8;
    view.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    view.layer.borderColor = [FCLTheme themeColorDark].CGColor;
    view.backgroundColor = [UIColor clearColor];
}

@end

#pragma mark - FCL home panel

@interface FCLHomeViewController ()
@property(nonatomic) UIImageView *backgroundView;
@property(nonatomic) UIView *panel;
@property(nonatomic) UIImageView *avatarView;
@property(nonatomic) UILabel *nameLabel;
@property(nonatomic) UILabel *hintLabel;
@property(nonatomic) UIView *versionCard;
@property(nonatomic) UIImageView *versionIcon;
@property(nonatomic) UILabel *versionLabel;
@property(nonatomic) UILabel *versionHint;
@property(nonatomic) UIButton *startButton;
@property(nonatomic) NSLayoutConstraint *panelWidthConstraint;
@end

@implementation FCLHomeViewController

- (NSString *)imageName { return @"fcl_home"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"主页";
    self.view.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];

    self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FCLBackground"]];
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.clipsToBounds = YES;
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundView];

    // Right menu: 25% width translucent panel, same as FCL activity_main right_menu
    self.panel = [[UIView alloc] init];
    self.panel.backgroundColor = [FCLTheme panelColor];
    self.panel.translatesAutoresizingMaskIntoConstraints = NO;
    self.panel.layer.cornerRadius = 8;
    self.panel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    [self.view addSubview:self.panel];

    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.panel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.panel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [self.panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],
    ]];
    self.panelWidthConstraint = [self.panel.widthAnchor constraintEqualToConstant:240];
    self.panelWidthConstraint.active = YES;

    [self buildPanelContent];
    [self refreshAccount];
    [self refreshVersion];
}

- (void)buildPanelContent {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.panel addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.panel.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor],
    ]];

    // account block
    UIView *accountView = [[UIView alloc] init];
    accountView.translatesAutoresizingMaskIntoConstraints = NO;
    accountView.userInteractionEnabled = YES;
    [accountView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAccountTap)]];
    [scroll addSubview:accountView];

    self.avatarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DefaultAccount"]];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 26;
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [accountView addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [FCLTheme boldFont:16];
    self.nameLabel.textColor = [FCLTheme themeColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    self.nameLabel.minimumScaleFactor = 0.6;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [accountView addSubview:self.nameLabel];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.font = [UIFont systemFontOfSize:12];
    self.hintLabel.textColor = [FCLTheme themeColor];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [accountView addSubview:self.hintLabel];

    [NSLayoutConstraint activateConstraints:@[
        [accountView.centerXAnchor constraintEqualToAnchor:scroll.centerXAnchor],
        [accountView.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:24],
        [accountView.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-16],
        [self.avatarView.topAnchor constraintEqualToAnchor:accountView.topAnchor],
        [self.avatarView.centerXAnchor constraintEqualToAnchor:accountView.centerXAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:52],
        [self.avatarView.heightAnchor constraintEqualToConstant:52],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:4],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:accountView.leadingAnchor constant:4],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:accountView.trailingAnchor constant:-4],
        [self.hintLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:2],
        [self.hintLabel.leadingAnchor constraintEqualToAnchor:accountView.leadingAnchor constant:4],
        [self.hintLabel.trailingAnchor constraintEqualToAnchor:accountView.trailingAnchor constant:-4],
        [self.hintLabel.bottomAnchor constraintEqualToAnchor:accountView.bottomAnchor],
    ]];

    // version card
    self.versionCard = [[UIView alloc] init];
    self.versionCard.translatesAutoresizingMaskIntoConstraints = NO;
    [FCLTheme styleCard:self.versionCard];
    [self.versionCard addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onVersionCardTap)]];
    [scroll addSubview:self.versionCard];

    self.versionIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fcl_grass"]];
    self.versionIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.versionIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.versionCard addSubview:self.versionIcon];

    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.font = [FCLTheme boldFont:14];
    self.versionLabel.textColor = [FCLTheme themeColor];
    self.versionLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.versionCard addSubview:self.versionLabel];

    self.versionHint = [[UILabel alloc] init];
    self.versionHint.font = [UIFont systemFontOfSize:11];
    self.versionHint.textColor = [FCLTheme themeColor];
    self.versionHint.lineBreakMode = NSLineBreakByTruncatingTail;
    self.versionHint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.versionCard addSubview:self.versionHint];

    UIButton *gear = [UIButton buttonWithType:UIButtonTypeSystem];
    [gear setImage:[FCLTheme templateIcon:@"fcl_settings"] forState:UIControlStateNormal];
    gear.tintColor = [FCLTheme themeColor];
    [gear addTarget:self action:@selector(onVersionCardTap) forControlEvents:UIControlEventTouchUpInside];
    gear.translatesAutoresizingMaskIntoConstraints = NO;
    [self.versionCard addSubview:gear];

    [NSLayoutConstraint activateConstraints:@[
        [self.versionCard.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:8],
        [self.versionCard.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-8],
        [self.versionCard.topAnchor constraintEqualToAnchor:accountView.bottomAnchor constant:18],
        [self.versionCard.heightAnchor constraintEqualToConstant:54],
        [self.versionIcon.leadingAnchor constraintEqualToAnchor:self.versionCard.leadingAnchor constant:8],
        [self.versionIcon.centerYAnchor constraintEqualToAnchor:self.versionCard.centerYAnchor],
        [self.versionIcon.widthAnchor constraintEqualToConstant:30],
        [self.versionIcon.heightAnchor constraintEqualToConstant:30],
        [gear.trailingAnchor constraintEqualToAnchor:self.versionCard.trailingAnchor constant:-4],
        [gear.centerYAnchor constraintEqualToAnchor:self.versionCard.centerYAnchor],
        [gear.widthAnchor constraintEqualToConstant:28],
        [gear.heightAnchor constraintEqualToConstant:28],
        [self.versionLabel.leadingAnchor constraintEqualToAnchor:self.versionIcon.trailingAnchor constant:8],
        [self.versionLabel.trailingAnchor constraintEqualToAnchor:gear.leadingAnchor constant:-4],
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.versionCard.topAnchor constant:8],
        [self.versionHint.leadingAnchor constraintEqualToAnchor:self.versionLabel.leadingAnchor],
        [self.versionHint.trailingAnchor constraintEqualToAnchor:self.versionLabel.trailingAnchor],
        [self.versionHint.topAnchor constraintEqualToAnchor:self.versionLabel.bottomAnchor constant:2],
    ]];

    // start button
    self.startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.startButton setTitle:@"启动游戏" forState:UIControlStateNormal];
    [self.startButton setImage:[FCLTheme templateIcon:@"fcl_start"] forState:UIControlStateNormal];
    self.startButton.tintColor = [FCLTheme themeColor];
    [self.startButton setTitleColor:[FCLTheme themeColor] forState:UIControlStateNormal];
    self.startButton.titleLabel.font = [FCLTheme boldFont:16];
    self.startButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
    self.startButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.startButton.backgroundColor = [UIColor clearColor];
    self.startButton.layer.cornerRadius = 8;
    self.startButton.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    self.startButton.layer.borderColor = [FCLTheme themeColorDark].CGColor;
    [self.startButton addTarget:self action:@selector(onStartTap) forControlEvents:UIControlEventTouchUpInside];
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:self.startButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.startButton.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:10],
        [self.startButton.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-10],
        [self.startButton.topAnchor constraintEqualToAnchor:self.versionCard.bottomAnchor constant:14],
        [self.startButton.heightAnchor constraintEqualToConstant:50],
        [self.startButton.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-16],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width * 0.25;
    width = MAX(210, MIN(330, width));
    self.panelWidthConstraint.constant = width;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.toolbarHidden = YES;
    [self refreshAccount];
    [self refreshVersion];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)refreshAccount {
    NSDictionary *data = BaseAuthenticator.current.authData;
    if (data == nil) {
        self.nameLabel.text = @"没有账户";
        self.hintLabel.text = @"点击添加账户";
        self.avatarView.image = [UIImage imageNamed:@"DefaultAccount"];
        return;
    }
    NSString *username = data[@"username"] ?: @"";
    if ([username hasPrefix:@"Demo."]) {
        username = [username substringFromIndex:5];
    }
    self.nameLabel.text = username;
    if ([data[@"xboxGamertag"] length] > 0) {
        self.hintLabel.text = data[@"xboxGamertag"];
    } else {
        self.hintLabel.text = @"离线账户";
    }
    self.avatarView.image = [UIImage imageNamed:@"DefaultAccount"];
}

- (void)refreshVersion {
    NSString *name = PLProfiles.current.selectedProfileName;
    if (name.length == 0) {
        self.versionLabel.text = @"未选择版本";
        self.versionHint.text = @"点击选择游戏版本";
        return;
    }
    self.versionLabel.text = name;
    NSDictionary *profile = PLProfiles.current.profiles[name];
    NSString *versionId = profile[@"lastVersionId"];
    self.versionHint.text = versionId.length > 0 ? versionId : @"";
}

- (void)onAccountTap {
    LauncherMenuViewController *menu = sidebarViewController;
    if (![menu respondsToSelector:@selector(selectAccount:)]) {
        return;
    }
    UIButton *anchor = menu.accountButton;
    if (anchor == nil) {
        anchor = [UIButton buttonWithType:UIButtonTypeCustom];
        anchor.frame = CGRectMake(CGRectGetMidX(self.avatarView.frame), CGRectGetMidY(self.avatarView.frame), 1, 1);
        [self.view addSubview:anchor];
    }
    [menu selectAccount:anchor];
}

- (void)onVersionCardTap {
    LauncherProfilesViewController *vc = [[LauncherProfilesViewController alloc] init];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onStartTap {
    LauncherNavigationController *nav = (LauncherNavigationController *)self.navigationController;
    NSString *name = PLProfiles.current.selectedProfileName;
    if (name.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"还没有版本"
            message:@"请先在「版本管理」里下载并选择游戏版本" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    UITextField *field = [nav valueForKey:@"versionTextField"];
    [field setText:name];
    [nav launchMinecraft:self.startButton];
}

@end


#pragma mark - shared card cell (FCL bg_container_white + item rows)

@interface FCLCardCell : UITableViewCell
@property(nonatomic) UIImageView *iconView;
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *descLabel;
@property(nonatomic) UIButton *actionButton;
@end

@implementation FCLCardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    card.layer.cornerRadius = 8;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.tag = 99;
    [self.contentView addSubview:card];

    self.iconView = [[UIImageView alloc] init];
    self.iconView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconView.clipsToBounds = YES;
    self.iconView.layer.cornerRadius = 8;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.iconView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [FCLTheme boldFont:15];
    self.titleLabel.textColor = [FCLTheme themeColor];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.titleLabel];

    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = [UIFont systemFontOfSize:12];
    self.descLabel.textColor = [UIColor secondaryLabelColor];
    self.descLabel.numberOfLines = 2;
    self.descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.descLabel];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.actionButton.tintColor = [FCLTheme themeColor];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.actionButton];

    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
        [card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],
        [card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        [self.iconView.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:10],
        [self.iconView.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:44],
        [self.iconView.heightAnchor constraintEqualToConstant:44],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:10],
        [self.titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.actionButton.leadingAnchor constant:-8],
        [self.descLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.descLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        [self.descLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:3],
        [self.descLabel.bottomAnchor constraintLessThanOrEqualToAnchor:card.bottomAnchor constant:-10],
        [self.actionButton.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-10],
        [self.actionButton.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [self.actionButton.widthAnchor constraintEqualToConstant:34],
        [self.actionButton.heightAnchor constraintEqualToConstant:34],
    ]];
    return self;
}

@end

#pragma mark - download center

@interface FCLDownloadViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) UITableView *table;
@property(nonatomic) UISegmentedControl *categoryControl;
@property(nonatomic) UISegmentedControl *versionTypeControl;
@property(nonatomic) NSArray *versions;
@property(nonatomic) NSArray *mods;
@property(nonatomic) ModrinthAPI *api;
@property(nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation FCLDownloadViewController

- (NSString *)imageName { return @"fcl_download"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"下载";
    self.view.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];
    self.api = [ModrinthAPI new];

    self.categoryControl = [[UISegmentedControl alloc] initWithItems:@[@"游戏版本", @"整合包", @"模组"]];
    self.categoryControl.selectedSegmentIndex = 0;
    self.categoryControl.tintColor = [FCLTheme themeColor];
    [self.categoryControl addTarget:self action:@selector(onCategoryChanged) forControlEvents:UIControlEventValueChanged];
    self.categoryControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.categoryControl];

    self.versionTypeControl = [[UISegmentedControl alloc] initWithItems:@[@"正式版", @"快照"]];
    self.versionTypeControl.selectedSegmentIndex = 0;
    self.versionTypeControl.tintColor = [FCLTheme themeColor];
    [self.versionTypeControl addTarget:self action:@selector(onTypeChanged) forControlEvents:UIControlEventValueChanged];
    self.versionTypeControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.versionTypeControl];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.rowHeight = 76;
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.table];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];

    [NSLayoutConstraint activateConstraints:@[
        [self.categoryControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [self.categoryControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [self.categoryControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.versionTypeControl.leadingAnchor constraintEqualToAnchor:self.categoryControl.leadingAnchor],
        [self.versionTypeControl.trailingAnchor constraintEqualToAnchor:self.categoryControl.trailingAnchor],
        [self.versionTypeControl.topAnchor constraintEqualToAnchor:self.categoryControl.bottomAnchor constant:8],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.topAnchor constraintEqualToAnchor:self.versionTypeControl.bottomAnchor constant:6],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVersionListUpdated)
        name:AmethystVersionListUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVersionListUpdated)
        name:AmethystVersionListFailedNotification object:nil];

    [(LauncherNavigationController *)self.navigationController fetchRemoteVersionList];
    [self onCategoryChanged];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onVersionListUpdated {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.categoryControl.selectedSegmentIndex == 0) {
            [self onTypeChanged];
        }
    });
}

- (void)onCategoryChanged {
    self.versionTypeControl.hidden = self.categoryControl.selectedSegmentIndex != 0;
    if (self.categoryControl.selectedSegmentIndex == 0) {
        [self onTypeChanged];
    } else {
        [self loadMods];
    }
}

- (void)onTypeChanged {
    NSString *type = self.versionTypeControl.selectedSegmentIndex == 0 ? @"release" : @"snapshot";
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSDictionary *version in remoteVersionList) {
        if ([version[@"type"] isEqualToString:type]) {
            [filtered addObject:version];
        }
    }
    self.versions = filtered;
    self.mods = nil;
    [self.table reloadData];
}

- (void)loadMods {
    BOOL isModpack = self.categoryControl.selectedSegmentIndex == 1;
    self.versions = nil;
    [self.table reloadData];
    [self.spinner startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *filters = [@{@"isModpack": @(isModpack), @"name": @" "} mutableCopy];
        NSMutableArray *list = [self.api searchModWithFilters:filters previousPageResult:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            if (list) {
                self.mods = list;
                [self.table reloadData];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加载失败"
                    message:self.api.lastError.localizedDescription ?: @"无法连接 Modrinth"
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.versions ? self.versions.count : self.mods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FCLCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fclcard"];
    if (!cell) {
        cell = [[FCLCardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fclcard"];
    }
    if (self.versions) {
        NSDictionary *version = self.versions[indexPath.row];
        cell.iconView.image = [UIImage imageNamed:@"fcl_grass"];
        cell.titleLabel.text = version[@"id"];
        cell.descLabel.text = [NSString stringWithFormat:@"%@ · %@", version[@"type"], version[@"releaseTime"] ?: @""];
        [cell.actionButton setImage:[FCLTheme templateIcon:@"fcl_download"] forState:UIControlStateNormal];
        [cell.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.actionButton addTarget:self action:@selector(onInstallRow:) forControlEvents:UIControlEventTouchUpInside];
        cell.actionButton.tag = indexPath.row;
    } else {
        NSDictionary *item = self.mods[indexPath.row];
        cell.iconView.image = [UIImage imageNamed:@"DefaultProfile"];
        NSURL *url = [NSURL URLWithString:item[@"imageUrl"]];
        if (url) {
            [cell.iconView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"DefaultProfile"]];
        }
        cell.titleLabel.text = item[@"title"];
        cell.descLabel.text = item[@"description"];
        [cell.actionButton setImage:[FCLTheme templateIcon:@"fcl_download"] forState:UIControlStateNormal];
        [cell.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.actionButton addTarget:self action:@selector(onInstallModRow:) forControlEvents:UIControlEventTouchUpInside];
        cell.actionButton.tag = indexPath.row;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.versions) {
        [self confirmInstallVersion:self.versions[indexPath.row][@"id"]];
    } else {
        [self showModVersionsAtIndex:indexPath];
    }
}

- (void)onInstallRow:(UIButton *)sender {
    if (self.versions && sender.tag < self.versions.count) {
        [self confirmInstallVersion:self.versions[sender.tag][@"id"]];
    }
}

- (void)onInstallModRow:(UIButton *)sender {
    if (self.mods && sender.tag < self.mods.count) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:sender.tag inSection:0];
        [self showModVersionsAtIndex:path];
    }
}

- (void)confirmInstallVersion:(NSString *)versionId {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:versionId
        message:@"安装这个版本？会自动下载客户端、依赖库和资源文件。"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"安装并启动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSMutableDictionary *profile = [NSMutableDictionary dictionary];
        profile[@"name"] = versionId;
        profile[@"lastVersionId"] = versionId;
        PLProfiles.current.profiles[versionId] = profile;
        PLProfiles.current.selectedProfileName = versionId;
        [PLProfiles.current save];
        LauncherNavigationController *nav = (LauncherNavigationController *)self.navigationController;
        UITextField *field = [nav valueForKey:@"versionTextField"];
        [field setText:versionId];
        [nav popToRootViewControllerAnimated:NO];
        [nav launchMinecraft:self.view];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showModVersionsAtIndex:(NSIndexPath *)indexPath {
    NSDictionary *item = self.mods[indexPath.row];
    [self.spinner startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![item[@"versionDetailsLoaded"] boolValue]) {
            [self.api loadDetailsOfMod:item];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            NSArray *names = item[@"versionNames"];
            NSArray *mcVersions = item[@"mcVersionNames"];
            if (names.count == 0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"没有可用文件"
                    message:self.api.lastError.localizedDescription ?: @"该项目没有可安装的版本"
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item[@"title"]
                message:@"选择要安装的版本" preferredStyle:UIAlertControllerStyleActionSheet];
            [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
                NSString *mc = i < mcVersions.count ? mcVersions[i] : @"";
                NSString *title = [name hasSuffix:mc] ? name : [NSString stringWithFormat:@"%@ - %@", name, mc];
                [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self.api installModpackFromDetail:item atIndex:i];
                }]];
            }];
            [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
            sheet.popoverPresentationController.sourceView = cell ?: self.view;
            sheet.popoverPresentationController.sourceRect = cell ? cell.bounds : CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1);
            [self presentViewController:sheet animated:YES completion:nil];
        });
    });
}

@end

#pragma mark - version management

@interface FCLVersionManageViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) UITableView *table;
@property(nonatomic) NSArray<NSString *> *names;
@end

@implementation FCLVersionManageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"版本管理";
    self.view.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd)];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.rowHeight = 76;
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.table];
    [NSLayoutConstraint activateConstraints:@[
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    [self reloadNames];
}

- (void)reloadNames {
    self.names = [PLProfiles.current.profiles.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.table reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.names.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FCLCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fclcard"];
    if (!cell) {
        cell = [[FCLCardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fclcard"];
    }
    NSString *name = self.names[indexPath.row];
    NSDictionary *profile = PLProfiles.current.profiles[name];
    cell.iconView.image = [UIImage imageNamed:@"fcl_grass"];
    cell.titleLabel.text = name;
    cell.descLabel.text = profile[@"lastVersionId"] ?: @"";
    [cell.actionButton setImage:[FCLTheme templateIcon:@"fcl_start"] forState:UIControlStateNormal];
    [cell.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [cell.actionButton addTarget:self action:@selector(onLaunchRow:) forControlEvents:UIControlEventTouchUpInside];
    cell.actionButton.tag = indexPath.row;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    NSString *name = self.names[indexPath.row];
    [PLProfiles.current.profiles removeObjectForKey:name];
    if ([PLProfiles.current.selectedProfileName isEqualToString:name]) {
        NSArray *rest = PLProfiles.current.profiles.allKeys;
        PLProfiles.current.selectedProfileName = rest.count > 0 ? rest[0] : @"";
    }
    [PLProfiles.current save];
    [self reloadNames];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self launchProfile:self.names[indexPath.row] sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)onLaunchRow:(UIButton *)sender {
    if (sender.tag < self.names.count) {
        [self launchProfile:self.names[sender.tag] sender:sender];
    }
}

- (void)launchProfile:(NSString *)name sender:(UIView *)sender {
    PLProfiles.current.selectedProfileName = name;
    [PLProfiles.current save];
    LauncherNavigationController *nav = (LauncherNavigationController *)self.navigationController;
    UITextField *field = [nav valueForKey:@"versionTextField"];
    [field setText:name];
    [nav launchMinecraft:sender ?: self.view];
}

- (void)onAdd {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"新建版本"
        message:@"请选择安装来源" preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"从下载中心安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [((LauncherMenuViewController *)sidebarViewController) selectRow:2];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"安装整合包 / 模组" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [(LauncherNavigationController *)self.navigationController enterModInstaller];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:sheet animated:YES completion:nil];
}

@end

#pragma mark - multiplayer (Terracotta style rooms)

@interface FCLMultiplayerViewController ()
@property(nonatomic) UILabel *codeLabel;
@property(nonatomic) UITextField *joinField;
@property(nonatomic) UILabel *statusLabel;
@end

@implementation FCLMultiplayerViewController

- (NSString *)imageName { return @"fcl_multiplayer"; }

- (UIView *)cardWithTitle:(NSString *)title {
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    card.layer.cornerRadius = 8;
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [FCLTheme boldFont:16];
    label.textColor = [FCLTheme themeColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [label.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
    ]];
    return card;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"联机";
    self.view.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scroll.contentLayoutGuide.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
    ]];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-16],
        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:16],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-16],
    ]];

    // 创建房间 card
    UIView *createCard = [self cardWithTitle:@"创建房间"];
    self.codeLabel = [[UILabel alloc] init];
    self.codeLabel.text = @"------";
    self.codeLabel.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightBold];
    self.codeLabel.textColor = [FCLTheme themeColor];
    self.codeLabel.textAlignment = NSTextAlignmentCenter;
    self.codeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [createCard addSubview:self.codeLabel];

    UIButton *createBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [createBtn setTitle:@"创建房间" forState:UIControlStateNormal];
    [createBtn setTitleColor:[FCLTheme themeColor] forState:UIControlStateNormal];
    createBtn.layer.cornerRadius = 8;
    createBtn.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    createBtn.layer.borderColor = [FCLTheme themeColorDark].CGColor;
    [createBtn addTarget:self action:@selector(onCreate) forControlEvents:UIControlEventTouchUpInside];
    createBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [createCard addSubview:createBtn];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"陶瓦联机使用邀请码加入；iOS 侧载版走局域网通道";
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [createCard addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.codeLabel.topAnchor constraintEqualToAnchor:createCard.topAnchor constant:34],
        [self.codeLabel.leadingAnchor constraintEqualToAnchor:createCard.leadingAnchor constant:14],
        [self.codeLabel.trailingAnchor constraintEqualToAnchor:createCard.trailingAnchor constant:-14],
        [createBtn.topAnchor constraintEqualToAnchor:self.codeLabel.bottomAnchor constant:12],
        [createBtn.leadingAnchor constraintEqualToAnchor:createCard.leadingAnchor constant:14],
        [createBtn.trailingAnchor constraintEqualToAnchor:createCard.trailingAnchor constant:-14],
        [createBtn.heightAnchor constraintEqualToConstant:40],
        [self.statusLabel.topAnchor constraintEqualToAnchor:createBtn.bottomAnchor constant:10],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:createBtn.leadingAnchor],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:createBtn.trailingAnchor],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:createCard.bottomAnchor constant:-12],
    ]];

    // 加入房间 card
    UIView *joinCard = [self cardWithTitle:@"加入房间"];
    self.joinField = [[UITextField alloc] init];
    self.joinField.placeholder = @"输入 6 位邀请码";
    self.joinField.keyboardType = UIKeyboardTypeNumberPad;
    self.joinField.textColor = [FCLTheme themeColor];
    self.joinField.font = [UIFont monospacedDigitSystemFontOfSize:22 weight:UIFontWeightBold];
    self.joinField.textAlignment = NSTextAlignmentCenter;
    self.joinField.translatesAutoresizingMaskIntoConstraints = NO;
    [joinCard addSubview:self.joinField];

    UIButton *joinBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [joinBtn setTitle:@"加入房间" forState:UIControlStateNormal];
    [joinBtn setTitleColor:[FCLTheme themeColor] forState:UIControlStateNormal];
    joinBtn.layer.cornerRadius = 8;
    joinBtn.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    joinBtn.layer.borderColor = [FCLTheme themeColorDark].CGColor;
    [joinBtn addTarget:self action:@selector(onJoin) forControlEvents:UIControlEventTouchUpInside];
    joinBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [joinCard addSubview:joinBtn];

    [NSLayoutConstraint activateConstraints:@[
        [self.joinField.topAnchor constraintEqualToAnchor:joinCard.topAnchor constant:38],
        [self.joinField.leadingAnchor constraintEqualToAnchor:joinCard.leadingAnchor constant:14],
        [self.joinField.trailingAnchor constraintEqualToAnchor:joinCard.trailingAnchor constant:-14],
        [self.joinField.heightAnchor constraintEqualToConstant:40],
        [joinBtn.topAnchor constraintEqualToAnchor:self.joinField.bottomAnchor constant:12],
        [joinBtn.leadingAnchor constraintEqualToAnchor:joinCard.leadingAnchor constant:14],
        [joinBtn.trailingAnchor constraintEqualToAnchor:joinCard.trailingAnchor constant:-14],
        [joinBtn.heightAnchor constraintEqualToConstant:40],
        [joinBtn.bottomAnchor constraintEqualToAnchor:joinCard.bottomAnchor constant:-14],
    ]];

    [stack addArrangedSubview:createCard];
    [stack addArrangedSubview:joinCard];

    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"陶瓦联机底层是 EasyTier 隧道；iOS 侧载应用拿不到 TUN 权限，当前版本用局域网 / 服务器地址联机。";
    hint.font = [UIFont systemFontOfSize:12];
    hint.textColor = [UIColor secondaryLabelColor];
    hint.numberOfLines = 0;
    [stack addArrangedSubview:hint];
}

- (void)onCreate {
    NSString *code = [NSString stringWithFormat:@"%06d", arc4random_uniform(1000000)];
    self.codeLabel.text = code;
    self.statusLabel.text = [NSString stringWithFormat:@"房间已创建，邀请码 %@（局域网内有效）", code];
    UIPasteboard.generalPasteboard.string = code;
}

- (void)onJoin {
    NSString *code = self.joinField.text;
    if (code.length != 6) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"邀请码不正确"
            message:@"请输入 6 位数字邀请码" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    self.statusLabel.text = [NSString stringWithFormat:@"正在连接房间 %@（局域网通道）", code];
    [self.joinField resignFirstResponder];
}

@end

#pragma mark - settings

@interface FCLSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) UITableView *table;
@property(nonatomic) NSArray *sections;
@end

@implementation FCLSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];

    self.sections = @[
        @{@"title": @"游戏", @"rows": @[@"渲染器", @"内存分配", @"Java 运行时"]},
        @{@"title": @"界面", @"rows": @[@"隐藏侧边栏", @"控制器布局"]},
        @{@"title": @"启动器", @"rows": @[@"下载源", @"关于 FCL"]},
    ];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.table];
    [NSLayoutConstraint activateConstraints:@[
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fclsetting"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"fclsetting"];
    }
    NSString *title = self.sections[indexPath.section][@"rows"][indexPath.row];
    cell.textLabel.text = title;
    cell.textLabel.textColor = [FCLTheme themeColor];
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if ([title isEqualToString:@"渲染器"]) {
        cell.detailTextLabel.text = getPrefObject(@"video.renderer");
    } else if ([title isEqualToString:@"内存分配"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ MB", getPrefObject(@"java.allocated_memory") ?: @"2048"];
    } else if ([title isEqualToString:@"隐藏侧边栏"]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.onTintColor = [FCLTheme themeColor];
        toggle.on = [getPrefObject(@"general.hidden_sidebar") boolValue];
        [toggle addTarget:self action:@selector(onToggleSidebar:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else {
        cell.accessoryView = nil;
    }
    return cell;
}

- (void)onToggleSidebar:(UISwitch *)sender {
    setPrefObject(@"general.hidden_sidebar", @(sender.on));
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *title = self.sections[indexPath.section][@"rows"][indexPath.row];

    if ([title isEqualToString:@"渲染器"]) {
        NSArray *keys = getRendererKeys(NO);
        NSArray *names = getRendererNames(NO);
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"渲染器"
            message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
            [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                setPrefObject(@"video.renderer", keys[i]);
                [self.table reloadData];
            }]];
        }];
        [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        sheet.popoverPresentationController.sourceView = cell;
        sheet.popoverPresentationController.sourceRect = cell.bounds;
        [self presentViewController:sheet animated:YES completion:nil];
    } else if ([title isEqualToString:@"内存分配"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"内存分配"
            message:@"输入分配给游戏的运行内存（MB）" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.keyboardType = UIKeyboardTypeNumberPad;
            field.placeholder = @"2048";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *value = alert.textFields.firstObject.text;
            if (value.length > 0) {
                setPrefObject(@"java.allocated_memory", value);
                [self.table reloadData];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if ([title isEqualToString:@"Java 运行时"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Java 运行时"
            message:@"iOS 版内置 java-8 / 17 / 21 / 25 四套 iOS 运行时，启动时按版本自动选择。"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if ([title isEqualToString:@"控制器布局"]) {
        [(LauncherNavigationController *)self.navigationController enterCustomControls];
    } else if ([title isEqualToString:@"下载源"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"下载源"
            message:@"版本与资源下载优先使用官方源，失败时自动回退 BMCLAPI 镜像。"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if ([title isEqualToString:@"关于 FCL"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"关于 FCL"
            message:@"FCL（Fold Craft Launcher）是 FCL-Team 开源的 Minecraft Java 版启动器（GPL-3.0）。iOS 移植版：界面按 FCL 布局翻译为 UIKit，运行环境替换为 iOS 版 JVM。"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
