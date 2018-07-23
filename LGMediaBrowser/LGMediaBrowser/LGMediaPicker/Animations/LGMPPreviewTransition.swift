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
    
    public private(set) var direction: Direction
    
    public init(withDirection direction: Direction) {
        self.direction = direction
    }
}

extension LGMPPreviewTransition: UIViewControllerAnimatedTransitioning {
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch self.direction {
        case .push:
            break
        case .pop:
            break
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
}
