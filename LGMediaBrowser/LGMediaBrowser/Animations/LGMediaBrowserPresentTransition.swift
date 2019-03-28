//
//  LGMediaBrowserPresentTransition.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/8.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation


public class LGMediaBrowserPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    public enum Direction {
        case present
        case dismiss
    }
    
    public var direction: Direction = .present
    public var targetView: UIView?
    public var finalImageSize: CGSize = CGSize.zero
    public var placeholderImage: UIImage?
    public weak var bottomBar: UIView?
    
    public init(direction: Direction, targetView: UIView?, finalImageSize: CGSize, placeholderImage: UIImage?) {
        super.init()
        self.direction = direction
        self.targetView = targetView
        self.finalImageSize = finalImageSize
        self.placeholderImage = placeholderImage
    }
    
    // MARK: -  UIViewControllerAnimatedTransitioning
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch self.direction {
        case .present:
            return 0.45
        case .dismiss:
            return 0.25
        }
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch self.direction {
        case .present:
            self.presentAnimation(using: transitionContext)
            break
        case .dismiss:
            self.dismissAnimation(using: transitionContext)
            break
        }
    }
    
    // MARK: - presentAnimation & dismissAnimation
    
    func presentAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else
        {
            assert(false, "fromVC or toVC is invalid")
            return
        }
        
        let containerView = transitionContext.containerView
        
        if let targetView = self.targetView {
            let image = self.placeholderImage
            let tempImageView = UIImageView(image: image)
            let tempBgView = UIView(frame: containerView.bounds)
            
            tempImageView.clipsToBounds = true
            tempImageView.contentMode = UIView.ContentMode.scaleAspectFill
            tempImageView.frame = targetView.convert(targetView.bounds, to: containerView)
            
            tempBgView.addSubview(tempImageView)
            containerView.addSubview(toVC.view)
            toVC.view.frame = containerView.bounds
            
            toVC.view.insertSubview(tempBgView, at: 0)
            if let temp = toVC as? LGMediaBrowser {
                temp.collectionView?.isHidden = true
            }
            
            let width: CGFloat = UIScreen.main.bounds.width
            let height: CGFloat = UIScreen.main.bounds.height
            
            let imageSize = self.calcFinalImageSize()
            let imageWidth = imageSize.width
            let imageHeight = imageSize.height
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0.0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0,
                           options: UIView.AnimationOptions.curveEaseInOut,
                           animations:
                {
                    tempImageView.frame = CGRect(x: (width - imageWidth) / 2.0,
                                                 y: (height - imageHeight) / 2.0,
                                                 width: imageWidth,
                                                 height: imageHeight)
            }) { (isFinished) in
                if let temp = toVC as? LGMediaBrowser {
                    temp.collectionView?.isHidden = false
                }
                let isCancelled = transitionContext.transitionWasCancelled
                tempImageView.removeFromSuperview()
                tempBgView.removeFromSuperview()
                transitionContext.completeTransition(!isCancelled)
            }
        } else {
            let fromView = fromVC.view
            let toView = toVC.view
            let duration = self.transitionDuration(using: transitionContext)
            containerView.insertSubview(toView!, aboveSubview: fromView!)
            let screenBounds = UIScreen.main.bounds
            let finalFrame = CGRect(x: 0,
                                    y: 0,
                                    width: screenBounds.width,
                                    height: screenBounds.height)
            toView?.frame = CGRect(x: 0,
                                   y: screenBounds.height,
                                   width: screenBounds.width,
                                   height: screenBounds.height)
            UIView.animate(withDuration: duration,
                           animations:
                {
                    toView?.frame = finalFrame
            }) { (isFinished) in
                let isCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!isCancelled)
            }
        }
    }
    
    func calcFinalImageSize() -> CGSize {
        if self.direction == .dismiss {
            return self.finalImageSize
        }
        if finalImageSize == CGSize.zero {
            return CGSize.zero
        }
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let imageWidth = finalImageSize.width
        var imageHeight = finalImageSize.height
        
        var resultWidth: CGFloat
        var resultHeight: CGFloat
        imageHeight = width / imageWidth * imageHeight
        if imageHeight > height {
            resultWidth = height / self.finalImageSize.height * imageWidth
            resultHeight = height
        } else {
            resultWidth = width
            resultHeight = imageHeight
        }
        return CGSize(width: resultWidth, height: resultHeight)
    }
    
    func dismissAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else
        {
            assert(false, "fromVC or toVC is invalid")
            return
        }
        
        let containerView = transitionContext.containerView
        
        if let targetView = self.targetView {
            let tempImageView = UIImageView(image: self.placeholderImage)
            tempImageView.clipsToBounds = true
            tempImageView.contentMode = UIView.ContentMode.scaleAspectFill
            
            let containerView = transitionContext.containerView
            tempImageView.frame = containerView.bounds
            containerView.addSubview(tempImageView)
            
            let rect = targetView.convert(targetView.bounds, to: containerView)
            targetView.isHidden = true
            fromVC.view.isHidden = true
            
            let width: CGFloat = UIScreen.main.bounds.width
            let height: CGFloat = UIScreen.main.bounds.height
            
            let imageSize = self.calcFinalImageSize()
            let imageWidth = imageSize.width
            let imageHeight = imageSize.height
            tempImageView.frame = CGRect(x: (width - imageWidth) / 2.0,
                                         y: (height - imageHeight) / 2.0,
                                         width: imageWidth,
                                         height: imageHeight)
            
            let isInteractive = transitionContext.isInteractive
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           animations:
                {
                    tempImageView.frame = rect
            }) { (finished) in
                let isCancelled = transitionContext.transitionWasCancelled
                targetView.isHidden = false
                tempImageView.removeFromSuperview()
                if isCancelled {
                    fromVC.view.isHidden = false
                    fromVC.view.backgroundColor = UIColor.black
                    
                } else {
                    
                }
                if !isInteractive {
                    transitionContext.completeTransition(!isCancelled)
                }
            }
        } else {
            let fromView = fromVC.view
            let toView = toVC.view
            let duration = self.transitionDuration(using: transitionContext)
            containerView.insertSubview(toView!, belowSubview: fromView!)
            let screenBounds = UIScreen.main.bounds
            let finalFrame = CGRect(x: 0,
                                   y: screenBounds.height,
                                   width: screenBounds.width,
                                   height: screenBounds.height)
            let isInteractive = transitionContext.isInteractive
            UIView.animate(withDuration: duration,
                           animations:
                {
                    fromView?.frame = finalFrame
            }) { (isFinished) in
                let isCancelled = transitionContext.transitionWasCancelled
                if !isInteractive {
                    transitionContext.completeTransition(!isCancelled)
                }
            }
        }
    }
}
