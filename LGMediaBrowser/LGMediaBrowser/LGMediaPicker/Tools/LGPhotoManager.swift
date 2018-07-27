//
//  LGPhotoManager.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos
import LGWebImage

public class LGPhotoManager {
    public enum SortBy {
        case ascending
        case descending
    }
    
    public struct ResultMediaType: OptionSet {
        public var rawValue: RawValue
        
        public typealias RawValue = Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static var image: ResultMediaType = ResultMediaType(rawValue: 1 << 0)
        public static var livePhoto: ResultMediaType = ResultMediaType(rawValue: 1 << 1)
        public static var animatedImage: ResultMediaType = ResultMediaType(rawValue: 1 << 2)
        public static var video: ResultMediaType = ResultMediaType(rawValue: 1 << 3)
        public static var audio: ResultMediaType = ResultMediaType(rawValue: 1 << 4)
        
        public static var all: ResultMediaType = [.image, .livePhoto, .animatedImage, .video, audio]
    }
    
    public static var sort: SortBy = .descending
    
    public static var imageManager: PHCachingImageManager = PHCachingImageManager()
    
    /// 根据支持的媒体类型获取相册列表
    ///
    /// - Parameters:
    ///   - supportMediaType: 支持的媒体类型
    ///   - complete: 完成回调
    public static func fetchAlbumList(_ supportMediaType: ResultMediaType, complete: ([LGAlbumListModel]) -> Void) {
        let supportVideo = supportMediaType.contains(.video)
        let supportImages = supportMediaType.contains(.image)
        
        guard supportVideo || supportImages else {
            complete([])
            return
        }

        
        let options = PHFetchOptions()
        if !supportVideo {
            options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        if !supportImages {
            options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        
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
        
        if let allAlbums = [smartAlbum, streamAlbum, userAlbum, syncedAlbum, sharedAlbum]
            as? [PHFetchResult<PHAssetCollection>]
        {
            var resultAlbum: [LGAlbumListModel] = []
            
            for album in allAlbums {
                album.enumerateObjects { (collection, index, stoped) in
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
                                                       supportMediaType: supportMediaType)
                        resultAlbum.insert(model, at: 0)
                    } else {
                        let head = (self.sort == .ascending ? result.lastObject : result.firstObject)
                        let model = LGAlbumListModel(title: title,
                                                     count: result.count,
                                                     isAllPhotos: false,
                                                     result: result,
                                                     headImageAsset: head)
                        model.models = self.fetchPhoto(inResult: result,
                                                       supportMediaType: supportMediaType)
                        resultAlbum.append(model)
                    }
                }
            }
            complete(resultAlbum)
            return
        } else {
            complete([])
            return
        }
    }
    
    /// 根据PHFetchResult<PHAsset>和支持的媒体类型组装LGPhotoModel
    ///
    /// - Parameters:
    ///   - result: PHFetchResult<PHAsset>
    ///   - supportMediaType: 支持的媒体类型定义
    ///   - allowSelectLivePhoto: 是否支持LivePhoto
    ///   - limitCount: 数量限制
    /// - Returns: [LGPhotoModel]
    public static func fetchPhoto(inResult result: PHFetchResult<PHAsset>,
                                  supportMediaType: ResultMediaType,
                                  limitCount: Int = Int.max) -> [LGPhotoModel]
    {
        var resultArray: [LGPhotoModel] = []
        var count: Int = 1
        result.enumerateObjects { (asset, index, stop) in
            let type = self.getAssetMediaType(from: asset)
            if type == LGPhotoModel.AssetMediaType.generalImage && !supportMediaType.contains(.image) { return }
            if type == LGPhotoModel.AssetMediaType.livePhoto && !supportMediaType.contains(.livePhoto)  { return }
            if type == LGPhotoModel.AssetMediaType.video && !supportMediaType.contains(.video) { return }
            if count == limitCount {
                stop.pointee = true
            }
            
            var durationStr = ""
            if asset.mediaType == .video {
                durationStr = formatDuration(asset.duration)
            }
            
            resultArray.append(LGPhotoModel(asset: asset, type: type, duration: durationStr))
            count += 1
        }
        
        return resultArray
    }
    
    /// 获取自定义媒体类型
    ///
    /// - Parameter asset: PHAsset
    /// - Returns: 结果LGPhotoModel.AssetMediaType
    public static func getAssetMediaType(from asset: PHAsset) -> LGPhotoModel.AssetMediaType {
        var result: LGPhotoModel.AssetMediaType = .unknown
        switch asset.mediaType {
        case .audio:
            result = .audio
            break
        case .video:
            result = .video
            break
        case .image:
            result = .generalImage
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes == .photoLive {
                    result = .livePhoto
                }
            } else {
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
    public static func formatDuration(_ duration: TimeInterval) -> String {
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
    public static func requestImage(forAsset asset: PHAsset,
                                    outputSize: CGSize = CGSize.zero,
                                    resizeMode: PHImageRequestOptionsResizeMode = PHImageRequestOptionsResizeMode.fast,
                                    progressHandlder: PHAssetImageProgressHandler? = nil,
                                    completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID
    {
        let options = PHImageRequestOptions()
        options.resizeMode = resizeMode
        options.isNetworkAccessAllowed = true
        options.progressHandler = progressHandlder
        
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
    
    public static func getAllPhotosAlbum(_ supportTypes: ResultMediaType = [.image, .video]) -> LGAlbumListModel {
        let options = PHFetchOptions()
        if !supportTypes.contains(.video) {
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        }
        
        if !supportTypes.contains(.image) {
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        }
        
        if self.sort != .ascending {
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.sort == .ascending)]
        }
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum,
                                                                  subtype: PHAssetCollectionSubtype.albumRegular,
                                                                  options: nil)
        var resultModel: LGAlbumListModel?
        smartAlbums.enumerateObjects { (assetCollection, index, stop) in
            if assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary {
                let result = PHAsset.fetchAssets(in: assetCollection, options: options)
                let headImageAsset = self.sort == .ascending ? result.lastObject : result.firstObject
                resultModel = LGAlbumListModel(title: assetCollection.localizedTitle,
                                               count: result.count,
                                               isAllPhotos: true,
                                               result: result,
                                               headImageAsset: headImageAsset)
                resultModel?.models = self.fetchPhoto(inResult: result,
                                     supportMediaType: supportTypes)
                resultModel?.isAllPhotos = true
            }
        }

        return resultModel!
    }
    
    public static func getPhotoBytes(withPhotos photos: [LGPhotoModel], completion: @escaping (String, Int) -> Void) {
        var totalDataLength: Int = 0
        var count: Int = 0
        for model in photos {
            imageManager.requestImageData(for: model.asset,
                                          options: nil)
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
    
    public static func formatDataLength(_ dataLength: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(dataLength))
    }
    
    
    public static func cancelImageRequest(_ requestId: PHImageRequestID) {
        if requestId != PHInvalidImageRequestID {
            imageManager.cancelImageRequest(requestId)
        }
    }
    
    public static func startCachingImages(for assets: [PHAsset],
                                          targetSize: CGSize,
                                          contentMode: PHImageContentMode,
                                          options: PHImageRequestOptions? = nil)
    {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        DispatchQueue.background.async {
            imageManager.startCachingImages(for: assets,
                                            targetSize: targetSize,
                                            contentMode: contentMode,
                                            options: options)
        }
    }
}
