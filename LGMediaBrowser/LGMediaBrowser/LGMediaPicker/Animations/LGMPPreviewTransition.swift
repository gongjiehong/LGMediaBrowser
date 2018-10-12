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
        
    }
    
    func popAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch self.direction {
        case .push:
            return 0.45
        case .pop:
            return 0.35
        }
    }
}
