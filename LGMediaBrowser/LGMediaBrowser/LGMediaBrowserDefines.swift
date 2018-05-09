//
//  LGMediaBrowserDefines.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/8.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

public enum LGMediaBrowserError: Error {
    case cannotConvertToURL
    case cannotConvertToPHAsset
}

/// LGMediaBrowser的状态定义，此状态决定内容的显示状态
///
/// - browsing: 纯浏览图片
/// - rowsingAndEditing: 浏览和编辑，例如修改
public enum LGMediaBrowserStatus {
    case browsing
    case browsingAndEditing
}

public struct LGMediaBrowserOptions {
    public var displayStatusbar: Bool = true
    public var displayCloseButton: Bool = true
    public var displayDeleteButton: Bool = false
    public var longPhotoWidthMatchScreen: Bool = true
    public var backgroundColor: UIColor = UIColor.black
    public var browserStatus: LGMediaBrowserStatus = .browsing
    public var swapCloseAndDeleteButtons: Bool = false
    
    public init() {
        
    }
}

public let kTapedScreenNotification = Notification.Name("TapedScreenNotification")

public struct LGButtonOptions {
    public static var closeButtonPadding: CGPoint = CGPoint(x: 5, y: 20)
    public static var deleteButtonPadding: CGPoint = CGPoint(x: 5, y: 20)
}
