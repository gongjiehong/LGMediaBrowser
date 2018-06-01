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

public struct LGMediaBrowserSettings {
    public var displayStatusbar: Bool = false
    public var displayCloseButton: Bool = true
    public var displayDeleteButton: Bool = false
    public var longPhotoWidthMatchScreen: Bool = true
    public var backgroundColor: UIColor = UIColor.black
    public var browserStatus: LGMediaBrowserStatus = .browsing
    public var swapCloseAndDeleteButtons: Bool = false
    public var enableTapToClose: Bool = true
    public var playVideoAfterDownloadOrExport: Bool = true
    
    public init() {
        
    }
}

public let kTapedScreenNotification = Notification.Name("TapedScreenNotification")
public let kNeedHideControlsNotification = Notification.Name("NeedHideControlsNotification")

public struct LGButtonOptions {
    public static var closeButtonPadding: CGPoint = CGPoint(x: 5, y: 20)
    public static var deleteButtonPadding: CGPoint = CGPoint(x: 5, y: 20)
}

@objc public protocol LGMediaBrowserDelegate: NSObjectProtocol {
    @objc optional
    func didShowMediaAtIndex(_ browser: LGMediaBrowser, index: Int)
    
    @objc optional
    func willDismissAtPageIndex(_ index: Int)
    
    @objc optional
    func didDismissAtPageIndex(_ index: Int)
    
    @objc optional
    func didScrollToIndex(_ browser: LGMediaBrowser, index: Int)
    
    @objc optional
    func removeMedia(_ browser: LGMediaBrowser, index: Int, reload: @escaping (() -> Void))
    
    @objc optional
    func viewForMedia(_ browser: LGMediaBrowser, index: Int) -> UIView?
    
    @objc optional
    func controlsVisibilityToggled(_ browser: LGMediaBrowser, hidden: Bool)
}

public protocol LGMediaBrowserDataSource: NSObjectProtocol {
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: LGMediaBrowser) -> Int
    func photoBrowser(_ photoBrowser: LGMediaBrowser, photoAtIndex index: Int) -> LGMediaModel
}

let kPanDissmissGestureName = "lg_panDissmiss"


func LGLocalizedString(_ key: String, comment: String) -> String {
    return NSLocalizedString(key, tableName: "LGMediaBrowser", bundle: thisBundle(), value: "", comment: comment)
}

func LGLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, tableName: "LGMediaBrowser", bundle: thisBundle(), value: "", comment: key)
}

