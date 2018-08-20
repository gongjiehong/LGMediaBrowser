//
//  LGMediaModel.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos
import AVFoundation
import LGWebImage
import LGHTTPRequest

/// 用于组装progress的最大值
private let _totalUnitCount: Int64 = 1000

/// 存储媒体数据的模型，承载下载数据功能
public class LGMediaModel {
    
    /// 定义媒体类型
    ///
    /// - generalPhoto: 普通图片，支持动图
    /// - livePhoto: LivePhoto
    /// - video: 视频
    /// - audio: 音频
    /// - other: 其它，此类型会被忽略，不处理展示
    public enum MediaType {
        case generalPhoto
        case livePhoto
        case video
        case audio
        case other
    }
    
    /// 媒体文件位置
    ///
    /// - remoteFile: 远程服务器上的文件
    /// - localFile: 本地文件
    /// - album: 系统相册中的PHAsset
    public enum Position {
        case remoteFile
        case localFile
        case album
    }
    
    /// 缩略图地址，如果是LivePhoto，该属性为第一帧图像的URL
    public private(set) var thumbnailImageURL: LGURLConvertible?
    
    /// 媒体文件地址，如果是LivePhoto，该属性为视频的URL
    public private(set) var mediaURL: LGURLConvertible?
    
    /// 相册中的媒体文件Asset对象
    public private(set) var mediaAsset: PHAsset?
    
    /// 媒体文件类型
    public private(set) var mediaType: MediaType
    
    /// 媒体文件位置
    public private(set) var mediaPosition: Position
    
    private var _progress: Progress?
    private var _thumbnailImage: UIImage?
    private var _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var _requestId: PHImageRequestID = PHInvalidImageRequestID
    
    private var _mediaFileProgress: Progress = Progress(totalUnitCount: _totalUnitCount / 2)
    private var _thumbnailImageProgress: Progress = Progress(totalUnitCount: _totalUnitCount / 2)
    
    /// 下载或导出进度
    public private(set) var progress: Progress {
        get {
            _ = _lock.wait(timeout: DispatchTime.distantFuture)
            defer {
                _ = _lock.signal()
            }
            
            if _progress == nil {
                _progress = Progress(totalUnitCount: _totalUnitCount)
                _progress?.addChild(_mediaFileProgress, withPendingUnitCount: _totalUnitCount / 2)
                _progress?.addChild(_thumbnailImageProgress, withPendingUnitCount: _totalUnitCount / 2)
                return _progress!
            } else {
                return _progress!
            }
        } set {
            _ = _lock.wait(timeout: DispatchTime.distantFuture)
            defer {
                _ = _lock.signal()
            }
            _progress = newValue
        }
    }
    
    /// 占位图，大多数时候直接就是原图
    public var thumbnailImage: UIImage? {
        set {
            _ = _lock.wait(timeout: DispatchTime.distantFuture)
            defer {
                _ = _lock.signal()
            }
            _thumbnailImage = newValue
        } get {
            _ = _lock.wait(timeout: DispatchTime.distantFuture)
            defer {
                _ = _lock.signal()
            }
            return _thumbnailImage
        }
    }
        
    
    /// 初始化, 同时会在异步线程请求媒体内容
    ///
    /// - Parameters:
    ///   - thumbnailImageURL: 媒体文件缩略图路径
    ///   - mediaURL: 媒体文件路径
    ///   - mediaAsset: 媒体文件的PHAsset
    ///   - mediaType: 媒体类型
    ///   - mediaPosition: 媒体文件的位置
    ///   - thumbnailImage: 缩略图
    public init(thumbnailImageURL: LGURLConvertible?,
                mediaURL: LGURLConvertible?,
                mediaAsset: PHAsset?,
                mediaType: MediaType,
                mediaPosition: Position,
                thumbnailImage: UIImage? = nil) /*throws*/
    {
//        switch mediaType {
//        case .video:
//         break
//        default:
//            break
//        }
        self.thumbnailImageURL = thumbnailImageURL
        self.mediaURL = mediaURL
        self.mediaAsset = mediaAsset
        self.mediaType = mediaType
        self.mediaPosition = mediaPosition
        self.thumbnailImage = thumbnailImage
        
        fetchThumbnailImage()
    }
    
    /// 获取缩略图
    func fetchThumbnailImage() {
        
        func downloadImageFromRemote() {
            if self.thumbnailImageURL == nil {
                return
            }
            LGWebImageManager.default.downloadImageWith(url: self.thumbnailImageURL!,
                                                        options: LGWebImageOptions.default,
                                                        progress:
                { [weak self] (progressValue) in
                    guard let weakSelf = self else { return }
                    weakSelf.progress = progressValue
                    
            }, transform: nil) { [weak self] (resultImage, resultURL, sourceType, imageStage, error) in
                guard let weakSelf = self else { return }
                weakSelf.thumbnailImage = resultImage
            }
        }
        
        func loadImageFromDisk() {
            if self.thumbnailImage == nil {
                DispatchQueue.background.async { [weak self] in
                    guard let weakSelf = self else { return }
                    do {
                        if let url = try weakSelf.thumbnailImageURL?.asURL() {
                            let absoluteString = url.absoluteString
                            // 正确的文件URL格式为 file://[path], 所以在转换后进行一次判断
                            if absoluteString.range(of: "://") != nil {
                                let data = try Data(contentsOf: url)
                                weakSelf.thumbnailImage = LGImage.imageWith(data: data)
                            } else {
                                let fileURL = URL(fileURLWithPath: absoluteString)
                                let data = try Data(contentsOf: fileURL)
                                weakSelf.thumbnailImage = LGImage.imageWith(data: data)
                            }
                            weakSelf.progress.completedUnitCount = _totalUnitCount
                        }
                    } catch {
                        println(error)
                    }
                }
            }
        }
        
        func exportImageFromAsset() {
            guard let asset = self.mediaAsset else { return }
            _requestId = LGPhotoManager.requestImage(forAsset: asset,
                                                     outputSize: CGSize(width: asset.pixelWidth,
                                                                        height: asset.pixelHeight),
                                                     resizeMode: PHImageRequestOptionsResizeMode.exact,
                                                     progressHandlder:
                { [weak self] (value, error, stop, info) in
                    guard let weakSelf = self else { return }
                    if error == nil {
                        weakSelf.progress.completedUnitCount = Int64(Double(_totalUnitCount) * value)
                    }
            }) { [weak self] (resultImage, info) in
                guard let weakSelf = self else { return }
                weakSelf.thumbnailImage = resultImage
            }
        }
        
        switch self.mediaPosition {
        case Position.remoteFile:
            downloadImageFromRemote()
            break
        case Position.localFile:
            loadImageFromDisk()
            break
        case Position.album:
            exportImageFromAsset()
            break
        }
    }
    
    public func fetchMediaFile() {
        func downloadGeneralPhoto() {
            do {
                let thumbnailImageURL = try self.thumbnailImageURL?.asURL()
                if let mediaURL = try self.mediaURL?.asURL()
                {
                    if thumbnailImageURL == mediaURL {
                        return
                    } else {
                        self.progress.addChild(_mediaFileProgress, withPendingUnitCount: _totalUnitCount / 2)
                        LGWebImageManager.default.downloadImageWith(url: mediaURL,
                                                                    options: LGWebImageOptions.default,
                                                                    progress:
                            { [weak self] (downloadProgress) in
                                guard let weakSelf = self else { return }
                                weakSelf._mediaFileProgress = downloadProgress
                        }, transform: nil) { [weak self] (resultImage, resultURL, sourceType, imageStage, error) in
                            
                        }
                    }
                }
            } catch {
                println(error)
            }
        }
        
        
        switch self.mediaPosition {
        case Position.remoteFile:
            switch self.mediaType {
            case MediaType.generalPhoto:
                downloadGeneralPhoto()
                break
            case MediaType.livePhoto:
                break
            case MediaType.audio:
                break
            case MediaType.video:
                break
            default:
                break
            }
            break
        case Position.localFile:
            break
        case Position.album:
            break
        }
    }
    
    deinit {
        LGPhotoManager.cancelImageRequest(_requestId)
    }
}


public enum LGMediaModelError: Error {
    case mediaURLIsInvalid
}
