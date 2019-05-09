//
//  LGStatusBarView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/29.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

/// 获取layoutMargins
///
/// - Returns: keywindow.rootViewController.view.layoutMargins
func LGStatusBarRootVCLayoutMargin() -> UIEdgeInsets {
    if let layoutMargins = UIApplication.shared.keyWindow?.rootViewController?.view.layoutMargins {
        if layoutMargins.top > 8 && layoutMargins.bottom > 8 {
            return layoutMargins
        }
    }
    return UIEdgeInsets.zero
}


open class LGStatusBarView: UIView {
    public private(set) lazy var textLabel: UILabel = {
        let temp = UILabel(frame: CGRect.zero)
        temp.backgroundColor = UIColor.clear
        temp.baselineAdjustment = UIBaselineAdjustment.alignCenters
        temp.textAlignment = NSTextAlignment.center
        temp.adjustsFontSizeToFitWidth = true
        temp.clipsToBounds = true
        temp.numberOfLines = 0
        temp.lineBreakMode = NSLineBreakMode.byWordWrapping
        return temp
    }()
    
    public private(set) lazy var activityIndicatorView: UIActivityIndicatorView = {
        let temp = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
        temp.hidesWhenStopped = true
        return temp
    }()
    
    public var textVerticalPositionAdjustment: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaultViews()
    }
    
    private func setupDefaultViews() {
        self.addSubview(textLabel)
        self.addSubview(activityIndicatorView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let topLayoutMargin = LGStatusBarRootVCLayoutMargin().top
        self.textLabel.frame = CGRect(x: 0,
                                      y: self.textVerticalPositionAdjustment + topLayoutMargin + 1.0,
                                      width: self.lg_width,
                                      height: self.lg_height - topLayoutMargin - 1.0)
        
        
        let textSize = self.textSize
        var indicatorFrame = self.activityIndicatorView.frame
        indicatorFrame.origin.x = round(self.lg_width - textSize.width / 2.0)
        indicatorFrame.origin.y = ceil(1.0 + (self.lg_height - indicatorFrame.height + topLayoutMargin) / 2.0)
        activityIndicatorView.frame = indicatorFrame
    }
    
    var textSize: CGSize {
        var textSize: CGSize = CGSize.zero
        if let text = self.textLabel.text, let font = self.textLabel.font {
            let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
            let constraintSize = CGSize(width: self.lg_width, height: CGFloat.greatestFiniteMagnitude)
            textSize = text.boundingRect(with: constraintSize,
                                         options: .usesLineFragmentOrigin,
                                         attributes: attributes,
                                         context: nil).size
        }
        return textSize
    }
    
    override open var frame: CGRect {
        didSet {
            println(frame)
        }
    }
}
