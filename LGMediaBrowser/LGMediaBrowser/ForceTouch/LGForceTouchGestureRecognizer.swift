//
//  LGForceTouchGestureRecognizer.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/// 自定义3Dtouch手势，如果设备不支持压力感应，则使用触摸点面积的变化加至少延迟0.2秒 来实现
class LGForceTouchGestureRecognizer: UIGestureRecognizer {
    /// 上下文存储，主要是回调和目标视图
    var context: LGForceTouchPreviewingContext?
    
    /// 管理器
    let forceTouchManager: LGForceTouchManager
    
    /// 补帧速度
    let interpolationSpeed: CGFloat = 0.02
    
    /// 触发prevew动作的阈值
    let previewThreshold: CGFloat = 0.66
    
    /// 触发commit动作的阈值
    let commitThreshold: CGFloat = 0.99
    
    /// 当前进度
    var progress: CGFloat = 0.0
    
    /// 目标进度
    var targetProgress: CGFloat = 0.0 {
        didSet {
            updateProgress()
        }
    }
    
    /// 初始触摸半径
    var initialMajorRadius: CGFloat = 0.0
    
    /// 定时器
    var timer: CADisplayLink?
    
    /// 动作是否开始
    var isForceTouchStarted = false
    
    
    /// 显示3Dtouch效果的controller
    private var previewController: UIViewController?
    
    /// 初始化
    ///
    /// - Parameter forceTouch: LGForceTouch对象
    init(forceTouch: LGForceTouch) {
        self.forceTouchManager = LGForceTouchManager(forceTouch: forceTouch)
        super.init(target: nil, action: nil)
    }
    
    // MARK: -  处理事件
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first, let context = context, isTouchValid(touch)
        {
            if let _ = context.delegate {
                self.state = .possible
                self.perform(#selector(delayedFirstTouch), with: touch, afterDelay: 0.2)
            } else {
                self.state = .failed
            }
        }
        else {
            self.state = .failed
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        if(self.state == .possible){
            self.cancelTouches()
        }
        
        if let touch = touches.first, isForceTouchStarted == true
        {
            testForceChange(touch.majorRadius)
        }
    }
    
    @objc func delayedFirstTouch(_ touch: UITouch) {
        if isTouchValid(touch) {
            self.state = .began
            if let context = context {
                let touchLocation = touch.location(in: self.view)
                let delegate = context.delegate
                if let previewController = delegate?.previewingContext(context,
                                                                       viewControllerForLocation: touchLocation)
                {
                    self.previewController = previewController
                } else {
                    cancelTouches()
                    return
                }
                
                _ = forceTouchManager.forceTouchPossible(context,
                                                         touchLocation: touchLocation,
                                                         targetViewController: self.previewController)
            }
            isForceTouchStarted = true
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
        isForceTouchStarted = false
        progress = 0.0
        previewController?.willMove(toParent: nil)
        previewController?.removeFromParent()
        previewController?.didMove(toParent: nil)
        previewController?.view.removeFromSuperview()
        previewController = nil
    }
    
    fileprivate func cancelTouches() {
        self.state = .cancelled
        isForceTouchStarted = false
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
