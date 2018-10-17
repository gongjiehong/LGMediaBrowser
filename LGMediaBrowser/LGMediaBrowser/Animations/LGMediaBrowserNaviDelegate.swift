//
//  LGMediaBrowserNaviDelegate.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/10/17.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public protocol LGMediaBrowserPushAnimationDelegate: NSObjectProtocol {
    func navigationController(_ navigationController: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
}

open class LGMediaBrowserNaviDelegate: NSObject, UINavigationControllerDelegate {
    
    private weak var targetController: UIViewController?
    
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if operation == .push {
            targetController = toVC
        } else {
            targetController = fromVC
        }
        
        if let temp = toVC as? LGMediaBrowserPushAnimationDelegate {
            return temp.navigationController(navigationController,
                                             animationControllerFor: operation,
                                             from: fromVC,
                                             to: toVC)
        } else if let temp = fromVC as? LGMediaBrowserPushAnimationDelegate {
            return temp.navigationController(navigationController,
                                             animationControllerFor: operation,
                                             from: fromVC,
                                             to: toVC)
        } else {
            return nil
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor controller: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        if let temp = targetController as? LGMediaBrowserPushAnimationDelegate {
            return temp.navigationController(navigationController, interactionControllerFor: controller)
        } else {
            return nil
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool)
    {
        println(viewController)
    }
}
