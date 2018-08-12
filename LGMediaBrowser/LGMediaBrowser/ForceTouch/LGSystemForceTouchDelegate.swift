//
//  LGSystemForceTouchDelegate.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

/// 将系统的preview回调转换为内置回调
class LGSystemForceTouchDelegate: NSObject, UIViewControllerPreviewingDelegate {
    
    /// 内置回调
    weak var delegate: LGForceTouchPreviewingDelegate?
    
    /// 通过回调初始化
    ///
    /// - Parameter delegate: 回调
    init(delegate: LGForceTouchPreviewingDelegate?) {
        self.delegate = delegate
    }
    
    /// 注册force touch
    ///
    /// - Parameters:
    ///   - sourceView: 被点击的源视图
    ///   - viewController: 源视图的视图控制器
    func registerFor3DTouch(_ sourceView: UIView, viewController: UIViewController) {
        viewController.registerForPreviewing(with: self, sourceView: sourceView)
    }
    
    // MARK: -  系统回调
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController)
    {
        if let delegate = delegate {
            let context = LGForceTouchPreviewingContext(delegate: delegate,
                                                        sourceView: previewingContext.sourceView)
            delegate.previewingContext(context, commitViewController: viewControllerToCommit)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        if let delegate = delegate {
            let context = LGForceTouchPreviewingContext(delegate: delegate,
                                                        sourceView: previewingContext.sourceView)
            let viewController = delegate.previewingContext(context, viewControllerForLocation: location)
            previewingContext.sourceRect = context.sourceRect
            return viewController
        }
        return nil
    }
}
