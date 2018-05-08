//
//  UIDevice+LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/8.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

// Only use within this framework
extension UIDevice {
    static var deviceIsiPhoneX: Bool {
        return UIScreen.main.nativeBounds.size.equalTo(CGSize(width: 1125.0, height: 2436.0))
    }
    
    static var topSafeMargin: CGFloat {
        return UIDevice.deviceIsiPhoneX ? 44.0 : 0.0
    }
    
    static var bottomSafeMargin: CGFloat {
        return UIDevice.deviceIsiPhoneX ? 34.0 : 0.0
    }
}
