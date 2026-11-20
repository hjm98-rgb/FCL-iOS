#import "FCLUI.h"
#import "LauncherPreferences.h"
#import "LauncherNavigationController.h"
#import "LauncherMenuViewController.h"
#import "LauncherProfilesViewController.h"
#import "PLProfiles.h"
#import "authenticator/BaseAuthenticator.h"

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

#pragma mark - download page

@interface FCLDownloadViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UISegmentedControl *typeControl;
@property(nonatomic) NSArray *versions;
@end

@implementation FCLDownloadViewController

- (NSString *)imageName { return @"fcl_download"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"下载";
    self.view.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];

    self.typeControl = [[UISegmentedControl alloc] initWithItems:@[@"正式版", @"快照"]];
    self.typeControl.selectedSegmentIndex = 0;
    [self.typeControl addTarget:self action:@selector(onTypeChanged) forControlEvents:UIControlEventValueChanged];
    self.typeControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.typeControl];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = 60;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.typeControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16],
        [self.typeControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
        [self.typeControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:self.typeControl.bottomAnchor constant:8],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onVersionListUpdated)
        name:AmethystVersionListUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onVersionListUpdated)
        name:AmethystVersionListFailedNotification object:nil];

    LauncherNavigationController *nav = (LauncherNavigationController *)self.navigationController;
    [nav fetchRemoteVersionList];
    [self onTypeChanged];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onVersionListUpdated {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onTypeChanged];
    });
}

- (void)onTypeChanged {
    NSString *type = self.typeControl.selectedSegmentIndex == 0 ? @"release" : @"snapshot";
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSDictionary *version in remoteVersionList) {
        if ([version[@"type"] isEqualToString:type]) {
            [filtered addObject:version];
        }
    }
    self.versions = filtered;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.versions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fclversion"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"fclversion"];
    }
    NSDictionary *version = self.versions[indexPath.row];
    cell.textLabel.text = version[@"id"];
    cell.textLabel.textColor = [FCLTheme themeColor];
    cell.textLabel.font = [FCLTheme boldFont:15];
    cell.detailTextLabel.text = version[@"releaseTime"] ?: version[@"type"];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.imageView.image = [UIImage imageNamed:@"fcl_grass"];
    cell.imageView.layer.magnificationFilter = kCAFilterNearest;
    cell.backgroundColor = [UIColor clearColor];
    UIView *bg = [[UIView alloc] init];
    bg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    cell.selectedBackgroundView = bg;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *version = self.versions[indexPath.row];
    NSString *versionId = version[@"id"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:versionId
        message:@"安装这个版本？安装时会自动下载补全客户端、依赖库和资源文件。"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"安装并启动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self installVersion:versionId];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)installVersion:(NSString *)versionId {
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
}

@end

#pragma mark - multiplayer page

@implementation FCLMultiplayerViewController

- (NSString *)imageName { return @"fcl_multiplayer"; }

- (UIView *)cardWithTitle:(NSString *)title desc:(NSString *)desc {
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    card.layer.cornerRadius = 8;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [FCLTheme boldFont:16];
    titleLabel.textColor = [FCLTheme themeColor];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:titleLabel];

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = desc;
    descLabel.font = [UIFont systemFontOfSize:13];
    descLabel.textColor = [UIColor secondaryLabelColor];
    descLabel.numberOfLines = 0;
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:descLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [titleLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [descLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [descLabel.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],
        [descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:6],
        [descLabel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
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

    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"FCL 的陶瓦联机底层依赖 TUN 虚拟网卡，iOS 侧载应用没有该权限，这里换成 iOS 上可用的联机方式。";
    hint.font = [UIFont systemFontOfSize:12];
    hint.textColor = [UIColor secondaryLabelColor];
    hint.numberOfLines = 0;
    [stack addArrangedSubview:hint];

    [stack addArrangedSubview:[self cardWithTitle:@"局域网联机"
        desc:@"和好友连同一个 WiFi，在游戏里对局域网开放，对方在「多人游戏」里会自动发现房间。"]];
    [stack addArrangedSubview:[self cardWithTitle:@"服务器联机"
        desc:@"进入游戏 → 多人游戏 → 添加服务器，填服务器地址和端口即可加入。"]];
    [stack addArrangedSubview:[self cardWithTitle:@"陶瓦联机"
        desc:@"保留 FCL 陶瓦联机的创建房间 / 邀请码逻辑，需要额外移植隧道组件，后续版本接入。"]];
}

@end
