//
//  LGPhotoManager.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/22.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos

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
        public static var audid: ResultMediaType = ResultMediaType(rawValue: 1 << 4)
    }
    
    public static var sort: SortBy = .descending
    
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
            
            for album in allAlbums where album.isKind(of: PHAssetCollection.self) {
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
                                                     isCameraRoll: true,
                                                     result: result,
                                                     headImageAsset: head)
                        resultAlbum.insert(model, at: 0)
                    } else {
                        let head = (self.sort == .ascending ? result.lastObject : result.firstObject)
                        let model = LGAlbumListModel(title: title,
                                                     count: result.count,
                                                     isCameraRoll: false,
                                                     result: result,
                                                     headImageAsset: head)
                        model.models = self.fetchPhoto(inResult: result,
                                                       supportMediaType: supportMediaType,
                                                       allowSelectLivePhoto: <#T##Bool#>)
                        resultAlbum.append(model)
                    }
                }
            }
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
            return String(format: "00:%2d", durationInt)
        } else if durationInt < 3600 {
            let minutes = durationInt / 60
            let seconds = durationInt % 60
            return String(format: "%2d:%2d", minutes, seconds)
        } else {
            let hours = durationInt / 3600
            let minutes = (durationInt % 3600) / 60
            let seconds = durationInt % 60
            return String(format: "%2d:%2d:%2d",hours , minutes, seconds)
        }
    }

}
