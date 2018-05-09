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
    
    var direction: Direction = .present
    var targetView: UIView?
    var finalImageSize: CGSize = CGSize.zero
    var placeholderImage: UIImage?
    
    public init(direction: Direction, targetView: UIView?, finalImageSize: CGSize, placeholderImage: UIImage) {
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
        guard let targetView = self.targetView else {
            assert(false, "targetView can not be nil")
        }
        
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            assert(false, "toVC is invalid")
        }
        
        let containerView = transitionContext.containerView
        let image = self.placeholderImage
        let tempImageView = UIImageView(image: image)
        let tempBgView = UIView(frame: containerView.bounds)
        
        tempImageView.clipsToBounds = true
        tempImageView.contentMode = UIViewContentMode.scaleAspectFill
        tempImageView.frame = targetView.convert(targetView.bounds, to: containerView)
        
        tempBgView.addSubview(tempImageView)
        containerView.addSubview(toVC.view)
        toVC.view.frame = containerView.bounds
        
        toVC.view.insertSubview(tempBgView, at: 0)
        if let temp = toVC as? LGMediaBrowser {
            temp.collectionView?.isHidden = true
        }
        
        let width: CGFloat = UIScreen.main.bounds.width
        let height: CGFloat = UIScreen.main.bounds.height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin
        
        let imageWidth = self.calcfinalImageSize().width
        let imageHeight = self.calcfinalImageSize().height
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0,
                       options: UIViewAnimationOptions.curveEaseInOut,
                       animations:
            {
                
            tempImageView.frame = CGRect(x: (width - imageWidth) / 2.0,
                                         y: (height - imageHeight) / 2.0 + UIDevice.topSafeMargin,
                                         width: imageWidth,
                                         height: imageHeight)
        }) { (isFinished) in
            if let temp = toVC as? LGMediaBrowser {
                temp.collectionView?.isHidden = false
            }
            let isCanceled = transitionContext.transitionWasCancelled
            tempImageView.removeFromSuperview()
            tempBgView.removeFromSuperview()
            transitionContext.completeTransition(!isCanceled)
        }
    }
    
    func calcfinalImageSize() -> CGSize {
        let kNavigationBarHeight: CGFloat = UIDevice.deviceIsiPhoneX ? 88.0 : 64.0
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height - kNavigationBarHeight
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
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            assert(false, "fromVC or toVC is invalid")
        }
        
        let tempImageView = UIImageView(image: self.placeholderImage)
        tempImageView.clipsToBounds = true
        tempImageView.contentMode = UIViewContentMode.scaleAspectFill
        
        let containerView = transitionContext.containerView
        tempImageView.frame = containerView.bounds
        containerView.addSubview(tempImageView)
        
        tempImageView.lg_size = calcfinalImageSize()
        
        guard let targetView = self.targetView else {
            assert(false, "targetView can not be nil")
        }
        
        let rect = targetView.convert(targetView.bounds, to: containerView)
        targetView.isHidden = true
        fromVC.view.isHidden = true
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations:
            {
                tempImageView.frame = rect
        }) { (finished) in
            let isCanceled = transitionContext.transitionWasCancelled
            targetView.isHidden = false
            tempImageView.removeFromSuperview()
            transitionContext.completeTransition(!isCanceled)
        }
    }
    
    
}
