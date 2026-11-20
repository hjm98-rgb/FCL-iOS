#import <UIKit/UIKit.h>

// FCL (Fold Craft Launcher) UI kit: theme + home panel + download / multiplayer pages.
// Visual values are taken from the official FCL android resources
// (res/values/colors.xml, res/layout/activity_main.xml).

@interface FCLTheme : NSObject
+ (UIColor *)themeColor;      // #7797CF  default_theme_color
+ (UIColor *)themeColorDark;  // #4E77C1  default_theme_color_dark
+ (UIColor *)panelColor;       // #40F4F4F4 - translucent right menu panel
+ (UIColor *)cardPressedColor;
+ (UIFont *)boldFont:(CGFloat)size;
+ (UIImage *)templateIcon:(NSString *)name;
+ (void)styleCard:(UIView *)view;
@end

// Right side home panel: account, version card, launch button (FCL activity_main right_menu).
@interface FCLHomeViewController : UIViewController
@end

// "下载" page: FCL download center entry points.
@interface FCLDownloadViewController : UIViewController
@end

// "版本管理" page: FCL version manager.
@interface FCLVersionManageViewController : UIViewController
@end

// "设置" page: FCL settings list.
@interface FCLSettingsViewController : UIViewController
@end

// "联机" page: FCL multiplayer entry points.
@interface FCLMultiplayerViewController : UIViewController
@end
