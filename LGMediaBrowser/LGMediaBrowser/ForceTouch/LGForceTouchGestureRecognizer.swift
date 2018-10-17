//
//  LGForceTouchGestureRecognizer.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/// 自定义3Dtouch手势，如果设备不支持压力感应，则使用延迟0.2秒实现
class LGForceTouchGestureRecognizer: UIGestureRecognizer {
    /// <#Description#>
    var context: LGForceTouchPreviewingContext?
    
    /// <#Description#>
    let forceTouchManager: LGForceTouchManager
    
    /// <#Description#>
    let interpolationSpeed: CGFloat = 0.02
    
    /// <#Description#>
    let previewThreshold: CGFloat = 0.66
    
    /// <#Description#>
    let commitThreshold: CGFloat = 0.99
    
    /// <#Description#>
    var progress: CGFloat = 0.0
    
    /// <#Description#>
    var targetProgress: CGFloat = 0.0 {
        didSet {
            updateProgress()
        }
    }
    
    /// <#Description#>
    var initialMajorRadius: CGFloat = 0.0
    
    /// <#Description#>
    var timer: CADisplayLink?
    
    /// <#Description#>
    var forceTouchStarted = false
    
    /// 初始化
    ///
    /// - Parameter forceTouch: LGForceTouch对象
    init(forceTouch: LGForceTouch) {
        self.forceTouchManager = LGForceTouchManager(forceTouch: forceTouch)
        super.init(target: nil, action: nil)
    }
    
    // MARK: -  处理事件
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first, let context = context, isTouchValid(touch)
        {
            let touchLocation = touch.location(in: self.view)
            self.state = (context.delegate?.previewingContext(context, viewControllerForLocation: touchLocation) != nil) ? .possible : .failed
            if self.state == .possible {
                self.perform(#selector(delayedFirstTouch), with: touch, afterDelay: 0.2)
            }
        }
        else {
            self.state = .failed
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent)
    {
        super.touchesMoved(touches, with: event)
        if(self.state == .possible){
            self.cancelTouches()
        }
        if let touch = touches.first, forceTouchStarted == true
        {
            testForceChange(touch.majorRadius)
        }
    }
    
    @objc func delayedFirstTouch(_ touch: UITouch) {
        if isTouchValid(touch) {
            self.state = .began
            if let context = context {
                let touchLocation = touch.location(in: self.view)
                _ = forceTouchManager.forceTouchPossible(context, touchLocation: touchLocation)
            }
            forceTouchStarted = true
            initialMajorRadius = touch.majorRadius
            forceTouchManager.forceTouchBegan()
            targetProgress = previewThreshold
        }
    }
    
    func testForceChange(_ majorRadius: CGFloat) {
        if initialMajorRadius/majorRadius < 0.6  {
            targetProgress = 0.99
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent)
    {
        self.cancelTouches()
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.cancelTouches()
        super.touchesCancelled(touches, with: event)
    }
    
    func resetValues() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        forceTouchStarted = false
        progress = 0.0
    }
    
    fileprivate func cancelTouches() {
        self.state = .cancelled
        forceTouchStarted = false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if progress < commitThreshold {
            targetProgress = 0.0
        }
    }
    
    func isTouchValid(_ touch: UITouch) -> Bool {
        let sourceRect = context?.sourceView?.frame ?? CGRect.zero
        let touchLocation = touch.location(in: self.view?.superview)
        return sourceRect.contains(touchLocation)
    }
    
    func updateProgress() {
        timer?.invalidate()
        timer = CADisplayLink(target: LGMPWeakTarget(target: self),
                                    selector: #selector(animateToTargetProgress))
        timer?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    @objc func animateToTargetProgress() {
        if progress < targetProgress {
            progress = min(progress + interpolationSpeed, targetProgress)
            if progress >= targetProgress {
                timer?.invalidate()
            }
        }
        else {
            progress = max(progress - interpolationSpeed*2, targetProgress)
            if progress <= targetProgress {
                progress = 0.0
                timer?.invalidate()
                forceTouchManager.forceTouchEnded()
            }
        }
        forceTouchManager.animateProgressForContext(progress, context: context)
    }
}
