//
//  UIApplication+Extensions.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2020/10/10.
//  Copyright © 2020 龚杰洪. All rights reserved.
//

import UIKit

extension UIApplication {
    public var lg_keyWindow: UIWindow? {
        if #available(iOS 13, *) {
            return self.windows.filter { $0.isKeyWindow }.first
        } else {
            return self.keyWindow
        }
    }
    
    public var lg_statusBarStyle: UIStatusBarStyle {
        return self.lg_keyWindow?.windowScene?.statusBarManager?.statusBarStyle ?? .default
    }
    
    public var lg_isStatusBarHidden: Bool {
        return self.lg_keyWindow?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
    }
    
    public var lg_statusBarOrientation: UIInterfaceOrientation {
        return self.lg_keyWindow?.windowScene?.interfaceOrientation ?? .portrait
    }
    
    public var lg_statusBarFrame: CGRect {
        return self.lg_keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
    }
}
