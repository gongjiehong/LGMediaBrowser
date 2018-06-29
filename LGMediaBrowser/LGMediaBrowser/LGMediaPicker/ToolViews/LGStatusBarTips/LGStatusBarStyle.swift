//
//  LGStatusBarStyle.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/29.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

open class LGStatusBarConfig {
    /// 预置状态条风格
    public struct Style: OptionSet, Hashable {
        public typealias RawValue = Int
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static var error: Style = Style(rawValue: 1 << 0)
        public static var warning: Style = Style(rawValue: 1 << 1)
        public static var success: Style = Style(rawValue: 1 << 2)
        public static var matrix: Style = Style(rawValue: 1 << 3)
        public static var dark: Style = Style(rawValue: 1 << 4)
        public static var `default`: Style = Style(rawValue: 1 << 5)
        
        public var hashValue: Int {
            return self.rawValue
        }
        
        public static var all: [Style] = [.error, .warning, .success, .matrix, .dark]
    }
    
    /// 状态条提示的出现动画
    ///
    /// - none: 无动画
    /// - move: 从顶部移入，结束后从顶部移出
    /// - bounce: 掉下并弹跳一小段距离
    /// - fade: 淡入淡出
    public enum AnimationType {
        case none
        case move
        case bounce
        case fade
    }
    
    /// 进度条的展示位置
    ///
    /// - top: 顶部
    /// - center: 中间
    /// - bottom: 底部
    /// - below: 在进度条下面显示
    public enum ProgressBarPosition {
        case top
        case center
        case bottom
        case below
    }

    
    /// 显示条的背景色
    public var barColor: UIColor
    
    /// 显示的文字颜色
    public var textColor: UIColor
    
    /// 文字阴影颜色
    public var textShadow: NSShadow?

    /// 显示的文字字体
    public var font: UIFont
    
    /// label 的垂直位置修正，默认0，不修正
    public var textVerticalPositionAdjustment: CGFloat = 0.0
    
    // MARK: Animation
    
    /// 动画类型，默认none，无动画
    public var animationType = AnimationType.none
    
    // MARK: Progress Bar
    
    /// 进度条颜色
    public var progressBarColor: UIColor
    
    /// 进度条高度
    public var progressBarHeight: CGFloat = 0.0
    
    /// 进度条显示位置，默认bottom
    public var progressBarPosition = ProgressBarPosition.bottom
    
    /// 进度条水平Insets，默认0.0
    public var progressBarHorizontalInsets: CGFloat = 0.0
    
    /// 进度条圆角，默认0
    public var progressBarCornerRadius: CGFloat = 0.0
    
    // MARK: -  初始化
    public init() {
        self.barColor = UIColor.white
        self.progressBarColor = UIColor.green
        self.progressBarHeight = 2.0
        self.textColor = UIColor.gray
        self.font = UIFont.systemFont(ofSize: 14.0)
    }
        
    /// 根据Style获取Config
    ///
    /// - Parameter style: 状态条风格定义
    /// - Returns: 组装好的config
    open static func config(withStyle style: Style = .default) -> LGStatusBarConfig {
        let config = LGStatusBarConfig()
        switch style {
        case .default:
            break
        case .error:
            config.barColor = UIColor(hexColor: "E56060")
            config.textColor = UIColor(hexColor: "FFFFFF")
            config.progressBarColor = UIColor(hexColor: "FFFFFF")
            config.progressBarHeight = 2.0
            break
        case .success:
            config.barColor = UIColor(hexColor: "3ACB6E")
            config.textColor = UIColor(hexColor: "FFFFFF")
            config.progressBarColor = UIColor(hexColor: "FFFFFF")
            config.progressBarHeight = 2.0
            break
        case .warning:
            config.barColor = UIColor(hexColor: "FFFF00")
            config.textColor = UIColor(hexColor: "FFFFFF")
            config.progressBarColor = UIColor(hexColor: "FFFFFF")
            config.progressBarHeight = 2.0
            break
        case .matrix:
            config.barColor = UIColor(hexColor: "000000")
            config.textColor = UIColor.green
            config.progressBarHeight = 2.0
            break
        case .dark:
            config.barColor = UIColor(hexColor: "7A141F")
            config.textColor = UIColor(hexColor: "FFFFFFF2")
            config.progressBarHeight = 2.0
            break
        default:
            break
        }
        return config
    }
}
