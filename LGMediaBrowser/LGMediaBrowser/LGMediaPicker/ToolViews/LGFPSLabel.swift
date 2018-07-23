//
//  LGFPSLabel.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public class LGFPSLabel: UILabel {

    var defaultSize: CGSize {
        return CGSize(width: 60.0, height: 20.0)
    }
    
    var timer: CADisplayLink!
    var count: Int = 0
    var lastTime: CFTimeInterval = 0.0
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupDefault()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefault()
    }
    
    func setupDefault() {
        self.layer.cornerRadius = 5.0
        self.layer.contentsScale = UIScreen.main.scale
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
        
        self.textAlignment = NSTextAlignment.center
        self.backgroundColor = UIColor.black
        
        timer = CADisplayLink(target: LGMPWeakTarget(target: self),
                              selector: #selector(timeInvoke(_:)))
        timer.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    var defaultFont: UIFont = UIFont.systemFont(ofSize: 14.0)
    
    @objc func timeInvoke(_ timer: CADisplayLink) {
        if lastTime == 0.0 {
            lastTime = timer.timestamp
            return
        }

        count += 1
        let delta = timer.timestamp - lastTime
        if delta < 1 { return }
        lastTime = timer.timestamp
        
        let fps = CFTimeInterval(count) / delta
        count = 0
        
        let progress = CGFloat(fps) / 60.0
        let color = UIColor(hue: 0.27 * (progress - 0.2), saturation: 1.0, brightness: 0.9, alpha: 1.0)

        let text = NSMutableAttributedString(string: String(format: "%d FPS", Int(round(fps))))
        text.addAttribute(NSAttributedString.Key.foregroundColor,
                          value: color,
                          range: NSMakeRange(0, text.length - 3))
        text.addAttribute(NSAttributedString.Key.foregroundColor,
                          value: UIColor.white,
                          range: NSMakeRange(text.length - 3, 3))
        text.addAttribute(NSAttributedString.Key.font,
                          value: defaultFont,
                          range: NSMakeRange(0, text.length))

        self.attributedText = text
    }
    
    deinit {
        timer.invalidate()
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return defaultSize
    }
}

class LGMPWeakTarget: NSObject {
    public weak var target: NSObjectProtocol?
    public init(target: NSObjectProtocol) {
        super.init()
        self.target = target
    }
    
    public override func responds(to aSelector: Selector!) -> Bool {
        return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}
