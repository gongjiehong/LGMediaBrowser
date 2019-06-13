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
    
    /// 覆盖状态栏的window
    lazy var overlayWindow: UIWindow = {
        let temp = UIWindow(frame: UIScreen.main.bounds)
        temp.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        temp.backgroundColor = UIColor.clear
        temp.isUserInteractionEnabled = false
        temp.windowLevel = UIWindow.Level.statusBar
        temp.rootViewController = LGStatusBarNotificationViewController()
        return temp
    }()
    
    /// 进度条视图
    lazy var progressView: UIView = {
        return UIView(frame: CGRect.zero)
    }()
    
    /// 顶部显示的条
    lazy var topBar: LGStatusBarView = {
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
    
    private var _progress: CGFloat = 0.0
    /// 进度数据
    var progress: CGFloat {
        set {
            setProgress(newValue)
        } get {
            return _progress
        }
    }
    
    /// dismiss当前显示的timer
    var dismissTimer: Timer?
    
    /// 更新window变换数据
    func updateWindowTransform() {
        if let window = UIApplication.shared.mainApplicationWindow(withIgnoringWindow: self.overlayWindow) {
            overlayWindow.transform = window.transform
            overlayWindow.frame = window.frame
        }
    }
    
    /// 导航条高度
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
    
    /// 初始化
    override public init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarFrame(_:)),
                                               name: UIApplication.willChangeStatusBarFrameNotification,
                                               object: nil)
    }
    
    /// 默认对象
    public static var `default`: LGStatusBarTips = {
        return LGStatusBarTips()
    }()
    
    // MARK: -  析构
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// 屏幕旋转时进行frame变换操作
    ///
    /// - Parameter noti: 状态栏高度改变的通知
    @objc func willChangeStatusBarFrame(_ noti: Notification) {
        let newBarFrame = noti.userInfo?[UIApplication.statusBarFrameUserInfoKey] as? CGRect ?? CGRect.zero
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
    @discardableResult
    public static func show(withStatus status: String,
                            style: LGStatusBarConfig.Style = .default,
                            dismissAfter delay: TimeInterval = 0.0)  -> UIView?
    {
        func displayDuration(forString string: String) -> TimeInterval {
            return max(TimeInterval(string.count) * 0.06 + 0.5, 2.5)
        }
        
        let view = self.default.show(withStatus: status, style: style)
        if delay == 0.0 {
            self.dismissAfter(displayDuration(forString: status))
        } else {
            self.dismissAfter(delay)
        }
        return view
    }
    
    @objc public class func dismiss() {
        self.dismiss(animated: true)
    }
    
    public class func dismiss(animated: Bool) {
        self.default.dismiss(animated: animated)
    }
    
    public class func dismissAfter(_ delay: TimeInterval) {
        self.default.setupDismissTimer(withInterval: delay)
    }
    
    
    public class func updateProgress(_ progress: CGFloat) {
        self.default.progress = progress
    }
    
    public class func setActivityIndicator(isShow: Bool, indicatorStyle style: UIActivityIndicatorView.Style) {
        self.default.setActivityIndicator(isShow: isShow, indicatorStyle: style)
    }
    
    
    func setupInitStatus() {
        self.overlayWindow.rootViewController?.view.addSubview(topBar)
        topBar.frame = CGRect.zero
        let config = self.activeConfig ?? self.defaultConfig
        if config.animationType != .fade {
            topBar.transform = CGAffineTransform(translationX: 0, y: -topBar.lg_height)
        } else {
            topBar.alpha = 0.0
        }
        
        updateWindowTransform()
        updateTopBarFrame(withStatusBarFrame: UIApplication.shared.statusBarFrame)
    }
    
    
    // MARK: -  instance method
    @discardableResult
    func show(withStatus status: String, style: LGStatusBarConfig.Style) -> UIView? {
        
        setupInitStatus()
        
        if UIApplication.shared.isStatusBarHidden { return nil }
        
        guard let config = self.allConfigs[style] else { return nil }
        
        if self.activeConfig !== config {
            self.activeConfig = config
        }
        
        if config.animationType == .fade {
            self.topBar.alpha = 0.0
            self.topBar.transform = CGAffineTransform.identity
        } else {
            self.topBar.alpha = 1.0
            self.topBar.transform = CGAffineTransform(translationX: 0, y: -self.topBar.lg_height)
        }
        
        RunLoop.current.cancelPerform(#selector(dismiss(timer:)), target: self, argument: nil)
        self.topBar.layer.removeAllAnimations()
        self.overlayWindow.isHidden = false
        
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
        self.setActivityIndicator(isShow: false, indicatorStyle: UIActivityIndicatorView.Style.white)
        
        let isAnimationsEnabled = config.animationType != .none
        if isAnimationsEnabled && config.animationType == .bounce {
            self.animateInWithBounceAnimation()
        } else {
            UIView.animate(withDuration: isAnimationsEnabled ? 0.2 : 0.0) {
                self.topBar.alpha = 1.0
                self.topBar.transform = CGAffineTransform.identity
            }
        }
        
        return self.topBar
    }
    
    func setupDismissTimer(withInterval interval: TimeInterval) {
        self.dismissTimer?.invalidate()
        self.dismissTimer = nil
        
        self.dismissTimer = Timer(fireAt: Date(timeIntervalSinceNow: interval),
                                  interval: 0,
                                  target: self,
                                  selector: #selector(dismiss(timer:)),
                                  userInfo: nil,
                                  repeats: false)
        RunLoop.current.add(self.dismissTimer!, forMode: RunLoop.Mode.common)
    }
    
    @objc func dismiss(timer: Timer) {
        self.dismiss(animated: true)
    }
    
    func dismiss(animated: Bool) {
        self.dismissTimer?.invalidate()
        self.dismissTimer = nil
        
        guard let config = self.activeConfig else { return }
        
        let animationsEnabled = config.animationType != .none
        
        func animation() {
            if config.animationType == .fade {
                self.topBar.alpha = 0.0
            } else {
                self.topBar.transform = CGAffineTransform(translationX: 0, y: -self.topBar.lg_height)
            }
        }
        
        
        func complete(_ isFinished: Bool) {
            self.overlayWindow.removeFromSuperview()
            self.overlayWindow.isHidden = true
            
            self.topBar.removeFromSuperview()
            
            self.progressView.removeFromSuperview()
        }
        
        if animationsEnabled && animated {
            UIView.animate(withDuration: 0.2,
                           animations: {
                            animation()
            }) { (isFinished) in
                complete(isFinished)
            }
        }
    }
    
    
    // MARK: -  bounce animation
    func animateInWithBounceAnimation() {
        if self.topBar.lg_originY >= 0 { return }
        
        // easing function (based on github.com/robb/RBBAnimation)
        func RBBEasingFunctionEaseOutBounce(value: CGFloat) -> CGFloat {
            if (value < 4.0 / 11.0) { return pow(11.0 / 4.0, 2) * pow(value, 2) }
            if (value < 8.0 / 11.0) { return 3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(value - 6.0 / 11.0, 2) }
            if (value < 10.0 / 11.0) { return 15.0 / 16.0 + pow(11.0 / 4.0, 2) * pow(value - 9.0 / 11.0, 2) }
            return 63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(value - 21.0 / 22.0, 2)
        }
        
        let fromCenterY: CGFloat = -topBar.lg_height / 2.0
        let toCenterY: CGFloat = 0.0
        let animationSteps: Int = 100
        var values: [CATransform3D] = [CATransform3D]()
        
        for index in 1...animationSteps {
            let easedTime = RBBEasingFunctionEaseOutBounce(value: CGFloat(index) / CGFloat(animationSteps))
            let easedValue = fromCenterY + easedTime * (toCenterY - fromCenterY)
            values.append(CATransform3DMakeTranslation(0.0, easedValue, 0.0))
        }
        
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.3
        animation.values = values
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.delegate = self
        self.topBar.layer.add(animation, forKey: "LGBounceAnimation")
    }
    
    
    // MARK: - set progress value
    func setProgress(_ newValue: CGFloat) {
        _progress = newValue
        
        if newValue > 1.0 { _progress = 1.0 }
        if newValue == 0.0 {
            progressView.frame = CGRect.zero
            return
        }
        
        guard let config = self.activeConfig else { return }
        switch config.progressBarPosition {
        case .below:
            self.topBar.superview?.addSubview(progressView)
            break
        default:
            self.topBar.insertSubview(progressView, belowSubview: self.topBar.textLabel)
            break
        }
        
        var frame = self.topBar.bounds
        var height = min(frame.height, max(0.5, config.progressBarHeight))
        if height == 20.0 && frame.height > height {
            height = frame.height
        }
        frame.size.height = height
        frame.size.width = round((frame.width - 2.0 * config.progressBarHorizontalInsets) * progress)
        frame.origin.x = config.progressBarHorizontalInsets
        
        let barHeight = self.topBar.lg_height
        switch config.progressBarPosition {
        case .top:
            frame.origin.y = 0.0
            break
        case .center:
            frame.origin.y = (barHeight - height) / 2.0
            break
        case .bottom:
            frame.origin.y = barHeight - height
            break
        case .below:
            frame.origin.y = barHeight
            break
        }
        
        progressView.backgroundColor = config.progressBarColor
        
        progressView.layer.cornerRadius = config.progressBarCornerRadius
        
        let animated = self.progressView.frame.equalTo(CGRect.zero)
        UIView.animate(withDuration: animated ? 0.05 : 0.0,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveLinear,
                       animations: {
                        self.progressView.frame = frame
        }) { (isFinished) in
            
        }
    }
    
    func setActivityIndicator(isShow: Bool, indicatorStyle style: UIActivityIndicatorView.Style) {
        if isShow {
            self.topBar.activityIndicatorView.startAnimating()
            self.topBar.activityIndicatorView.style = style
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
