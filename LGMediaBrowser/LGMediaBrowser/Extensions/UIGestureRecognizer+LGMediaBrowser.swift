//
//  UIGestureRecognizer+LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/15.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

// Only use within this framework
extension UIGestureRecognizer {
    private struct AssociatedKeys {
        static var name: String = "lg_name"
    }
    var lg_name: String? {
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.name,
                                     newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            return objc_getAssociatedObject(self, &AssociatedKeys.name) as? String
        }
    }
}
