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
private let totalUnitCount: Int64 = 1_000

public let LGMediaModelInvalidHashValue: Int64 = -1

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
    
    public typealias ProgressHandler = (Progress, Int64) -> Void
    
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
    public private(set) var mediaType: MediaType = .other
    
    /// 媒体文件位置
    public private(set) var mediaPosition: Position = .remoteFile
    
    public private(set) lazy var identify: Int64 = {
        return Int64(arc4random() - 1)
    }()
    
    internal weak var photoModel: LGPhotoModel? = nil
    
    private var _thumbnailImage: UIImage?
    private var _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var _requestId: PHImageRequestID = PHInvalidImageRequestID
    
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
    
    public init() {
        self.mediaType = .other
        self.mediaPosition = .localFile
        
        println(identify)
    }
    

    /// 初始化, 此处会校验参数是否合法
    ///
    /// - Parameters:
    ///   - thumbnailImageURL: 媒体文件缩略图路径
    ///   - mediaURL: 媒体文件路径
    ///   - mediaAsset: 媒体文件的PHAsset
    ///   - mediaType: 媒体类型
    ///   - mediaPosition: 媒体文件的位置
    ///   - thumbnailImage: 缩略图
    /// - Throws: 参数不正确的异常抛出
    public convenience init(thumbnailImageURL: LGURLConvertible?,
                mediaURL: LGURLConvertible?,
                mediaAsset: PHAsset?,
                mediaType: MediaType,
                mediaPosition: Position,
                thumbnailImage: UIImage? = nil) throws
    {
        self.init()
        func checkParams() throws {
            switch mediaPosition {
            case .remoteFile:
                switch mediaType {
                case .generalPhoto, .livePhoto, .video:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    } else if thumbnailImageURL == nil {
                        throw LGMediaModelError.thumbnailURLIsInvalid
                    }
                    break
                case .audio:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    break
                case .other:
                    break
                }
                break
            case .localFile:
                switch mediaType {
                case .generalPhoto:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    break
                case .livePhoto:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    } else if thumbnailImageURL == nil {
                        throw LGMediaModelError.thumbnailURLIsInvalid
                    }
                    break
                case .video, .audio:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    break
                case .other:
                    break
                }
                break
            case .album:
                if mediaAsset == nil {
                    throw LGMediaModelError.mediaAssetIsInvalid
                }
                break
            }
        }
        
        try checkParams()
        
        self.thumbnailImageURL = thumbnailImageURL
        self.mediaURL = mediaURL
        self.mediaAsset = mediaAsset
        self.mediaType = mediaType
        self.mediaPosition = mediaPosition
        self.thumbnailImage = thumbnailImage
    }
    
    /// 缩略图是否有效
    public var isThumbnailImageValid: Bool {
        if let thumbnailImageURL = try? self.thumbnailImageURL?.asURL() {
            if let mediaURL = try? self.mediaURL?.asURL() {
                if thumbnailImageURL == mediaURL {
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        return false
    }
    
    /// 获取需要下载或导出的缩略图
    ///
    /// - Parameters:
    ///   - progressBlock: 进度回调
    ///   - completion: 完成回调
    /// - Throws: 抛出过程中产生的异常
    public func fetchThumbnailImage(withProgress progressBlock: ProgressHandler?,
                             completion: ((UIImage?, Int64) -> Void)?) throws
    {
        if !isThumbnailImageValid {
            throw LGMediaModelError.unableToGetThumbnail
        }
        
        func downloadImageFromRemote() throws {
            if self.thumbnailImageURL == nil {
                throw LGMediaModelError.thumbnailURLIsInvalid
            }
            LGWebImageManager.default.downloadImageWith(url: self.thumbnailImageURL!,
                                                        options: LGWebImageOptions.default,
                                                        progress:
                { (progressValue) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {
                            progressBlock?(progressValue, LGMediaModelInvalidHashValue)
                            return
                        }
                        if let progressBlock = progressBlock {
                            progressBlock(progressValue, weakSelf.identify)
                        }
                    }
            }, transform: nil)
            { (resultImage, resultURL, sourceType, imageStage, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {
                        completion?(nil, LGMediaModelInvalidHashValue)
                        return
                    }
                    weakSelf.thumbnailImage = resultImage
                    if let completion = completion {
                        completion(weakSelf.thumbnailImage, weakSelf.identify)
                    }
                }
            }
            
        }
        
        func loadImageFromDisk() throws {
            if self.thumbnailImage == nil {
                var finalURL: URL?
                if let url = try self.thumbnailImageURL?.asURL() {
                    let absoluteString = url.absoluteString
                    // 正确的文件URL格式为 file://[path], 所以在转换后进行一次判断
                    if absoluteString.range(of: "://") != nil {
                        finalURL = url
                    } else {
                        finalURL = URL(fileURLWithPath: absoluteString)
                    }
                }
                
                if let finalURL = finalURL {
                    DispatchQueue.background.async { [weak self] in
                        do {
                            let data = try Data(contentsOf: finalURL)
                            let image = LGImage.imageWith(data: data)
                            DispatchQueue.main.async { [weak self] in
                                guard let weakSelf = self else {
                                    completion?(nil, LGMediaModelInvalidHashValue)
                                    return
                                }
                                weakSelf.thumbnailImage = image
                                if let completion = completion {
                                    completion(image, weakSelf.identify)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                completion?(nil, LGMediaModelInvalidHashValue)
                            }
                        }
                    }
                }
            } else {
                completion?(self.thumbnailImage, self.identify)
            }
        }
        
        func exportImageFromAsset() throws {
            guard let asset = self.mediaAsset else {
                throw LGMediaModelError.mediaAssetIsInvalid
            }
            let pixelSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            _requestId = LGPhotoManager.requestImage(forAsset: asset,
                                                     outputSize: fixedPixelSize(pixelSize),
                                                     resizeMode: PHImageRequestOptionsResizeMode.fast,
                                                     progressHandlder:
                { (value, error, stop, info) in
                    DispatchQueue.main.async { [weak self] in
                        if error == nil {
                            let progress = Progress(totalUnitCount: totalUnitCount)
                            progress.completedUnitCount = Int64(Double(totalUnitCount) * value)
                            if let progressBlock = progressBlock {
                                guard let weakSelf = self else {
                                    return
                                }
                                progressBlock(progress, weakSelf.identify)
                            }
                        }
                    }
            }) { (resultImage, info) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {
                        completion?(nil, LGMediaModelInvalidHashValue)
                        return
                    }
                    weakSelf.thumbnailImage = resultImage
                    if let completion = completion {
                        completion(weakSelf.thumbnailImage, weakSelf.identify)
                    }
                }
            }
        }
        
        switch self.mediaPosition {
        case Position.remoteFile:
            try downloadImageFromRemote()
            break
        case Position.localFile:
            try loadImageFromDisk()
            break
        case Position.album:
            try exportImageFromAsset()
            break
        }
    }
    
    /// 获取要下载或导出的原始图片
    ///
    /// - Parameters:
    ///   - progressBlock: 进度回调
    ///   - completion: 完成回调
    /// - Throws: 抛出过程中产生的异常
    public func fetchImage(withProgress progressBlock: LGProgressHandler?,
                    completion: ((UIImage?, Int64) -> Void)?) throws
    {
        func downloadImageFromRemote() throws {
            if self.thumbnailImageURL == nil {
                throw LGMediaModelError.mediaURLIsInvalid
            }
            LGWebImageManager.default.downloadImageWith(url: self.mediaURL!,
                                                        options: LGWebImageOptions.default,
                                                        progress:
                { (progressValue) in
                    DispatchQueue.main.async {
                        if let progressBlock = progressBlock {
                            progressBlock(progressValue)
                        }
                    }
            }, transform: nil)
            { (resultImage, resultURL, sourceType, imageStage, error) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {
                        completion?(nil, LGMediaModelInvalidHashValue)
                        return
                    }
                    weakSelf.thumbnailImage = resultImage
                    if let completion = completion {
                        completion(weakSelf.thumbnailImage, weakSelf.identify)
                    }
                }
            }
            
        }
        
        func loadImageFromDisk() throws {
            if self.thumbnailImage == nil {
                var finalURL: URL?
                if let url = try self.mediaURL?.asURL() {
                    let absoluteString = url.absoluteString
                    // 正确的文件URL格式为 file://[path], 所以在转换后进行一次判断
                    if absoluteString.range(of: "://") != nil {
                        finalURL = url
                    } else {
                        finalURL = URL(fileURLWithPath: absoluteString)
                    }
                }
                
                if let finalURL = finalURL {
                    DispatchQueue.background.async { [weak self] in
                        do {
                            let data = try Data(contentsOf: finalURL)
                            let image = LGImage.imageWith(data: data)
                            DispatchQueue.main.async { [weak self] in
                                guard let weakSelf = self else {
                                    completion?(nil, LGMediaModelInvalidHashValue)
                                    return
                                }
                                weakSelf.thumbnailImage = image
                                if let completion = completion {
                                    completion(image, weakSelf.identify)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                completion?(nil, LGMediaModelInvalidHashValue)
                            }
                        }
                    }
                }
            } else {
                completion?(self.thumbnailImage, self.identify)
            }
        }
        
        func exportImageFromAsset() throws {
            guard let asset = self.mediaAsset else {
                throw LGMediaModelError.mediaAssetIsInvalid
            }
            
            if #available(iOS 11.0, *) {
                if asset.playbackStyle == .imageAnimated {
                    _requestId = LGPhotoManager.requestImageData(for: asset,
                                                                 resizeMode: PHImageRequestOptionsResizeMode.fast,
                                                                 progressHandler:
                        { (progressValue, error, stoped, infoDic) in
                            DispatchQueue.main.async {
                                if error == nil {
                                    let progress = Progress(totalUnitCount: totalUnitCount)
                                    progress.completedUnitCount = Int64(Double(totalUnitCount) * progressValue)
                                    if let progressBlock = progressBlock {
                                        progressBlock(progress)
                                    }
                                }
                            }
                    }) { (imageData, dataUTI, orientation, infoDic) in
                        guard let imageData = imageData else {return}
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else {
                                completion?(nil, LGMediaModelInvalidHashValue)
                                return
                            }
                            weakSelf.thumbnailImage = LGImage.imageWith(data: imageData)
                            if let completion = completion {
                                completion(weakSelf.thumbnailImage, weakSelf.identify)
                            }
                        }
                    }
                    return
                }
            }
            
            let pixelSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            _requestId = LGPhotoManager.requestImage(forAsset: asset,
                                                     outputSize: fixedPixelSize(pixelSize),
                                                     resizeMode: PHImageRequestOptionsResizeMode.fast,
                                                     progressHandlder:
                { (value, error, stop, info) in
                    DispatchQueue.main.async {
                        if error == nil {
                            let progress = Progress(totalUnitCount: totalUnitCount)
                            progress.completedUnitCount = Int64(Double(totalUnitCount) * value)
                            if let progressBlock = progressBlock {
                                progressBlock(progress)
                            }
                        }
                    }
            }) { (resultImage, info) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {
                        completion?(nil, LGMediaModelInvalidHashValue)
                        return
                    }
                    weakSelf.thumbnailImage = resultImage
                    if let completion = completion {
                        completion(weakSelf.thumbnailImage, weakSelf.identify)
                    }
                }
            }
        }
        
        switch self.mediaPosition {
        case Position.remoteFile:
            try downloadImageFromRemote()
            break
        case Position.localFile:
            try loadImageFromDisk()
            break
        case Position.album:
            try exportImageFromAsset()
            break
        }
    }
    
    private func fixedPixelSize(_ size: CGSize) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width * UIScreen.main.scale
        let screenHeight = UIScreen.main.bounds.height * UIScreen.main.scale
        if size.width <= screenWidth && size.height < screenHeight {
            return size
        }
        
        if size.width > screenWidth {
            let scale = size.width / screenWidth
            let resultHeight = size.height / scale
            return CGSize(width: screenWidth, height: resultHeight)
        }
        
        if size.height > screenHeight {
            let scale = size.height / screenHeight
            let resultWidth = size.width / scale
            return CGSize(width: resultWidth, height: screenHeight)
        }
        
        return size
    }
    
    /// 获取PHLivePhoto，分别从本地URL，服务器，相册三种获取并合成
    ///
    /// - Parameters:
    ///   - progressBlock: 进度回调
    ///   - completion: 结果回调
    /// - Throws: 过程中产生的异常
    @available(iOS 9.1, *)
    public func fetchLivePhoto(withProgress progressBlock: LGProgressHandler?,
                               completion: ((PHLivePhoto?, Int64) -> Void)?) throws
    {
        func fetchLivePhotoFromAlbumAsset() {
            guard let asset = self.mediaAsset else { return }
            let options = PHLivePhotoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { (progress, error, stoped, infoDic) in
                DispatchQueue.main.async {
                    let total: Int64 = totalUnitCount
                    let result = Progress(totalUnitCount: total)
                    result.completedUnitCount = Int64(Double(totalUnitCount) * progress)
                    progressBlock?(result)
                }
            }
            _requestId = LGPhotoManager.imageManager.requestLivePhoto(for: asset,
                                                                      targetSize: CGSize(width: asset.pixelWidth,
                                                                                         height: asset.pixelHeight),
                                                                      contentMode: PHImageContentMode.aspectFill,
                                                                      options: options)
            { (livePhoto, infoDic) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    completion?(livePhoto, weakSelf.identify)
                }
            }
        }
        
        func fetchLivePhoto(withThumbnailImageURL thumbnailImageURL: URL,
                            mediaURL: URL,
                            placeholderImage: UIImage?)
        {
            PHLivePhoto.request(withResourceFileURLs: [thumbnailImageURL, mediaURL],
                                placeholderImage: placeholderImage,
                                targetSize: placeholderImage?.size ?? CGSize.zero,
                                contentMode: PHImageContentMode.aspectFill)
            { [weak self] (resultPhoto, infoDic) in
                guard let weakSelf = self else {
                    completion?(nil, LGMediaModelInvalidHashValue)
                    return
                }
                completion?(resultPhoto, weakSelf.identify)
            }
        }
        
        func fetchLivePhotoFromLocalFile() {
            do {
                if let thumbnailImageURL = try self.thumbnailImageURL?.asURL(),
                    let movieFileURL = try self.mediaURL?.asURL(),
                    FileManager.default.fileExists(atPath: thumbnailImageURL.path),
                    FileManager.default.fileExists(atPath: movieFileURL.path)
                {
                    var placeholderImage = self.thumbnailImage
                    if placeholderImage == nil {
                        placeholderImage = UIImage(contentsOfFile: thumbnailImageURL.path)
                    }
                    fetchLivePhoto(withThumbnailImageURL: thumbnailImageURL,
                                   mediaURL: movieFileURL,
                                   placeholderImage: placeholderImage)
                } else {
                    completion?(nil, LGMediaModelInvalidHashValue)
                }
            } catch {
                completion?(nil, LGMediaModelInvalidHashValue)
            }
        }
        
        func fetchLivePhotoFromRemoteFile() {
            do {
                if let thumbnailImageURL = try self.thumbnailImageURL?.asURL(),
                    let movieFileURL = try self.mediaURL?.asURL()
                {
                    let cacheKey = thumbnailImageURL.absoluteString
                    if LGImageCache.default.containsImage(forKey: cacheKey),
                        !LGFileDownloader.default.remoteURLIsDownloaded(thumbnailImageURL)
                    {
                        let diskCache = LGImageCache.default.diskCache
                        let originalURL = diskCache.filePathForDiskStorage(withKey: cacheKey)
                        let destinationImagePath = LGFileDownloader.Helper.filePath(withURL: thumbnailImageURL)
                        let destinationImageURL = URL(fileURLWithPath: destinationImagePath)
                        try? FileManager.default.copyItem(at: originalURL, to: destinationImageURL)
                    }
                    
                    if LGFileDownloader.default.remoteURLIsDownloaded(thumbnailImageURL),
                        LGFileDownloader.default.remoteURLIsDownloaded(movieFileURL)
                    {
                        var placeholderImage = self.thumbnailImage
                        if placeholderImage == nil {
                            placeholderImage = UIImage(contentsOfFile: thumbnailImageURL.path)
                        }
                        
                        let destinationImageURL = LGFileDownloader.Helper.filePath(withURL: thumbnailImageURL)
                        let destinationMovieFileURL = LGFileDownloader.Helper.filePath(withURL: movieFileURL)
                        fetchLivePhoto(withThumbnailImageURL: URL(fileURLWithPath: destinationImageURL),
                                       mediaURL: URL(fileURLWithPath: destinationMovieFileURL),
                                       placeholderImage: placeholderImage)
                    } else {
                        var synchronizeMark: Int = 0 {
                            didSet {
                                if synchronizeMark >= 2 {
                                    DispatchQueue.main.async {
                                        fetchLivePhotoFromLocalFile()
                                    }
                                }
                            }
                        }
                        
                        var totalProgress: Double = 0.0 {
                            didSet {
                                DispatchQueue.main.async {
                                    let total: Int64 = totalUnitCount
                                    let result = Progress(totalUnitCount: total)
                                    result.completedUnitCount = Int64(Double(totalUnitCount) * (totalProgress / 2.0))
                                    progressBlock?(result)
                                }
                            }
                        }
                        
                        LGFileDownloader.default.downloadFile(thumbnailImageURL,
                                                              progress:
                            { (progress) in
                                totalProgress += progress.fractionCompleted
                        }) { (destinationImageURL, isDownloadCompleted, error) in
                            if !isDownloadCompleted {
                                DispatchQueue.main.async { [weak self] in
                                    guard let weakSelf = self else {
                                        completion?(nil, LGMediaModelInvalidHashValue)
                                        return
                                    }
                                    completion?(nil, weakSelf.identify)
                                }
                                return
                            }
                            synchronizeMark += 1
                        }
                        
                        LGFileDownloader.default.downloadFile(movieFileURL,
                                                              progress:
                            { (progress) in
                                totalProgress += progress.fractionCompleted
                        }) { (destinationMovieURL, isDownloadCompleted, error) in
                            if !isDownloadCompleted {
                                DispatchQueue.main.async { [weak self] in
                                    guard let weakSelf = self else {
                                        completion?(nil, LGMediaModelInvalidHashValue)
                                        return
                                    }
                                    completion?(nil, weakSelf.identify)
                                }
                                return
                            }
                            synchronizeMark += 1
                        }
                    }
                } else {
                    completion?(nil, LGMediaModelInvalidHashValue)
                }
            } catch {
                completion?(nil, LGMediaModelInvalidHashValue)
            }
        }
        
        switch self.mediaPosition {
        case Position.remoteFile:
            fetchLivePhotoFromRemoteFile()
            break
        case Position.localFile:
            fetchLivePhotoFromLocalFile()
            break
        case Position.album:
            fetchLivePhotoFromAlbumAsset()
            break
        }
    }
    
    /// 获取AVPlayerItem，用于视频播放，内部分本地，远程和相册进行处理
    ///
    /// - Parameters:
    ///   - progressBlock: 进度回调
    ///   - completion: 结果回调
    /// - Throws: 过程中产生的异常
    public func fetchMoviePlayerItem(withProgress progressBlock: LGProgressHandler?,
                                   completion: ((AVPlayerItem?, Int64) -> Void)?) throws
    {
        func fetchLocalVideo() throws {
            if let url = try self.mediaURL?.asURL() {
                let playerItem = AVPlayerItem(url: url)
                completion?(playerItem, self.identify)
            }
        }
        
        func fetchRemoteVideo() throws {
            if let url = try self.mediaURL?.asURL() {
                if globalConfigs.isPlayVideoAfterDownloadEndsOrExportEnds &&
                    !LGFileDownloader.default.remoteURLIsDownloaded(url)
                {
                    LGFileDownloader.default.downloadFile(url,
                                                          progress:
                        { (progress) in
                            DispatchQueue.main.async {
                                progressBlock?(progress)
                            }
                    }) { [weak self] (destinationURL, isDownloadCompleted, error) in
                        guard let weakSelf = self else {
                            completion?(nil, LGMediaModelInvalidHashValue)
                            return
                        }
                        if let destinationURL = destinationURL, isDownloadCompleted {
                            let playerItem = AVPlayerItem(url: destinationURL)
                            completion?(playerItem, weakSelf.identify)
                        } else {
                            completion?(nil, weakSelf.identify)
                        }
                    }
                } else {
                    let playerItem = AVPlayerItem(url: url)
                    completion?(playerItem, self.identify)
                }
            }
        }
        
        func fetchAlbumVideo() {
            if let asset = self.mediaAsset {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.progressHandler = {(progress, error, stop, infoDic) in
                    DispatchQueue.main.async {
                        let progressValue = Progress(totalUnitCount: totalUnitCount)
                        progressValue.completedUnitCount = Int64(Double(totalUnitCount) * progress)
                        progressBlock?(progressValue)
                    }
                }
                
                _requestId = LGPhotoManager.imageManager.requestAVAsset(forVideo: asset,
                                                           options: options)
                { (avAsset, audioMix, infoDic) in
                    DispatchQueue.main.async { [weak self] in
                        guard let avAsset = avAsset, let weakSelf = self else {
                            completion?(nil, LGMediaModelInvalidHashValue)
                            return
                        }
                        let playerItem = AVPlayerItem(asset: avAsset)
                        completion?(playerItem, weakSelf.identify)
                    }
                }
            } else {
                completion?(nil, self.identify)
            }
        }
        
        switch self.mediaPosition {
        case .localFile:
            try fetchLocalVideo()
            break
        case .remoteFile:
            try fetchRemoteVideo()
            break
        case .album:
            fetchAlbumVideo()
            break
        }
    }
    
    deinit {
        LGPhotoManager.cancelImageRequest(_requestId)
    }
}

//extension LGMediaModel: Hashable {
//    public static func == (lhs: LGMediaModel, rhs: LGMediaModel) -> Bool {
//        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
//    }
//    public var hashValue: Int {
//        return ObjectIdentifier(self).identify
//    }
//}


public enum LGMediaModelError: Error {
    case thumbnailURLIsInvalid
    case mediaURLIsInvalid
    case mediaAssetIsInvalid
    case unableToGetThumbnail
}
