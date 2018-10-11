//
//  UIDevice+LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

public struct LGMesurement {
    public static let isPhone: Bool = {
        return UIDevice.current.userInterfaceIdiom == .phone
    }()
    
    public static let isPad: Bool = {
        return UIDevice.current.userInterfaceIdiom == .pad
    }()

    public static let statusBarHeight: CGFloat = {
        return UIApplication.shared.statusBarFrame.height
    }()
    
    public static let screenWidth: CGFloat = {
        return UIScreen.main.bounds.width
    }()
    
    public static let screenHeight: CGFloat = {
        return UIScreen.main.bounds.height
    }()
    
    public static let screenScale: CGFloat = {
        return UIScreen.main.scale
    }()
    
    public static let screenRatio: CGFloat = {
        return screenWidth / screenHeight
    }()
    
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
}
