//
//  LGMPPreviewTransition.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/7/5.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

open class LGMPPreviewTransition: NSObject {
    public enum Direction {
        case push
        case pop
    }
    
    public var targetView: UIView?
    public var finalImageSize: CGSize = CGSize.zero
    public var placeholderImage: UIImage?
    public private(set) var direction: Direction
    public weak var bottomBar: UIView?
    
    public init(withDirection direction: Direction) {
        self.direction = direction
    }
}

extension LGMPPreviewTransition: UIViewControllerAnimatedTransitioning {
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch self.direction {
        case .push:
            pushAnimation(using: transitionContext)
            break
        case .pop:
            popAnimation(using: transitionContext)
            break
        }
    }
    
    func pushAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {return}
        
        if self.placeholderImage == nil {
            self.placeholderImage = UIImage(color: UIColor(colorName: "DefaultImage"),
                                            size: CGSize(width: UIScreen.main.bounds.width * 0.3,
                                                         height: UIScreen.main.bounds.width * 0.3))
        }
        
        let containerView = transitionContext.containerView
        
        self.finalImageSize = placeholderImage?.size ?? CGSize.zero
        let imageSize = calcfinalImageSize()
        let finalWidth = UIScreen.main.bounds.width
        var finalHeight = UIScreen.main.bounds.height - UIDevice.topSafeMargin - UIDevice.bottomSafeMargin
        
        let orientation = UIApplication.shared.statusBarOrientation
        if orientation == .landscapeRight || orientation == .landscapeLeft {
            if UIDevice.isNotchScreen {
                finalHeight = UIScreen.main.bounds.height - UIDevice.topSafeMargin - 21.0
            }
        }
        
        let tempImageView = UIImageView(image: placeholderImage)
        tempImageView.clipsToBounds = true
        tempImageView.contentMode = UIView.ContentMode.scaleAspectFill
        
        let tempBackgroundView = UIView(frame: containerView.bounds)
        tempBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        if let targetView = self.targetView {
            tempImageView.frame = targetView.convert(targetView.bounds, to: containerView)
        } else {
            tempImageView.center = CGPoint(x: finalWidth / 2.0, y: finalHeight / 2.0)
        }
        
        tempBackgroundView.addSubview(tempImageView)
        
        fromVC.view.addSubview(tempBackgroundView)
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        
        var bottomBarView: UIView = UIView()
        if let bottomBar = self.bottomBar, let copy = bottomBar.copy() as? UIView {
            bottomBarView = copy
            containerView.addSubview(bottomBarView)
            bottomBarView.alpha = 0.0
            
            bottomBarView.translatesAutoresizingMaskIntoConstraints = false
            bottomBarView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            bottomBarView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            if #available(iOS 11.0, *) {
                let safeBottomAnchor = containerView.safeAreaLayoutGuide.bottomAnchor
                bottomBarView.bottomAnchor.constraint(equalTo: safeBottomAnchor).isActive = true
            } else {
                bottomBarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
            }
            bottomBarView.heightAnchor.constraint(equalToConstant: 44.0 + UIDevice.bottomSafeMargin)
        }
        
        toVC.view.alpha = 0.0
        
        
        if let navigationBar = toVC.navigationController?.navigationBar {
            navigationBar.isUserInteractionEnabled = false
        }
        
        let options = UIView.AnimationOptions.curveEaseOut
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.0,
                       options: options,
                       animations:
            {
                tempImageView.frame = CGRect(origin: CGPoint(x: (finalWidth - imageSize.width) / 2.0,
                                                             y: (finalHeight - imageSize.height) / 2.0),
                                             size: imageSize)
                tempBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(1.0)
                bottomBarView.alpha = 1.0
        }) { (isFinished) in
            toVC.view.alpha = 1.0
            tempBackgroundView.removeFromSuperview()
            tempImageView.removeFromSuperview()
            if let navigationBar = toVC.navigationController?.navigationBar {
                navigationBar.isUserInteractionEnabled = true
            }
            bottomBarView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
    
    func popAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {return}
        
        if self.placeholderImage == nil {
            self.placeholderImage = UIImage(color: UIColor(colorName: "DefaultImage"),
                                            size: CGSize(width: UIScreen.main.bounds.width * 0.3,
                                                         height: UIScreen.main.bounds.width * 0.3))
        }
        
        let containerView = transitionContext.containerView
        
        let tempImageView = UIImageView(image: self.placeholderImage)
        tempImageView.clipsToBounds = true
        tempImageView.contentMode = UIView.ContentMode.scaleAspectFill
        
        let tempBackgroundView = UIView(frame: containerView.bounds)
        tempBackgroundView.addSubview(tempImageView)
        
        containerView.addSubview(toVC.view)
        containerView.addSubview(fromVC.view)
        
        var bottomBarView: UIView = UIView()
        if let bottomBar = self.bottomBar, let copy = bottomBar.copy() as? UIView {
            bottomBarView = copy
            containerView.addSubview(bottomBarView)
            bottomBarView.alpha = 1.0
            
            bottomBarView.translatesAutoresizingMaskIntoConstraints = false
            bottomBarView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            bottomBarView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            if #available(iOS 11.0, *) {
                let safeBottomAnchor = containerView.safeAreaLayoutGuide.bottomAnchor
                bottomBarView.bottomAnchor.constraint(equalTo: safeBottomAnchor).isActive = true
            } else {
                bottomBarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
            }
            bottomBarView.heightAnchor.constraint(equalToConstant: 44.0 + UIDevice.bottomSafeMargin)
        }
        
        fromVC.view.isHidden = true
        
        if transitionContext.isInteractive {
            tempBackgroundView.backgroundColor = UIColor.black
            if let navigationController = toVC.navigationController {
            }
            containerView.insertSubview(tempBackgroundView, belowSubview: fromVC.view)
        } else {
            toVC.view.addSubview(tempBackgroundView)
            tempBackgroundView.backgroundColor = UIColor.black
        }
        
        if let navigationBar = toVC.navigationController?.navigationBar {
            navigationBar.isUserInteractionEnabled = false
        }
        targetView?.isHidden = true
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        tempImageView.frame = CGRect(x: (screenWidth - finalImageSize.width) / 2.0,
                                     y: (screenHeight - finalImageSize.height) / 2.0,
                                     width: finalImageSize.width,
                                     height: finalImageSize.height)
        
        let options = UIView.AnimationOptions.curveEaseOut
        
        let isInteractive = transitionContext.isInteractive
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.1,
                       options: options,
                       animations:
            {
                if let targetView = self.targetView {
                    tempImageView.frame = targetView.convert(targetView.bounds, to: containerView)
                    tempBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                } else {
                    tempImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                    tempBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                    tempImageView.alpha = 0.0
                }
                tempImageView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
                bottomBarView.alpha = 0.0
        }) { (isFinished) in
            let isCancelled = transitionContext.transitionWasCancelled
            if isCancelled {
                fromVC.view.isHidden = false
            } else {
            }
            if let navigationBar = toVC.navigationController?.navigationBar {
                navigationBar.isUserInteractionEnabled = true
            }
            self.targetView?.isHidden = false
            tempBackgroundView.removeFromSuperview()
            tempImageView.removeFromSuperview()
            bottomBarView.removeFromSuperview()
            if !isInteractive {
                transitionContext.completeTransition(!isCancelled)
            }
        }
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch self.direction {
        case .push:
            return 0.45
        case .pop:
            return 0.35
        }
    }
    
    func calcfinalImageSize() -> CGSize {
        if self.direction == .pop {
            return self.finalImageSize
        }
        if finalImageSize == CGSize.zero {
            return UIScreen.main.bounds.size
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
}
