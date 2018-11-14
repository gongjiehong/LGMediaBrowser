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
/// - checkMedia: 媒体选择模式，私有，不能直接调用
public enum LGMediaBrowserStatus {
    case browsing
    case browsingAndEditing
    case checkMedia
}

public struct LGMediaBrowserSettings {
    public var showsStatusBar: Bool = true
    public var showsNavigationBar: Bool = false
    public var showsCloseButton: Bool = true
    public var showsDeleteButton: Bool = false
    public var isLongPhotoWidthMatchScreen: Bool = true
    public var isExchangeCloseAndDeleteButtons: Bool = false
    public var isClickToTurnOffEnabled: Bool = true
    public var isPlayVideoAfterDownloadEndsOrExportEnds: Bool = true
    public var backgroundColor: UIColor = UIColor.black
    
    public init() {
    }
    
    public static func browsing() -> LGMediaBrowserSettings {
        return LGMediaBrowserSettings()
    }
    
    public static func browsingAndEditing() -> LGMediaBrowserSettings {
        var result = LGMediaBrowserSettings()
        result.showsDeleteButton = true
        result.isClickToTurnOffEnabled = false
        return result
    }
    
    public static func checkMedia() -> LGMediaBrowserSettings {
        var result = LGMediaBrowserSettings()
        result.isClickToTurnOffEnabled = false
        result.showsNavigationBar = true
        result.showsStatusBar = true
        return result
    }
    
    public static func settings(with status: LGMediaBrowserStatus) -> LGMediaBrowserSettings {
        switch status {
        case .browsing:
            return self.browsing()
        case .browsingAndEditing:
            return self.browsingAndEditing()
        case .checkMedia:
            return self.checkMedia()
        }
    }
}


@objc public protocol LGMediaBrowserDelegate: NSObjectProtocol {
    @objc optional
    func didShow(_ browser: LGMediaBrowser, atIndex index: Int)
    
    @objc optional
    func willHide(_ browser: LGMediaBrowser, atIndex index: Int)
    
    @objc optional
    func didHide(_ browser: LGMediaBrowser, atIndex index: Int)
    
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

let kPanExitGestureName = "LGMediaBrowser.PanExit"

func LGLocalizedString(_ key: String, comment: String) -> String {
    return NSLocalizedString(key, tableName: "LGMediaBrowser", bundle: thisBundle(), value: "", comment: comment)
}

func LGLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, tableName: "LGMediaBrowser", bundle: thisBundle(), value: "", comment: key)
}
