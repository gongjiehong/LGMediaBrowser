//
//  LGForceTouch.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

public class LGForceTouchPreviewingContext {
    public weak var delegate: LGForceTouchPreviewingDelegate?
    
    public weak var sourceView: UIView?
    
    public var sourceRect: CGRect
    
    public init(delegate: LGForceTouchPreviewingDelegate?, sourceView: UIView) {
        self.delegate = delegate
        self.sourceView = sourceView
        self.sourceRect = sourceView.frame
    }
}

public protocol LGForceTouchPreviewingDelegate: class {
    func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           viewControllerForLocation location: CGPoint) -> UIViewController?
    
    func previewingContext(_ previewingContext: LGForceTouchPreviewingContext,
                           commitViewController viewControllerToCommit: UIViewController)
}

open class LGForceTouch: NSObject {
    var previewingContexts: [LGForceTouchPreviewingContext] = []
    weak var viewController: UIViewController?
    
    var forceTouchGestureRecognizer: LGForceTouchGestureRecognizer?
    
    var forceTouchDelegate: LGSystemForceTouchDelegate?

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    //MARK: Delegate registration
    open func registerForPreviewingWithDelegate(_ delegate: LGForceTouchPreviewingDelegate,
                                                sourceView: UIView) -> LGForceTouchPreviewingContext {
        let previewing = LGForceTouchPreviewingContext(delegate: delegate, sourceView: sourceView)
        previewingContexts.append(previewing)
        
        // If force touch is available, use Apple's implementation. Otherwise, use PeekPop's.
        if isForceTouchCapable() {
            let delegate = LGSystemForceTouchDelegate(delegate: delegate)
            guard let target = viewController else {
                return previewing
            }
            delegate.registerFor3DTouch(sourceView, viewController: target)
            forceTouchDelegate = delegate
        }
        else {
            let gestureRecognizer = LGForceTouchGestureRecognizer(forceTouch: self)
            gestureRecognizer.context = previewing
            gestureRecognizer.cancelsTouchesInView = false
            gestureRecognizer.delaysTouchesBegan = true
            gestureRecognizer.delegate = self
            sourceView.addGestureRecognizer(gestureRecognizer)
            forceTouchGestureRecognizer = gestureRecognizer
        }
        
        return previewing
    }
    
    func isForceTouchCapable() -> Bool {
        guard let target = viewController else {
            return false
        }
        return target.traitCollection.forceTouchCapability == .available && TARGET_OS_SIMULATOR != 1
    }
}


extension LGForceTouch: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
}

extension LGForceTouchPreviewingContext: Equatable {}
public func ==(lhs: LGForceTouchPreviewingContext, rhs: LGForceTouchPreviewingContext) -> Bool {
    return lhs.sourceView == rhs.sourceView
}
