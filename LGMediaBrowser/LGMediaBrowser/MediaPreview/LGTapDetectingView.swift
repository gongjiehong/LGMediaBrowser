//
//  LGTapDetectingView.swift
//  LGPhotoBrowser
//
//  Created by 龚杰洪 on 2018/4/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public protocol LGTapDetectingViewDelegate: NSObjectProtocol {
    func singleTapDetected(_ touch: UITouch, targetView: UIView)
    func doubleTapDetected(_ touch: UITouch, targetView: UIView)
}

open class LGTapDetectingView: UIView {
    public weak var detectingDelegate: LGTapDetectingViewDelegate?
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            switch touch.tapCount {
            case 1:
                detectingDelegate?.singleTapDetected(touch, targetView: self)
                break
            case 2:
                detectingDelegate?.doubleTapDetected(touch, targetView: self)
                break
            default:
                break
            }
        }
        self.next?.touchesEnded(touches, with: event)
    }
}
