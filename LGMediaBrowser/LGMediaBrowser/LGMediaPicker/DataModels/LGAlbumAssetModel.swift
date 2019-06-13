//
//  LGAlbumAssetModel.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2019/6/12.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation
import Photos

/// 包装PHAsset对象
public class LGAlbumAssetModel {
    public var asset: PHAsset
    public var type: LGMediaType
    public var duration: String
    public var isSelected: Bool
    public var url: URL?
    public var image: UIImage?
    public var currentSelectedIndex: Int = -1
    
    public init(asset: PHAsset, type: LGMediaType, duration: String) {
        self.asset = asset
        self.type = type
        self.duration = duration
        self.isSelected = false
    }
    
    public var pixelSize: CGSize {
        return CGSize(width: self.asset.pixelWidth, height: self.asset.pixelHeight)
    }
    
    public func pixelSize(containInSize size: CGSize) -> CGSize {
        var width = min(CGFloat(self.asset.pixelWidth), size.width)
        var height = width * CGFloat(self.asset.pixelHeight) / CGFloat(self.asset.pixelWidth)
        
        if height.isNaN { return CGSize.zero }
        
        if height > size.height {
            height = size.height
            width = height * CGFloat(self.asset.pixelWidth) / CGFloat(self.asset.pixelHeight)
        }
        
        return CGSize(width: width, height: height)
    }
    
    /// 异步获取变同步，耗时操作
    public var isICloudAsset: Bool {
        let lock = DispatchSemaphore(value: 1)
        var result: Bool = false
        self.isICloudAsset { (isICloudAsset) in
            result = isICloudAsset
            lock.lg_unlock()
        }
        lock.lg_lock()
        return result
    }
    
    /// 判断内容是否在iCloud上，此操作特别耗时, 所以做成异步返回
    public func isICloudAsset(_ callback: @escaping (Bool) -> Void) {
        switch self.type {
        case .image, .animatedImage:
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            options.resizeMode = .fast
            LGAssetExportManager.default.imageManager.requestImageData(for: self.asset,
                                                                       options: options)
            { (data, dataUTI, orientation, infoDic) in
                let result = (data == nil)
                DispatchQueue.main.async {
                    callback(result)
                }
            }
            break
        case .video:
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            LGAssetExportManager.default.imageManager.requestAVAsset(forVideo: self.asset,
                                                                     options: options)
            { (avAsset, audioMix, infoDic) in
                let result = (avAsset == nil)
                DispatchQueue.main.async {
                    callback(result)
                }
            }
            break
        case .livePhoto:
            if #available(iOS 9.1, *) {
                let options = PHLivePhotoRequestOptions()
                options.isNetworkAccessAllowed = false
                options.deliveryMode = .fastFormat
                LGAssetExportManager.default.imageManager.requestLivePhoto(for: self.asset,
                                                                           targetSize: self.pixelSize,
                                                                           contentMode: PHImageContentMode.aspectFill,
                                                                           options: options)
                { (livePhoto, infoDic) in
                    let result = (livePhoto == nil)
                    DispatchQueue.main.async {
                        callback(result)
                    }
                }
            } else {
                callback(false)
            }
            break
        default:
            callback(false)
            break
        }
    }
}

extension LGAlbumAssetModel {
    public func asLGMediaModel() -> LGMediaModel {
        do {
            let model = try LGMediaModel(thumbnailImageURL: nil,
                                         mediaURL: nil,
                                         mediaAsset: self.asset,
                                         mediaType: self.type,
                                         mediaPosition: LGMediaModel.Position.album,
                                         thumbnailImage: self.image)
            model.photoModel = self
            model.isAutoPlayAnimatedImage = (self.type == .animatedImage)
            return model
        } catch {
            println(error)
            return LGMediaModel()
        }
    }
}


extension LGAlbumAssetModel {
    /// 导出图片的统一存储地址，预先创建文件夹，直接写入
    public var imageCachePath: String {
        guard let fileName = self.asset.localIdentifier.md5Hash() else {
            return ""
        }
        
        let tmpDirPath = NSTemporaryDirectory()
        let exportDir = tmpDirPath + "LGAlbumAssetModel/Export/Images"
        do {
            if FileManager.default.fileExists(atPath: exportDir) {
                
            } else {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: exportDir),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
            return exportDir + fileName + ".jpg"
        } catch {
            return ""
        }
    }
    
    /// LivePhoto导出时的统一存储地址，预先创建文件夹，直接写入
    public var livePhotoCachePath: (imagePath: String, moviePath: String) {
        guard let fileName = self.asset.localIdentifier.md5Hash() else {
            return ("", "")
        }
        
        let tmpDirPath = NSTemporaryDirectory()
        let exportDir = tmpDirPath + "LGAlbumAssetModel/Export/LivePhoto/"
        do {
            if FileManager.default.fileExists(atPath: exportDir) {
                
            } else {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: exportDir),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
            return (exportDir + fileName + ".jpg", exportDir + fileName + ".mov")
        } catch {
            return ("", "")
        }
    }
    
    /// 视频导出时的统一存储地址，预先创建文件夹，直接写入
    public var videoCachePath: (thumbnailImagePath: String, moviePath: String) {
        guard let fileName = self.asset.localIdentifier.md5Hash() else {
            return ("", "")
        }
        
        let tmpDirPath = NSTemporaryDirectory()
        let exportDir = tmpDirPath + "LGAlbumAssetModel/Export/Videos/"
        do {
            if FileManager.default.fileExists(atPath: exportDir) {
                
            } else {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: exportDir),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
            return (exportDir + fileName + ".jpg", exportDir + fileName + ".mp4")
        } catch {
            return ("", "")
        }
    }
}

