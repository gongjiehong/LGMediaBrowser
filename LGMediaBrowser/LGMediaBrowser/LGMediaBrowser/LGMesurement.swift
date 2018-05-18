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
    
    public static let isPhoneX: Bool = {
        return isPhone && UIScreen.main.nativeBounds.height == 2436
    }()
}
