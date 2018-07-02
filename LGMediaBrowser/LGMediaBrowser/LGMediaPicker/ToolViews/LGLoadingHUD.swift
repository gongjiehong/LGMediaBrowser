//
//  LGLoadingHUD.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/25.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public class LGLoadingHUD: UIView {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        createSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createSubViews()
    }
    
    private weak var centerBgView: UIView!
    
    public func createSubViews() {
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = false
        
        let centerBgViewSize = CGSize(width: 120.0, height: 120.0)
        let centerBgView = UIView(frame: CGRect(origin: CGPoint.zero, size: centerBgViewSize))
        centerBgView.layer.cornerRadius = 5.0
        centerBgView.layer.masksToBounds = true
        centerBgView.backgroundColor = UIColor(colorName: "HUDBackground")
        self.addSubview(centerBgView)
        self.centerBgView = centerBgView
        
        
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        indicatorView.frame = CGRect(x: 40, y: 30, width: 40, height: 40)
        centerBgView.addSubview(indicatorView)
        indicatorView.startAnimating()
        
        let loadingLabel = UILabel()
        loadingLabel.textAlignment = NSTextAlignment.center
        loadingLabel.textColor = UIColor(colorName: "HUDLoadingText")
        loadingLabel.font = UIFont.systemFont(ofSize: 12.0)
        loadingLabel.text = LGLocalizedString("Loading...")
        loadingLabel.frame = CGRect(x: 0,
                                    y: indicatorView.frame.maxY + 20,
                                    width: centerBgViewSize.width,
                                    height: 20.0)
        centerBgView.addSubview(loadingLabel)
    }
    
    @discardableResult
    public static func show(inView targetView: UIView? = nil) -> LGLoadingHUD {
        var frame = UIScreen.main.bounds
        var realTargetView: UIView?
        if let targetView = targetView {
            frame = targetView.bounds
            realTargetView = targetView
        } else {
            if let window = UIApplication.shared.keyWindow {
                frame = window.frame
                realTargetView = window
            }
        }
        let temp = LGLoadingHUD(frame: frame)
        DispatchQueue.main.async {
            guard let realTargetView = realTargetView else { return }
            realTargetView.addSubview(temp)
            temp.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            temp.alpha = 0.6
            UIView.animate(withDuration: 0.2,
                           animations: {
                            temp.transform = CGAffineTransform.identity
                            temp.alpha = 1.0
            })
        }
        return temp
    }
    
    public func show(inView targetView: UIView? = nil) {
        var realTargetView = targetView
        if realTargetView == nil {
            realTargetView = UIApplication.shared.keyWindow
        }
        DispatchQueue.main.async {
            guard let realTargetView = realTargetView else { return }
            realTargetView.addSubview(self)
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.transform = CGAffineTransform.identity
            })
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.centerBgView.center = self.center
    }
    
    public func dismiss() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                            self.alpha = 0.0
            }, completion: { (isFinished) in
                self.removeFromSuperview()
            })
        }
    }
}
