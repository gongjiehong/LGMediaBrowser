//
//  LGMediaBrowserInteractiveTransition.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/9.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

weak var panDismissGesture: UIPanGestureRecognizer?

public class LGMediaBrowserInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var isInteration: Bool = false
    public weak var targetController: UIViewController?
    private weak var transitionContext: UIViewControllerContextTransitioning?
    
    public weak var fromTargetView: UIView!
    public weak var toTargetView: UIView?
    public weak var targetImage: UIImage?
    private var transitionImageViewCenter: CGPoint = CGPoint.zero
    private var beginX: CGFloat = 0
    private var beginY: CGFloat = 0
    private var tempImageView: UIImageView?
    private var backgroundView: UIView?
    
    public init(fromTargetView: UIView, toTargetView: UIView?, targetController: UIViewController) {
        super.init()
        self.fromTargetView = fromTargetView
        self.toTargetView = toTargetView
        self.targetController = targetController
    }
    
    public override init() {
        super.init()
    }
    
    
    public func addPanGestureFor(viewController: UIViewController) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        viewController.view.addGestureRecognizer(pan)
        pan.lg_name = kPanDissmissGestureName
        panDismissGesture = pan
        self.targetController = viewController
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let gestureView = sender.view else {
            return
        }
        var scale: CGFloat = 0.0
        
        let translation = sender.translation(in: gestureView)
        let transitionY = translation.y
        scale = transitionY / ((gestureView.lg_height - 50.0) / 2.0)
        
        if scale > 1.0 {
            scale = 1.0
        }
        
        switch sender.state {
        case .began:
            if scale < 0 {
                return
            }
            let location = sender.location(in: sender.view)
            beginX = location.x
            beginY = location.y
            isInteration = true
            self.targetController?.dismiss(animated: true, completion: nil)
            break
        case .changed:
            if self.isInteration {
                if scale < 0.0 {
                    scale = 0.0
                }
                var imageViewScale = 1 - scale * 0.5
                if imageViewScale < 0.4 {
                    imageViewScale = 0.4
                }
                tempImageView?.center = CGPoint(x: self.transitionImageViewCenter.x + translation.x,
                                                   y: self.transitionImageViewCenter.y + translation.y)
                tempImageView?.transform = CGAffineTransform(scaleX: imageViewScale, y: imageViewScale)
                self.update(scale)
                self.updateInteractivePercent(1 - scale * scale)
            }
            break
        case .ended:
            if self.isInteration {
                if scale < 0.0 {
                    scale = 0.0
                }
                self.isInteration = false
                if abs(transitionY) < 100 {
                    self.cancel()
                    self.interactivePercentCancel()
                } else {
                    self.finish()
                    self.interactivePercentFinished()
                }
            }
            break
        default:
            if self.isInteration {
                self.isInteration = false
                self.cancel()
                self.interactivePercentCancel()
            }
            break
        }
    }
        
    func beginInteractivePercent() {
        guard let transitionContext = transitionContext else {
            assert(false, "transitionContext is invalid")
            return
        }
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else
        {
            assert(false, "fromVC or toVC is invalid")
            return
        }
        let containerView = transitionContext.containerView
        var tempImageViewFrame: CGRect = CGRect.zero
        
        
        
        tempImageViewFrame = fromTargetView.convert(fromTargetView.bounds, to: containerView)
        
        let imageView = UIImageView()
        tempImageView = imageView
        tempImageView?.layer.masksToBounds = true
        tempImageView?.clipsToBounds = true
        tempImageView?.contentMode = UIViewContentMode.scaleAspectFill
        
        tempImageView?.image = targetImage
        

        var contains = true
        
        let bgView = UIView(frame: containerView.bounds)
        bgView.backgroundColor = UIColor.white
        self.backgroundView = bgView
        
        var scaleX: CGFloat
        var scaleY: CGFloat
        if self.beginX < tempImageViewFrame.origin.x {
            scaleX = 0.0
        } else if self.beginX > tempImageViewFrame.maxX {
            scaleX = 1.0
        } else {
            scaleX = (self.beginX - tempImageViewFrame.origin.x) / tempImageViewFrame.size.width
        }
        
        if self.beginY < tempImageViewFrame.origin.y {
            scaleY = 0.0
        } else if self.beginY > tempImageViewFrame.maxY {
            scaleY = 1.0
        } else {
            scaleY = (self.beginY - tempImageViewFrame.origin.y) / tempImageViewFrame.size.height
        }
  
        self.tempImageView?.layer.anchorPoint = CGPoint(x: scaleX, y: scaleY)
        self.tempImageView?.frame = tempImageViewFrame
        self.transitionImageViewCenter = (self.tempImageView?.center)!
        containerView.addSubview(toVC.view)
        containerView.addSubview(fromVC.view)
        toVC.view.addSubview(self.backgroundView!)
        toVC.view.addSubview(self.tempImageView!)
        
        fromVC.view.backgroundColor = UIColor.clear
        if let toTargetView = self.toTargetView {
            let rect = toTargetView.convert(toTargetView.bounds, to: containerView)
        }
    }
    
    func updateInteractivePercent(_ scale: CGFloat) {
        guard let fromVC = transitionContext?.viewController(forKey: .from) else {
//            assert(false, "fromVC is invalid")
            return
        }
    
        fromVC.view.alpha = scale
        self.backgroundView?.alpha = scale
    }
    
    func interactivePercentCancel() {
        guard let transitionContext = transitionContext else {
            return
        }
        guard let fromVC = transitionContext.viewController(forKey: .from) else
        {
            assert(false, "fromVC or toVC is invalid")
            return
        }
        
        UIView.animate(withDuration: TimeInterval(duration),
                       animations:
            {
                fromVC.view.alpha = 1.0
                self.tempImageView?.transform = CGAffineTransform.identity
                self.tempImageView?.center = self.transitionImageViewCenter
                self.backgroundView?.alpha = 1.0
        }) { (isFinished) in
            self.tempImageView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.tempImageView?.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
            self.backgroundView = nil
            let isCanceled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!isCanceled)
        }
    }
    
    func interactivePercentFinished() {
        guard let transitionContext = transitionContext else {
            return
        }
        
        guard let fromVC = transitionContext.viewController(forKey: .from) else {
            return
        }
        
        let containerView = transitionContext.containerView
        
        let options = UIViewAnimationOptions.curveEaseOut
        let tempImageViewFrame = self.tempImageView?.frame ?? CGRect.zero
        self.tempImageView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.tempImageView?.transform = CGAffineTransform.identity
        self.tempImageView?.frame = tempImageViewFrame
        
        UIView.animate(withDuration: TimeInterval(duration),
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.1,
                       options: options,
                       animations:
            {
                if let toTargetView = self.toTargetView {
                    self.tempImageView?.frame = toTargetView.convert(toTargetView.bounds, to: containerView)
                } else {
                    self.tempImageView?.center = self.transitionImageViewCenter
                    self.tempImageView?.alpha = 0.0
                    self.tempImageView?.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                }
//                fromVC.view.alpha = 0.0
                self.backgroundView?.alpha = 0.0
        }) { (isFinished) in
            self.tempImageView?.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
            
            let isCanceled = transitionContext.transitionWasCancelled
            
//            transitionContext.completeTransition(!isCanceled)
        }

    }
    
    public override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
        self.transitionContext = transitionContext
        self.beginInteractivePercent()
    }
}