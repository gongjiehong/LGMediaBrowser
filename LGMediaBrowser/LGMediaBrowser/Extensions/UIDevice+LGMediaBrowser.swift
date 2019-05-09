//
//  UIDevice+LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/8.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

extension UIDevice {
    public static var isNotchScreen: Bool {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return false
        }
        
        if #available(iOS 11.0, *) {
            if keyWindow.safeAreaInsets.top > 20.0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public static var topSafeMargin: CGFloat {
        if isNotchScreen {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return 0.0
            }
            if #available(iOS 11.0, *) {
                return keyWindow.safeAreaInsets.top
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }
    
    public static var statusBarHeight: CGFloat {
        if isNotchScreen {
            return 0.0
        }
        return 20.0
    }
        
    public static var bottomSafeMargin: CGFloat {
        if isNotchScreen {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return 0.0
            }
            if #available(iOS 11.0, *) {
                return keyWindow.safeAreaInsets.bottom
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }
}
