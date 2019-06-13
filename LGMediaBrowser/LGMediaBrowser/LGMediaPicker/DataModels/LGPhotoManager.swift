//
//  LGAssetExportManager.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos
import LGWebImage

/// 处理图片和相册信息获取，缓存，销毁缓存等
public class LGAssetExportManager {
    /// 输出结果排序方式
    ///
    /// - ascending: 升序排列
    /// - descending: 降序排列
    public enum SortBy {
        /// 升序排列
        case ascending
        
        /// 降序排列
        case descending
    }
    
    
    /// LGAssetExportManager单例
    public static let `default`: LGAssetExportManager = {
        return LGAssetExportManager()
    }()
    
    public init() {
    }
    
    /// 排序方式，默认升序
    public var sort: SortBy = .ascending
    
    /// PHCachingImageManager，默认 PHCachingImageManager()
    public var imageManager: PHCachingImageManager = PHCachingImageManager()
    
    
    /// 根据支持的媒体类型获取相册列表
    ///
    /// - Parameters:
    ///   - supportTypes: 支持的媒体类型
    ///   - complete: 完成回调
    public func fetchAlbumList(_ supportTypes: LGMediaType, complete: ([LGAlbumListModel]) -> Void) {
        
        let predicateString = constructPredicateString(supportTypes)
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: predicateString)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.sort == .ascending)]
        
        let smartAlbum = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum,
                                                                 subtype: PHAssetCollectionSubtype.albumRegular,
                                                                 options: nil)
        let streamAlbum = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                  subtype: .albumMyPhotoStream,
                                                                  options: nil)
        let userAlbum = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        let syncedAlbum = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                  subtype: .albumSyncedAlbum,
                                                                  options: nil)
        let sharedAlbum = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                  subtype: .albumCloudShared,
                                                                  options: nil)
        
        var allAlbums = [PHFetchResult<PHAssetCollection>]()
        allAlbums.append(smartAlbum)
        allAlbums.append(streamAlbum)
        if let userAlbum = userAlbum as? PHFetchResult<PHAssetCollection> {
            allAlbums.append(userAlbum)
        }
        allAlbums.append(syncedAlbum)
        allAlbums.append(sharedAlbum)
        
        var resultAlbum: [LGAlbumListModel] = []
        
        for album in allAlbums {
            album.enumerateObjects { (collection, index, stoped) in
                // smartAlbumLongExposures = 215
                if collection.assetCollectionSubtype.rawValue > 215 ||
                    collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                
                let result = PHAsset.fetchAssets(in: collection, options: options)
                if result.count < 1 { return }
                let title = collection.localizedTitle
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    let head = (self.sort == .ascending ? result.lastObject : result.firstObject)
                    let model = LGAlbumListModel(title: title,
                                                 count: result.count,
                                                 isAllPhotos: true,
                                                 result: result,
                                                 headImageAsset: head)
                    model.models = self.fetchPhoto(inResult: result,
                                                   supportTypes: supportTypes)
                    resultAlbum.insert(model, at: 0)
                } else {
                    let head = (self.sort == .ascending ? result.lastObject : result.firstObject)
                    let model = LGAlbumListModel(title: title,
                                                 count: result.count,
                                                 isAllPhotos: false,
                                                 result: result,
                                                 headImageAsset: head)
                    model.models = self.fetchPhoto(inResult: result,
                                                   supportTypes: supportTypes)
                    resultAlbum.append(model)
                }
            }
        }
        complete(resultAlbum)
    }
    
    /// 根据PHFetchResult<PHAsset>和支持的媒体类型组装LGAlbumAssetModel
    ///
    /// - Parameters:
    ///   - result: PHFetchResult<PHAsset>
    ///   - supportTypes: 支持的媒体类型定义
    ///   - allowSelectLivePhoto: 是否支持LivePhoto
    ///   - limitCount: 数量限制
    /// - Returns: [LGAlbumAssetModel]
    public func fetchPhoto(inResult result: PHFetchResult<PHAsset>,
                           supportTypes: LGMediaType,
                           limitCount: Int = Int.max) -> [LGAlbumAssetModel]
    {
        var resultArray: [LGAlbumAssetModel] = []
        var count: Int = 1
        
        autoreleasepool {
            result.enumerateObjects { (asset, index, stop) in
                let type = self.getMediaType(from: asset, supportTypes: supportTypes)
                if type == LGMediaType.image, !supportTypes.contains(.image) { return }
                if type == LGMediaType.animatedImage, !supportTypes.contains(.animatedImage) { return }
                if type == LGMediaType.livePhoto, !supportTypes.contains(.livePhoto)  { return }
                if type == LGMediaType.video, !supportTypes.contains(.video) { return }
                if count == limitCount {
                    stop.pointee = true
                }
                
                var durationStr = ""
                if asset.mediaType == .video {
                    durationStr = self.formatDuration(asset.duration)
                }
                
                resultArray.append(LGAlbumAssetModel(asset: asset, type: type, duration: durationStr))
                count += 1
            }
        }
        
        return resultArray
    }
    
    /// 获取自定义媒体类型
    ///
    /// - Parameter asset: PHAsset
    /// - Returns: 结果LGMediaType
    public func getMediaType(from asset: PHAsset,
                             supportTypes: LGMediaType) -> LGMediaType
    {
        var result: LGMediaType = .unsupport
        switch asset.mediaType {
        case .video:
            result = .video
            break
        case .image:
            result = .image
            if asset.mediaSubtypes == .photoLive, supportTypes.contains(.livePhoto) {
                result = .livePhoto
            } else if #available(iOS 11.0, *),
                asset.playbackStyle == .imageAnimated,
                supportTypes.contains(.animatedImage)
            {
                result = .animatedImage
            }
            break
        default:
            break
        }
        return result
    }
    
    /// 格式化视频时长为hh:mm:ss格式
    ///
    /// - Parameter duration: 视频时长
    /// - Returns: hh:mm:ss格式字符串
    public func formatDuration(_ duration: TimeInterval) -> String {
        let durationInt = Int(duration)
        if durationInt < 60 {
            return String(format: "00:%0.2d", durationInt)
        } else if durationInt < 3600 {
            let minutes = durationInt / 60
            let seconds = durationInt % 60
            return String(format: "%0.2d:%0.2d", minutes, seconds)
        } else {
            let hours = durationInt / 3600
            let minutes = (durationInt % 3600) / 60
            let seconds = durationInt % 60
            return String(format: "%0.2d:%0.2d:%0.2d",hours , minutes, seconds)
        }
    }
    
    public typealias ImageDataCompleteBlock = (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void
    
    /// 根据asset获取Data
    ///
    /// - Parameters:
    ///   - asset: PHAsset对象
    ///   - resizeMode: 缩放模式，默认选最快速的
    ///   - progressHandler: 下载进度回调
    ///   - resultHandler: 完成回调
    /// - Returns: 请求ID PHImageRequestID
    @discardableResult
    public func requestImageData(for asset: PHAsset,
                                 resizeMode: PHImageRequestOptionsResizeMode,
                                 progressHandler: PHAssetImageProgressHandler?,
                                 resultHandler: @escaping ImageDataCompleteBlock) -> PHImageRequestID
    {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = resizeMode
        options.progressHandler = progressHandler
        return imageManager.requestImageData(for: asset,
                                             options: options,
                                             resultHandler: resultHandler)
    }
    
    
    
    /// 根据图片ASSET，最终输出大小，缩放模式请求图片
    ///
    /// - Parameters:
    ///   - asset: 图片PHAsset对象
    ///   - outputSize: 需要的输出大小
    ///   - resizeMode: 缩放模式，默认选最快速的
    ///   - progressHandlder: 下载进度回调
    ///   - completion: 完成回调
    /// - Returns: 请求ID PHImageRequestID
    @discardableResult
    public func requestImage(forAsset asset: PHAsset,
                             outputSize: CGSize = CGSize.zero,
                             isAsync: Bool = true,
                             resizeMode: PHImageRequestOptionsResizeMode = PHImageRequestOptionsResizeMode.fast,
                             progressHandlder: PHAssetImageProgressHandler? = nil,
                             completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID
    {
        let options = PHImageRequestOptions()
        options.resizeMode = resizeMode
        options.isNetworkAccessAllowed = true
        options.progressHandler = progressHandlder
        options.isSynchronous = !isAsync
        
        var realOutputSize: CGSize
        if outputSize.equalTo(CGSize.zero) {
            realOutputSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        } else {
            realOutputSize = outputSize
        }
        
        return imageManager.requestImage(for: asset,
                                         targetSize: realOutputSize,
                                         contentMode: PHImageContentMode.aspectFill,
                                         options: options,
                                         resultHandler:
            { (resultImage, infoDic) in
                
                let isCancelled = infoDic?[PHImageCancelledKey] as? Bool
                let hasError = (infoDic?[PHImageErrorKey] != nil)
                if isCancelled != true && hasError == false {
                    completion(resultImage, infoDic)
                }
        })
    }
    
    /// 获取‘所有照片’相册内容
    ///
    /// - Parameter supportTypes: 支持的内容类型
    /// - Returns: LGAlbumListModel对象，如果没有相册则返回空
    public func getAllPhotosAlbum(_ supportTypes: LGMediaType = .all) -> LGAlbumListModel? {
        let predicateString = constructPredicateString(supportTypes)
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: predicateString)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.sort == .ascending)]
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum,
                                                                  subtype: PHAssetCollectionSubtype.albumRegular,
                                                                  options: nil)
        var resultModel: LGAlbumListModel?
        
        smartAlbums.enumerateObjects { (assetCollection, index, stop) in
            if assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary
            {
                let result = PHAsset.fetchAssets(in: assetCollection, options: options)
                let headImageAsset = self.sort == .ascending ? result.lastObject : result.firstObject
                resultModel = LGAlbumListModel(title: assetCollection.localizedTitle,
                                               count: result.count,
                                               isAllPhotos: true,
                                               result: result,
                                               headImageAsset: headImageAsset)
                resultModel?.models = self.fetchPhoto(inResult: result,
                                                      supportTypes: supportTypes)
                resultModel?.isAllPhotos = true
            }
        }
        
        return resultModel
    }
    
    /// 组装查询条件文本
    ///
    /// - Parameter supportTypes: 支持的内容类型
    /// - Returns: 组装好的查询条件文本
    func constructPredicateString(_ supportTypes: LGMediaType) -> String {
        var predicateString: String = ""
        if supportTypes == .video {
            predicateString = String(format: "mediaType = %ld", PHAssetMediaType.video.rawValue)
        } else if supportTypes == .livePhoto {
            predicateString = String(format: "mediaType = %ld && mediaSubtype = %ld",
                                     PHAssetMediaType.image.rawValue,
                                     PHAssetMediaSubtype.photoLive.rawValue)
        } else if supportTypes == .animatedImage {
            if #available(iOS 11.0, *) {
                predicateString = String(format: "mediaType = %ld && playbackStyle = %ld",
                                         PHAssetMediaType.image.rawValue,
                                         PHAsset.PlaybackStyle.imageAnimated.rawValue)
            } else {
                fatalError("animated image only need iOS 11.0 and above")
            }
        } else if supportTypes == .all {
            predicateString = String(format: "mediaType = %ld || mediaType = %ld",
                                     PHAssetMediaType.image.rawValue,
                                     PHAssetMediaType.video.rawValue)
        } else if supportTypes == .image {
            predicateString = String(format: "mediaType = %ld",
                                     PHAssetMediaType.image.rawValue)
        }  else {
            fatalError("Type combination is not supported")
        }
        return predicateString
    }
    
    /// 获取多个内容累加大小
    ///
    /// - Parameters:
    ///   - photos: LGAlbumAssetModel数组，表示多个内容对象
    ///   - completion: 完成回调，返回格式化的大小文本和原始大小
    public func getPhotoBytes(withPhotos photos: [LGAlbumAssetModel], completion: @escaping (String, Int) -> Void) {
        var totalDataLength: Int = 0
        var count: Int = 0
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        autoreleasepool {
            for model in photos {
                imageManager.requestImageData(for: model.asset,
                                              options: options)
                { (data, dataUTI, imageOrientation, infoDic) in
                    guard let data = data else { return }
                    totalDataLength += data.count
                    count += 1
                    if count >= photos.count {
                        completion(self.formatDataLength(totalDataLength), totalDataLength)
                    }
                }
            }
        }
    }
    
    /// 格式化文件长度文本
    ///
    /// - Parameter dataLength: 原始文件长度
    /// - Returns: 格式化后的文本
    public func formatDataLength(_ dataLength: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(dataLength))
    }
    
    /// 取消相册，图片，data等请求
    ///
    /// - Parameter requestId: 有效的请求id
    public func cancelImageRequest(_ requestId: PHImageRequestID) {
        if requestId != PHInvalidImageRequestID {
            imageManager.cancelImageRequest(requestId)
        }
    }
    
    /// 根据指定条件开始缓存图片，系统会处理内存和磁盘缓存，默认采用fast模式，支持从网络下载
    ///
    /// - Parameters:
    ///   - assets: 需要缓存的内容对象数组[PHAsset]
    ///   - targetSize: 目标图片大小
    ///   - contentMode: 内容展示模式PHImageContentMode
    ///   - options: 配置PHImageRequestOptions，默认空
    public func startCachingImages(for assets: [PHAsset],
                                   targetSize: CGSize,
                                   contentMode: PHImageContentMode,
                                   options: PHImageRequestOptions? = nil)
    {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        DispatchQueue.background.async {
            self.imageManager.startCachingImages(for: assets,
                                                 targetSize: targetSize,
                                                 contentMode: contentMode,
                                                 options: options)
        }
    }
    
    /// 停止缓存图片
    public func stopCachingImages() {
        DispatchQueue.background.async {
            if LGAuthorizationStatusManager.default.albumStatus == .authorized {
                self.imageManager.stopCachingImagesForAllAssets()
            }
        }
    }
}

