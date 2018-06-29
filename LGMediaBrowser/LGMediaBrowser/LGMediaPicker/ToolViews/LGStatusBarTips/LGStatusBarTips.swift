//
//  LGStatusBarTips.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/29.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public class LGStatusBarTips: NSObject {
    /// 存储当前显示的配置
    var activeConfig: LGStatusBarConfig?
    
    /// 默认配置
    var defaultConfig: LGStatusBarConfig = LGStatusBarConfig.config(withStyle: LGStatusBarConfig.Style.default)
    
    /// 预置的所有配置
    lazy var allConfigs: [LGStatusBarConfig.Style: LGStatusBarConfig] = {
        var temp = [LGStatusBarConfig.Style: LGStatusBarConfig]()
        for style in LGStatusBarConfig.Style.all {
            temp[style] = LGStatusBarConfig.config(withStyle: style)
        }
        return temp
    }()
    
    var overlayWindow: UIWindow!
    
    /// 覆盖状态栏的window
    lazy var defaultOverlayWindow: UIWindow = {
        let temp = UIWindow(frame: UIScreen.main.bounds)
        temp.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        temp.backgroundColor = UIColor.clear
        temp.isUserInteractionEnabled = false
        temp.windowLevel = UIWindowLevelStatusBar
        temp.rootViewController = LGStatusBarNotificationViewController()
        
        updateWindowTransform()
        updateTopBarFrame(withStatusBarFrame: UIApplication.shared.statusBarFrame)
        
        return temp
    }()
    
    /// 进度条视图
    var progressView: UIView!
    
    /// 进度条视图
    lazy var defaultProgressView: UIView = {
        return UIView(frame: CGRect.zero)
    }()
    
    var topBar: LGStatusBarView!
    
    /// 顶部显示的条
    lazy var defaultTopBar: LGStatusBarView = {
        let temp = LGStatusBarView(frame: CGRect.zero)
        self.overlayWindow.rootViewController?.view.addSubview(temp)
        
        let config = self.activeConfig ?? self.defaultConfig
        if config.animationType != .fade {
            temp.transform = CGAffineTransform(translationX: 0, y: -temp.lg_height)
        } else {
            temp.alpha = 0.0
        }
        return temp
    }()
    
    /// 进度数据
    var progress: CGFloat = 0.0  {
        didSet {
            progressDidSet()
        }
    }
    
    var dismissTimer: Timer?
    
    /// 更新window变换数据
    func updateWindowTransform() {
        if let window = UIApplication.shared.mainApplicationWindow(withIgnoringWindow: self.overlayWindow) {
            overlayWindow.transform = window.transform
            overlayWindow.frame = window.frame
        }
    }
    
    var navigationBarHeight: CGFloat {
        var naviBarHeight: CGFloat
        if (UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight) {
            naviBarHeight = 32.0
        } else {
            naviBarHeight = 44.0
        }
        return naviBarHeight
    }
    
    public var isVisible: Bool {
        return self.topBar != nil
    }
    
    /// 更新显示条的frame
    ///
    /// - Parameter frame: 状态栏frame
    func updateTopBarFrame(withStatusBarFrame frame: CGRect) {
        let width = max(frame.width, frame.height)
        var height = min(frame.width, frame.height)
        
        var yPos: CGFloat = 0.0
        if ProcessInfo().operatingSystemVersion.majorVersion >= 7 && height == 40.0 {
            yPos = -height / 2.0
        }
        
        let topLayoutMargin = LGStatusBarRootVCLayoutMargin().top
        if topLayoutMargin > 0 {
            height += topLayoutMargin
        }
        height += navigationBarHeight
        topBar.frame = CGRect(x: 0, y: yPos, width: width, height: height)
    }
    
    override public init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarFrame(_:)),
                                               name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame,
                                               object: nil)
    }
    
    public static var `default`: LGStatusBarTips = {
        return LGStatusBarTips()
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func willChangeStatusBarFrame(_ noti: Notification) {
        let newBarFrame = noti.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? CGRect ?? CGRect.zero
        let duration = UIApplication.shared.statusBarOrientationAnimationDuration
        
        func updateFrameAnimation() {
            updateWindowTransform()
            updateTopBarFrame(withStatusBarFrame: newBarFrame)
        }
        
        UIView.animate(withDuration: duration,
                       animations: {
                        updateFrameAnimation()
        }) { (isFinished) in
            updateFrameAnimation()
        }
    }
    
    // MARK: -  class method
//    public static func show(withStatus status: String) {
//        self.default.show
//    }
//
//    + (UIView*)showWithStatus:(NSString *)status;
//    {
//    return [[self sharedInstance] showWithStatus:status
//    styleName:nil];
//    }
//
//    + (UIView*)showWithStatus:(NSString *)status
//    styleName:(NSString*)styleName;
//    {
//    return [[self sharedInstance] showWithStatus:status
//    styleName:styleName];
//    }
//
//    + (UIView*)showWithStatus:(NSString *)status
//    dismissAfter:(NSTimeInterval)timeInterval;
//    {
//    UIView *view = [[self sharedInstance] showWithStatus:status
//    styleName:nil];
//    [self dismissAfter:timeInterval];
//    return view;
//    }
//
//    + (UIView*)showWithStatus:(NSString *)status
//    dismissAfter:(NSTimeInterval)timeInterval
//    styleName:(NSString*)styleName;
//    {
//    UIView *view = [[self sharedInstance] showWithStatus:status
//    styleName:styleName];
//    [self dismissAfter:timeInterval];
//    return view;
//    }
//
    
    @objc class func dismiss() {
        
    }
    
//    + (void)dismiss;
//    {
//    [self dismissAnimated:YES];
//    }
//
//    + (void)dismissAnimated:(BOOL)animated;
//    {
//    [[self sharedInstance] dismissAnimated:animated];
//    }
//
//    + (void)dismissAfter:(NSTimeInterval)delay;
//    {
//    [[self sharedInstance] setDismissTimerWithInterval:delay];
//    }
//
//    + (void)setDefaultStyle:(JDPrepareStyleBlock)prepareBlock;
//    {
//    NSAssert(prepareBlock != nil, @"No prepareBlock provided");
//
//    JDStatusBarStyle *style = [[self sharedInstance].defaultStyle copy];
//    [self sharedInstance].defaultStyle = prepareBlock(style);
//    }
//
//    + (NSString*)addStyleNamed:(NSString*)identifier
//    prepare:(JDPrepareStyleBlock)prepareBlock;
//    {
//    return [[self sharedInstance] addStyleNamed:identifier
//    prepare:prepareBlock];
//    }
//
//    + (void)showProgress:(CGFloat)progress;
//    {
//    [[self sharedInstance] setProgress:progress];
//    }
//
//    + (void)showActivityIndicator:(BOOL)show indicatorStyle:(UIActivityIndicatorViewStyle)style;
//    {
//    [[self sharedInstance] showActivityIndicator:show indicatorStyle:style];
//    }
    
    // MARK: -  instance method
    func show(withStatus status: String, style: LGStatusBarConfig.Style) -> UIView? {
        if UIApplication.shared.isStatusBarHidden { return nil }
        
        guard let config = self.allConfigs[style] else { return nil }
        
        if let activeConfig = self.activeConfig, config !== activeConfig {
            self.activeConfig = config
        }
        
        if config.animationType == .fade {
            self.topBar.alpha = 0.0
            self.topBar.transform = CGAffineTransform.identity
        } else {
            self.topBar.alpha = 1.0
            self.topBar.transform = CGAffineTransform(translationX: 0, y: -self.topBar.lg_height)
        }
        
        RunLoop.current.cancelPerform(#selector(LGStatusBarTips.dismiss), target: self, argument: nil)
        self.topBar.layer.removeAllAnimations()
        self.overlayWindow.isHidden = true
        
        topBar.backgroundColor = config.barColor
        topBar.textVerticalPositionAdjustment = config.textVerticalPositionAdjustment
        
        let textLabel = topBar.textLabel
        textLabel.textColor = config.textColor
        textLabel.font = config.font
        textLabel.accessibilityLabel = status
        textLabel.text = status
        
        if let shadow = config.textShadow {
            textLabel.shadowColor = shadow.shadowColor as? UIColor
            textLabel.shadowOffset = shadow.shadowOffset
        } else {
            textLabel.shadowColor = nil
            textLabel.shadowOffset = CGSize.zero
        }
        
        self.progress = 0.0
        self.setActivityIndicator(isShow: false, indicatorStyle: UIActivityIndicatorViewStyle.white)
        
        let isAnimationsEnabled = config.animationType != .none
        if isAnimationsEnabled && config.animationType == .bounce {
            
        } else {
            
        }
    }
//    - (UIView*)showWithStatus:(NSString *)status
//    styleName:(NSString*)styleName;
//    {
//    JDStatusBarStyle *style = nil;
//    if (styleName != nil) {
//    style = self.userStyles[styleName];
//    }
//
//    if (style == nil) style = self.defaultStyle;
//    return [self showWithStatus:status style:style];
//    }
    

//    // reset progress & activity
//    self.progress = 0.0;
//    [self showActivityIndicator:NO indicatorStyle:0];
//
//    // animate in
//    BOOL animationsEnabled = (style.animationType != JDStatusBarAnimationTypeNone);
//    if (animationsEnabled && style.animationType == JDStatusBarAnimationTypeBounce) {
//    [self animateInWithBounceAnimation];
//    } else {
//    [UIView animateWithDuration:(animationsEnabled ? 0.4 : 0.0) animations:^{
//    self.topBar.alpha = 1.0;
//    self.topBar.transform = CGAffineTransformIdentity;
//    }];
//    }
//
//    return self.topBar;
//    }
//
//    #pragma mark Dismissal
//
//    - (void)setDismissTimerWithInterval:(NSTimeInterval)interval;
//    {
//    [self.dismissTimer invalidate];
//    self.dismissTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]
//    interval:0 target:self selector:@selector(dismiss:) userInfo:nil repeats:NO];
//    [[NSRunLoop currentRunLoop] addTimer:self.dismissTimer forMode:NSRunLoopCommonModes];
//    }
//
//    - (void)dismiss:(NSTimer*)timer;
//    {
//    [self dismissAnimated:YES];
//    }
//
//    - (void)dismissAnimated:(BOOL)animated;
//    {
//    [self.dismissTimer invalidate];
//    self.dismissTimer = nil;
//
//    // check animation type
//    BOOL animationsEnabled = (self.activeStyle.animationType != JDStatusBarAnimationTypeNone);
//    animated &= animationsEnabled;
//
//    dispatch_block_t animation = ^{
//    if (self.activeStyle.animationType == JDStatusBarAnimationTypeFade) {
//    self.topBar.alpha = 0.0;
//    } else {
//    self.topBar.transform = CGAffineTransformMakeTranslation(0, -self.topBar.frame.size.height);
//    }
//    };
//
//    void(^complete)(BOOL) = ^(BOOL finished) {
//    [self.overlayWindow removeFromSuperview];
//    [self.overlayWindow setHidden:YES];
//    _overlayWindow.rootViewController = nil;
//    _overlayWindow = nil;
//    _progressView = nil;
//    _topBar = nil;
//    };
//
//    if (animated) {
//    // animate out
//    [UIView animateWithDuration:0.4 animations:animation completion:complete];
//    } else {
//    animation();
//    complete(YES);
//    }
//    }
//
//    #pragma mark Bounce Animation
    
    func animateInWithBounceAnimation() {
        if self.topBar.lg_originY >= 0 { return }
        
        // easing function (based on github.com/robb/RBBAnimation)
        func RBBEasingFunctionEaseOutBounce(value: CGFloat) -> CGFloat {
            if (value < 4.0 / 11.0) { return pow(11.0 / 4.0, 2) * pow(value, 2) }
            if (value < 8.0 / 11.0) { return 3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(value - 6.0 / 11.0, 2) }
            if (value < 10.0 / 11.0) { return 15.0 / 16.0 + pow(11.0 / 4.0, 2) * pow(value - 9.0 / 11.0, 2) }
            return 63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(value - 21.0 / 22.0, 2)
        }
        
        let fromCenterY: CGFloat = -20.0
        let toCenterY: CGFloat = 0.0
        let animationSteps: Int = 100
        var varlues: [CATransform3D] = [CATransform3D]()
        
        for index in 1...animationSteps {
            let easedTime = RBBEasingFunctionEaseOutBounce(value: CGFloat(index) / CGFloat(animationSteps))
            let easedValue = fromCenterY + easedTime * (toCenterY - fromCenterY)
            varlues.append(CATransform3DMakeTranslation(0.0, easedValue, 0.0))
        }
        
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.3
        animation.values = varlues
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.delegate = self
        self.topBar.layer.setValue(toCenterY, forKey: "transform")
        self.topBar.layer.add(animation, forKey: "LGBounceAnimation")
    }
//
//    #pragma mark Progress & Activity
//
    
    func progressDidSet() {
        if self.topBar == nil { return }
    }
    
//    - (void)setProgress:(CGFloat)progress;
//    {
//    if (_topBar == nil) return;
//
//    // trim progress
//    _progress = MIN(1.0, MAX(0.0,progress));
//
//    if (_progress == 0.0) {
//    _progressView.frame = CGRectZero;
//    return;
//    }
//
//    // update superview
//    if (self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionBelow ||
//    self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionNavBar) {
//    [self.topBar.superview addSubview:self.progressView];
//    } else {
//    [self.topBar insertSubview:self.progressView belowSubview:self.topBar.textLabel];
//    }
//
//    // calculate progressView frame
//    CGRect frame = self.topBar.bounds;
//    CGFloat height = MIN(frame.size.height,MAX(0.5, self.activeStyle.progressBarHeight));
//    if (height == 20.0 && frame.size.height > height) height = frame.size.height;
//    frame.size.height = height;
//    frame.size.width = round((frame.size.width - 2 * self.activeStyle.progressBarHorizontalInsets) * progress);
//    frame.origin.x = self.activeStyle.progressBarHorizontalInsets;
//
//    // apply y-position from active style
//    CGFloat barHeight = self.topBar.bounds.size.height;
//    if (self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionBottom) {
//    frame.origin.y = barHeight - height;
//    } else if(self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionCenter) {
//    frame.origin.y = round((barHeight - height)/2.0);
//    } else if(self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionTop) {
//    frame.origin.y = 0.0;
//    } else if(self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionBelow) {
//    frame.origin.y = barHeight;
//    } else if(self.activeStyle.progressBarPosition == JDStatusBarProgressBarPositionNavBar) {
//    CGFloat navBarHeight = 44.0;
//    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) &&
//    UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
//    navBarHeight = 32.0;
//    }
//    frame.origin.y = barHeight + navBarHeight;
//    }
//
//    // apply color from active style
//    self.progressView.backgroundColor = self.activeStyle.progressBarColor;
//
//    // apply corner radius
//    self.progressView.layer.cornerRadius = self.activeStyle.progressBarCornerRadius;
//
//    // update progressView frame
//    BOOL animated = !CGRectEqualToRect(self.progressView.frame, CGRectZero);
//    [UIView animateWithDuration:animated ? 0.05 : 0.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
//    self.progressView.frame = frame;
//    } completion:nil];
//    }
    
    func setActivityIndicator(isShow: Bool, indicatorStyle style: UIActivityIndicatorViewStyle) {
        if self.topBar == nil { return }
        if isShow {
            self.topBar.activityIndicatorView.startAnimating()
            self.topBar.activityIndicatorView.activityIndicatorViewStyle = style
        } else {
            self.topBar.activityIndicatorView.stopAnimating()
        }
    }
}

extension LGStatusBarTips: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.topBar.transform = CGAffineTransform.identity
        self.topBar.layer.removeAllAnimations()
    }
}

extension UIApplication {
    func mainApplicationWindow(withIgnoringWindow ignoringWindow: UIWindow?) -> UIWindow? {
        for window in UIApplication.shared.windows {
            if !window.isHidden && window != ignoringWindow {
                return window
            }
        }
        return nil
    }
}

class LGStatusBarNotificationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
    }
    
    var mainController: UIViewController? {
        if let mainWindow = UIApplication.shared.mainApplicationWindow(withIgnoringWindow: self.view.window) {
            var topViewController = mainWindow.rootViewController
            
            repeat {
                topViewController = topViewController?.presentedViewController
            } while topViewController?.presentedViewController != nil
            
            return topViewController
        }
        return nil
    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return mainController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return mainController?.preferredInterfaceOrientationForPresentation ??
            super.preferredInterfaceOrientationForPresentation
    }
    
    lazy var viewControllerBasedStatusBarAppearanceEnabled: Bool = {
        var isEnabled: Bool = false
        if let infoDic = Bundle.main.infoDictionary {
            if let temp = infoDic["UIViewControllerBasedStatusBarAppearance"] as? Bool {
                isEnabled = temp
            }
        }
        return isEnabled
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if viewControllerBasedStatusBarAppearanceEnabled {
            return mainController?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
        } else {
            return UIApplication.shared.statusBarStyle
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if viewControllerBasedStatusBarAppearanceEnabled {
            return mainController?.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
        } else {
            return super.preferredStatusBarUpdateAnimation
        }
    }
}
