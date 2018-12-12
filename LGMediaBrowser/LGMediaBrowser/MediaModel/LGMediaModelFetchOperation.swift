//
//  LGMediaModelFetchOperation.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/12/10.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import LGHTTPRequest
import LGWebImage
import AVFoundation
import Photos


/// 用于组装progress的最大值
private let totalUnitCount: Int64 = 1_000
open class LGMediaModelFetchOperation: Operation {
    public typealias ProgressBlock = LGProgressHandler
    
    public typealias ImageCompletionBlock = ((UIImage?, Bool, Error?) -> Void)
    public typealias ThumbnailImageCompletionBlock = ImageCompletionBlock
    public typealias VideoCompletionBlock = ((AVPlayerItem?, Bool, Error?) -> Void)
    public typealias AudioCompletionBlock = VideoCompletionBlock
    public typealias LivephotoCompletionBlock = ((PHLivePhoto?, Bool, Error?) -> Void)
    
    private var _isFinished: Bool = false
    open override var isFinished: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isFinished
        } set {
            lock.lock()
            defer {
                lock.unlock()
            }
            if _isFinished != newValue {
                willChangeValue(forKey: "isFinished")
                _isFinished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    private var _isCancelled: Bool = false
    open override var isCancelled: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isCancelled
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            if _isCancelled != newValue {
                willChangeValue(forKey: "isCancelled")
                _isCancelled = newValue
                didChangeValue(forKey: "isCancelled")
            }
        }
    }
    
    private var _isExecuting: Bool = false
    open override var isExecuting: Bool {
        get{
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isExecuting
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            
            if _isExecuting != newValue {
                willChangeValue(forKey: "isExecuting")
                _isExecuting = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }
    
    open override var isConcurrent: Bool {
        return true
    }
    
    open override var isAsynchronous: Bool {
        return true
    }
    
    private var isStarted: Bool = false
    private var lock: NSRecursiveLock = NSRecursiveLock()
    private var taskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    private weak var thumbnailImageOperation: LGWebImageOperation?
    private weak var mediaImageOperation: LGWebImageOperation?
    private weak var thumbnailImageDownloadOperation: LGFileDownloadOperation?
    private weak var fileDownloadOperation: LGFileDownloadOperation?
    private var imageRequestId: PHImageRequestID = PHInvalidImageRequestID
    private var livePhotoRequestId: Int32 = PHLivePhotoRequestIDInvalid
    
    private weak var imageCache = LGImageCache.default
    private weak var mediaModel: LGMediaModel?
    
    var progress: ProgressBlock?
    var thumbnailImageCompletion: ThumbnailImageCompletionBlock? = nil
    var imageCompletion: ImageCompletionBlock? = nil
    var videoCompletion: VideoCompletionBlock? = nil
    var audioCompletion: AudioCompletionBlock? = nil
    var livePhotoCompletion: LivephotoCompletionBlock? = nil
    var destinationURL: URL?
    
    public init(withMediaModel model: LGMediaModel,
                progress: ProgressBlock? = nil,
                thumbnailImageCompletion: ThumbnailImageCompletionBlock? = nil,
                imageCompletion: ImageCompletionBlock? = nil,
                videoCompletion: VideoCompletionBlock? = nil,
                audioCompletion: AudioCompletionBlock? = nil,
                livePhotoCompletion: LivephotoCompletionBlock? = nil) {
        super.init()
        self.mediaModel = model
        self.progress = progress
        self.thumbnailImageCompletion = thumbnailImageCompletion
        self.imageCompletion = imageCompletion
        self.videoCompletion = videoCompletion
        self.audioCompletion = audioCompletion
        self.livePhotoCompletion = livePhotoCompletion
    }
    
    open override func start() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        isStarted = true
        
        if isCancelled {
            cancelOperation()
            isFinished = true
        } else if isReady, !isFinished, !isExecuting {
            self.isExecuting = true

            guard let mediaModel = self.mediaModel else {
                self.invokeThumbnailImageCompletionOnMainThread(nil,
                                                                remoteURL: nil,
                                                                sourceType: LGWebImageSourceType.none,
                                                                imageStage: LGWebImageStage.cancelled,
                                                                error: LGMediaModelError.mediaModelIsInvalid)
                return
            }
            
            do {
                switch mediaModel.mediaType {
                case .generalPhoto:
                    try fetchMediaImage()
                    break
                case .livePhoto:
                    try fetchLivePhoto()
                    break
                case .video:
                    try fetchMoviePlayerItem()
                    break
                default:
                    throw LGMediaModelError.mediaModelIsInvalid
                }
            } catch {
                self.invokeThumbnailImageCompletionOnMainThread(nil,
                                                                remoteURL: nil,
                                                                sourceType: LGWebImageSourceType.none,
                                                                imageStage: LGWebImageStage.cancelled,
                                                                error: error)
                println(error)
            }
        }
    }
    
    func invokeThumbnailImageCompletionOnMainThread(_ image: UIImage?,
                                                    remoteURL: URL?,
                                                    sourceType: LGWebImageSourceType,
                                                    imageStage: LGWebImageStage,
                                                    error: Error?)
    {
        guard let completion = self.thumbnailImageCompletion else {return}
        DispatchQueue.main.async { [weak self] in
            completion(image,
                       error == nil,
                       error)
            guard let weakSelf = self else {return}
            if imageStage != .progress {
                weakSelf.finish()
            }
        }
    }
    
    func invokeMediaImageCompletionOnMainThread(_ image: UIImage?,
                                                remoteURL: URL?,
                                                sourceType: LGWebImageSourceType,
                                                imageStage: LGWebImageStage,
                                                error: Error?)
    {
        guard let completion = self.imageCompletion else {return}
        DispatchQueue.main.async { [weak self] in
            completion(image,
                       error == nil,
                       error)
            guard let weakSelf = self else {return}
            if imageStage != .progress {
                weakSelf.finish()
            }
        }
    }
    
    func invokeLivePhotoCompletionOnMainThread(_ livePhoto: PHLivePhoto?, isFinished: Bool, error: Error?) {
        guard let completion = self.livePhotoCompletion else {return}
        DispatchQueue.main.async { [weak self] in
            completion(livePhoto,
                       error == nil,
                       error)
            guard let weakSelf = self else {return}
            if isFinished {
                weakSelf.finish()
            }
        }
    }
    
    func invokeVideoCompletionOnMainThread(_ playerItem: AVPlayerItem?, isFinished: Bool, error: Error?) {
        guard let completion = self.videoCompletion else {return}
        DispatchQueue.main.async { [weak self] in
            completion(playerItem,
                       error == nil,
                       error)
            guard let weakSelf = self else {return}
            if isFinished {
                weakSelf.finish()
            }
        }
    }
    
    // MARK: - 获取图片
    
    /// 获取需要下载或导出的缩略图
    /// - Throws: 抛出过程中产生的异常
    public func fetchThumbnailImage() throws {
        guard let mediaModel = self.mediaModel else {
            throw LGMediaModelError.mediaModelIsInvalid
        }
        
        if !mediaModel.isThumbnailImageValid {
            throw LGMediaModelError.unableToGetThumbnail
        }
        
        func downloadImageFromRemote() throws {
            guard let thumbnailImageURL = mediaModel.thumbnailImageURL else {
                throw LGMediaModelError.thumbnailURLIsInvalid
            }
            
            if isCancelled {
                return
            }
            
            let result = LGWebImageManager.default.downloadImageWith(url: thumbnailImageURL,
                                                                      options: LGWebImageOptions.default,
                                                                      progress:
                { [weak self] (progress) in
                    guard let strongSelf = self else {return}
                    if let progressBlock = strongSelf.progress {
                        progressBlock(progress)
                    }
            }) { [weak self] (resultImage, url, sourceType, imageStage, error) in
                guard let strongSelf = self else {return}
                strongSelf.mediaModel?.thumbnailImage = resultImage
                strongSelf.invokeThumbnailImageCompletionOnMainThread(resultImage,
                                                                      remoteURL: url,
                                                                      sourceType: sourceType,
                                                                      imageStage: imageStage,
                                                                      error: error)
            }
            self.thumbnailImageOperation = result.operation
        }
        
        func loadImageFromDisk() throws {
            if mediaModel.thumbnailImage == nil {
                var finalURL: URL?
                if let url = try mediaModel.thumbnailImageURL?.asURL() {
                    let absoluteString = url.absoluteString
                    // 正确的文件URL格式为 file://[path], 所以在转换后进行一次判断
                    if absoluteString.range(of: "://") != nil {
                        finalURL = url
                    } else {
                        finalURL = URL(fileURLWithPath: absoluteString)
                    }
                }
                
                if let finalURL = finalURL {
                    if isCancelled {
                        return
                    }
                    
                    let data = try Data(contentsOf: finalURL)
                    
                    if isCancelled {
                        return
                    }
                    
                    let image = LGImage.imageWith(data: data)
                    
                    if isCancelled {
                        return
                    }
                    
                    mediaModel.thumbnailImage = image
                    
                    self.invokeThumbnailImageCompletionOnMainThread(image,
                                                                    remoteURL: finalURL,
                                                                    sourceType: LGWebImageSourceType.diskCache,
                                                                    imageStage: LGWebImageStage.finished,
                                                                    error: nil)
                }
            } else {
                self.invokeThumbnailImageCompletionOnMainThread(mediaModel.thumbnailImage,
                                                                remoteURL: nil,
                                                                sourceType: LGWebImageSourceType.diskCache,
                                                                imageStage: LGWebImageStage.finished,
                                                                error: nil)
            }
        }
        
        func exportImageFromAsset() throws {
            guard let asset = mediaModel.mediaAsset else {
                throw LGMediaModelError.mediaAssetIsInvalid
            }
            let pixelSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            imageRequestId = LGPhotoManager.requestImage(forAsset: asset,
                                                         outputSize: fixedPixelSize(pixelSize),
                                                         isAsync: true,
                                                         resizeMode: PHImageRequestOptionsResizeMode.fast,
                                                         progressHandlder:
                { [weak self] (value, error, stop, info) in
                    guard let _ = self else {return}
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self, error == nil else {return}
                        let progress = Progress(totalUnitCount: totalUnitCount)
                        progress.completedUnitCount = Int64(Double(totalUnitCount) * value)
                        if let progressBlock = strongSelf.progress {
                            progressBlock(progress)
                        }
                    }
            }) { [weak self] (resultImage, info) in
                guard let strongSelf = self else {
                    return
                }
                
                if strongSelf.isCancelled {
                    return
                }
                
                strongSelf.mediaModel?.thumbnailImage = resultImage
                strongSelf.invokeThumbnailImageCompletionOnMainThread(resultImage,
                                                                      remoteURL: nil,
                                                                      sourceType: LGWebImageSourceType.diskCache,
                                                                      imageStage: LGWebImageStage.finished,
                                                                      error: nil)
            }
        }
        
        switch mediaModel.mediaPosition {
        case LGMediaModel.Position.remoteFile:
            try downloadImageFromRemote()
            break
        case LGMediaModel.Position.localFile:
            try loadImageFromDisk()
            break
        case LGMediaModel.Position.album:
            try exportImageFromAsset()
            break
        }
    }
    
    private func fixedPixelSize(_ size: CGSize) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width * UIScreen.main.scale
        let screenHeight = UIScreen.main.bounds.height * UIScreen.main.scale
        
        let aspectRatio = screenWidth / screenHeight
        
        if size.width / size.height > aspectRatio {
            let scale = size.height / screenHeight
            let resultWidth = size.width / scale
            return CGSize(width: resultWidth, height: screenHeight)
        } else {
            let scale = size.width / screenWidth
            let resultHeight = size.height / scale
            return CGSize(width: screenWidth, height: resultHeight)
        }
    }
    
    /// 获取要下载或导出的原始图片
    ///
    /// - Throws: 抛出过程中产生的异常
    public func fetchMediaImage() throws {
        guard let mediaModel = self.mediaModel else {
            throw LGMediaModelError.mediaModelIsInvalid
        }
        
        func downloadImageFromRemote() throws {
            guard let mediaURL = mediaModel.mediaURL else {
                throw LGMediaModelError.mediaURLIsInvalid
            }
            
            if isCancelled {
                return
            }
            
            let result = LGWebImageManager.default.downloadImageWith(url: mediaURL,
                                                                     options: LGWebImageOptions.default,
                                                                     progress:
                { [weak self] (progress) in
                    guard let strongSelf = self else {return}
                    if let progressBlock = strongSelf.progress {
                        progressBlock(progress)
                    }
            }) { [weak self] (resultImage, url, sourceType, imageStage, error) in
                guard let strongSelf = self else {return}
                if strongSelf.isCancelled {return}
                strongSelf.mediaModel?.thumbnailImage = resultImage
                strongSelf.invokeMediaImageCompletionOnMainThread(resultImage,
                                                                  remoteURL: url,
                                                                  sourceType: sourceType,
                                                                  imageStage: imageStage,
                                                                  error: error)
            }
            self.mediaImageOperation = result.operation
        }
        
        func loadImageFromDisk() throws {
            if self.mediaModel?.thumbnailImage == nil {
                var finalURL: URL?
                if let url = try mediaModel.mediaURL?.asURL() {
                    let absoluteString = url.absoluteString
                    // 正确的文件URL格式为 file://[path], 所以在转换后进行一次判断
                    if absoluteString.range(of: "://") != nil {
                        finalURL = url
                    } else {
                        finalURL = URL(fileURLWithPath: absoluteString)
                    }
                }
                
                if let finalURL = finalURL {
                    if isCancelled {
                        return
                    }
                    let data = try Data(contentsOf: finalURL)
                    
                    if isCancelled {
                        return
                    }
                    let image = LGImage.imageWith(data: data)
                    
                    mediaModel.thumbnailImage = image
                    self.invokeMediaImageCompletionOnMainThread(image,
                                                                remoteURL: finalURL,
                                                                sourceType: LGWebImageSourceType.diskCache,
                                                                imageStage: LGWebImageStage.finished,
                                                                error: nil)
                }
            }
        }

        func exportImageFromAsset() throws {
            guard let asset = mediaModel.mediaAsset else {
                throw LGMediaModelError.mediaAssetIsInvalid
            }
            
            if #available(iOS 11.0, *) {
                if asset.playbackStyle == .imageAnimated {
                    imageRequestId = LGPhotoManager.requestImageData(for: asset,
                                                                      resizeMode: PHImageRequestOptionsResizeMode.fast,
                                                                      progressHandler:
                        { (progressValue, error, stoped, infoDic) in
                            DispatchQueue.main.async { [weak self] in
                                guard let weakSelf = self else {return}
                                if weakSelf.isCancelled {
                                    return
                                }
                                if error == nil {
                                    let progress = Progress(totalUnitCount: totalUnitCount)
                                    progress.completedUnitCount = Int64(Double(totalUnitCount) * progressValue)
                                    if let progressBlock = weakSelf.progress {
                                        progressBlock(progress)
                                    }
                                }
                            }
                    }) { [weak self] (imageData, dataUTI, orientation, infoDic) in
                        guard let imageData = imageData, let strongSelf = self else {return}
                        if strongSelf.isCancelled {
                            return
                        }
                        
                        let image = LGImage.imageWith(data: imageData)
                        
                        mediaModel.thumbnailImage = image
                        strongSelf.invokeMediaImageCompletionOnMainThread(image,
                                                                          remoteURL: nil,
                                                                          sourceType: LGWebImageSourceType.diskCache,
                                                                          imageStage: LGWebImageStage.finished,
                                                                          error: nil)
                    }
                    return
                }
            }
            
            let pixelSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            
            imageRequestId = LGPhotoManager.requestImage(forAsset: asset,
                                                         outputSize: fixedPixelSize(pixelSize),
                                                         resizeMode: PHImageRequestOptionsResizeMode.fast,
                                                         progressHandlder:
                { (value, error, stop, info) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        if weakSelf.isCancelled {
                            return
                        }
                        if error == nil {
                            let progress = Progress(totalUnitCount: totalUnitCount)
                            progress.completedUnitCount = Int64(Double(totalUnitCount) * value)
                            if let progressBlock = weakSelf.progress {
                                progressBlock(progress)
                            }
                        }
                    }
            }) { [weak self] (resultImage, info) in
                guard let strongSelf = self else {return}
                if strongSelf.isCancelled {return}
                strongSelf.mediaModel?.thumbnailImage = resultImage
                strongSelf.invokeMediaImageCompletionOnMainThread(resultImage,
                                                                  remoteURL: nil,
                                                                  sourceType: .diskCache,
                                                                  imageStage: LGWebImageStage.finished,
                                                                  error: nil)
            }
        }
        
        switch mediaModel.mediaPosition {
        case .remoteFile:
            try downloadImageFromRemote()
            break
        case .localFile:
            try loadImageFromDisk()
            break
        case .album:
            try exportImageFromAsset()
            break
        }
    }
    
    /// 获取PHLivePhoto，分别从本地URL，服务器，相册三种获取并合成
    ///
    /// - Throws: 过程中产生的异常
    @available(iOS 9.1, *)
    public func fetchLivePhoto() throws {
        guard let mediaModel = self.mediaModel else {
            throw LGMediaModelError.mediaModelIsInvalid
        }
        
        func fetchLivePhotoFromAlbumAsset() {
            guard let asset = mediaModel.mediaAsset else { return }
            let options = PHLivePhotoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { (progress, error, stoped, infoDic) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else {return}
                    if weakSelf.isCancelled {return}
                    let total: Int64 = totalUnitCount
                    let result = Progress(totalUnitCount: total)
                    result.completedUnitCount = Int64(Double(totalUnitCount) * progress)
                    weakSelf.progress?(result)
                }
            }
            
            let pixelSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            imageRequestId = LGPhotoManager.imageManager.requestLivePhoto(for: asset,
                                                                          targetSize: fixedPixelSize(pixelSize),
                                                                          contentMode: PHImageContentMode.aspectFill,
                                                                          options: options)
            { [weak self] (livePhoto, infoDic) in
                guard let weakSelf = self else {return}
                if weakSelf.isCancelled {return}
                
                let error = infoDic?[PHImageErrorKey] as? Error
                weakSelf.invokeLivePhotoCompletionOnMainThread(livePhoto, isFinished: true, error: error)
            }
        }
        
        func fetchLivePhoto(withThumbnailImageURL thumbnailImageURL: URL,
                            mediaURL: URL,
                            placeholderImage: UIImage?)
        {
            livePhotoRequestId = PHLivePhoto.request(withResourceFileURLs: [thumbnailImageURL, mediaURL],
                                                     placeholderImage: placeholderImage,
                                                     targetSize: placeholderImage?.size ?? CGSize.zero,
                                                     contentMode: PHImageContentMode.aspectFill)
            { [weak self] (resultPhoto, infoDic) in
                guard let weakSelf = self else { return }
                if weakSelf.isCancelled {return}
                let error = infoDic[PHImageErrorKey] as? Error
                weakSelf.invokeLivePhotoCompletionOnMainThread(resultPhoto,
                                                               isFinished: true,
                                                               error: error)
            }
        }
        
        func fetchLivePhotoFromLocalFile() {
            do {
                if let thumbnailImageURL = try mediaModel.thumbnailImageURL?.asURL(),
                    let movieFileURL = try mediaModel.mediaURL?.asURL(),
                    FileManager.default.fileExists(atPath: thumbnailImageURL.path),
                    FileManager.default.fileExists(atPath: movieFileURL.path)
                {
                    var placeholderImage = mediaModel.thumbnailImage
                    if placeholderImage == nil {
                        placeholderImage = UIImage(contentsOfFile: thumbnailImageURL.path)
                    }
                    fetchLivePhoto(withThumbnailImageURL: thumbnailImageURL,
                                   mediaURL: movieFileURL,
                                   placeholderImage: placeholderImage)
                } else {
                    self.invokeLivePhotoCompletionOnMainThread(nil,
                                                               isFinished: true,
                                                               error: LGMediaModelError.mediaURLIsInvalid)
                }
            } catch {
                self.invokeLivePhotoCompletionOnMainThread(nil,
                                                           isFinished: true,
                                                           error: error)
            }
        }
        
        func fetchLivePhotoFromRemoteFile() {
            do {
                if let thumbnailImageURL = try mediaModel.thumbnailImageURL?.asURL(),
                    let movieFileURL = try mediaModel.mediaURL?.asURL()
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
                        var placeholderImage = mediaModel.thumbnailImage
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
                                if self.isCancelled {return}
                                let total: Int64 = totalUnitCount
                                let result = Progress(totalUnitCount: total)
                                result.completedUnitCount = Int64(Double(totalUnitCount) * (totalProgress / 2.0))
                                DispatchQueue.main.async { [weak self] in
                                    self?.progress?(result)
                                }
                            }
                        }
                        
                        let thumbResult = LGFileDownloader.default.downloadFile(thumbnailImageURL,
                                                                           progress:
                            { (progress) in
                            totalProgress += progress.fractionCompleted
                        }) { [weak self] (destinationURL, isDownloadCompleted, error) in
                            if !isDownloadCompleted {
                                guard let weakSelf = self else {
                                    return
                                }
                                weakSelf.invokeLivePhotoCompletionOnMainThread(nil, isFinished: true, error: error)
                                return
                            }
                            synchronizeMark += 1
                        }
                        
                        self.thumbnailImageDownloadOperation = thumbResult.operation
                        
                  
                        let fileDownloadResult = LGFileDownloader.default.downloadFile(movieFileURL,
                                                                                    progress:
                            { (progress) in
                                totalProgress += progress.fractionCompleted
                        }) { [weak self] (destinationMovieURL, isDownloadCompleted, error) in
                            if !isDownloadCompleted {
                                guard let weakSelf = self else {
                                    return
                                }
                                weakSelf.invokeLivePhotoCompletionOnMainThread(nil, isFinished: true, error: error)
                                return
                            }
                            synchronizeMark += 1
                        }
                        
                        self.fileDownloadOperation = fileDownloadResult.operation
                    }
                } else {
                    self.invokeLivePhotoCompletionOnMainThread(nil,
                                                               isFinished: true,
                                                               error: LGMediaModelError.mediaURLIsInvalid)
                }
            } catch {
                self.invokeLivePhotoCompletionOnMainThread(nil, isFinished: true, error: error)
            }
        }
        
        switch mediaModel.mediaPosition {
        case .remoteFile:
            fetchLivePhotoFromRemoteFile()
            break
        case .localFile:
            fetchLivePhotoFromLocalFile()
            break
        case .album:
            fetchLivePhotoFromAlbumAsset()
            break
        }
    }
    
    /// 获取AVPlayerItem，用于视频播放，内部分本地，远程和相册进行处理
    ///
    /// - Throws: 过程中产生的异常
    public func fetchMoviePlayerItem() throws {
        guard let mediaModel = self.mediaModel else {
            throw LGMediaModelError.mediaModelIsInvalid
        }
        
        func fetchLocalVideo() throws {
            if let url = try mediaModel.mediaURL?.asURL() {
                let playerItem = AVPlayerItem(url: url)
                self.invokeVideoCompletionOnMainThread(playerItem, isFinished: true, error: nil)
            }
        }
        
        func fetchRemoteVideo() throws {
            if let url = try mediaModel.mediaURL?.asURL() {
                if globalConfigs.isPlayVideoAfterDownloadEndsOrExportEnds &&
                    !LGFileDownloader.default.remoteURLIsDownloaded(url)
                {
                    let movieDownloadResult = LGFileDownloader.default.downloadFile(url,
                                                                                progress:
                        { (progress) in
                            DispatchQueue.main.async { [weak self] in
                                guard let weakSelf = self else {return}
                                if weakSelf.isCancelled {return}
                                if let progressBlock = weakSelf.progress {
                                    progressBlock(progress)
                                }
                            }
                    }) { [weak self] (destinationURL, isDownloadCompleted, error) in
                        guard let weakSelf = self else {
                            return
                        }
                        if weakSelf.isCancelled {return}
                        
                        if let destinationURL = destinationURL, isDownloadCompleted {
                            let playerItem = AVPlayerItem(url: destinationURL)
                            weakSelf.invokeVideoCompletionOnMainThread(playerItem, isFinished: true, error: nil)
                        } else {
                            weakSelf.invokeVideoCompletionOnMainThread(nil, isFinished: true, error: error)
                        }
                            
                    }
                    self.fileDownloadOperation = movieDownloadResult.operation
                } else {
                    let destinationURL = URL(fileURLWithPath: LGFileDownloader.Helper.filePath(withURL: url))
                    let playerItem = AVPlayerItem(url: destinationURL)
                    self.invokeVideoCompletionOnMainThread(playerItem, isFinished: true, error: nil)
                }
            }
        }
        
        func fetchAlbumVideo() {
            if let asset = mediaModel.mediaAsset {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.progressHandler = {(progress, error, stop, infoDic) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        let progressValue = Progress(totalUnitCount: totalUnitCount)
                        progressValue.completedUnitCount = Int64(Double(totalUnitCount) * progress)
                        weakSelf.progress?(progressValue)
                    }
                }
                
                imageRequestId = LGPhotoManager.imageManager.requestAVAsset(forVideo: asset,
                                                                             options: options)
                { (avAsset, audioMix, infoDic) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {
                            return
                        }
                        
                        if weakSelf.isCancelled {return}
                        
                        guard let avAsset = avAsset else {
                            let error = infoDic?[PHImageErrorKey] as? Error
                            weakSelf.invokeVideoCompletionOnMainThread(nil, isFinished: true, error: error)
                            return
                        }
                        let playerItem = AVPlayerItem(asset: avAsset)
                        weakSelf.invokeVideoCompletionOnMainThread(playerItem, isFinished: true, error: nil)
                    }
                }
            } else {
                self.invokeVideoCompletionOnMainThread(nil, isFinished: true, error: LGMediaModelError.mediaModelIsInvalid)
            }
        }
        
        switch mediaModel.mediaPosition {
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
    
    open override func cancel() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if !isCancelled {
            super.cancel()
            isCancelled = true
            
            if isExecuting {
                isExecuting = false
            }
            cancelOperation()
        }
        
        if isStarted {
            isFinished = true
        }
    }
    
    override open class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        if key == "isExecuting" || key == "isFinished" || key == "isCancelled" {
            return false
        } else {
            return super.automaticallyNotifiesObservers(forKey: key)
        }
    }
    
    // MARK: - private
    
    func finish() {
        isExecuting = false
        isFinished = true
        endBackgroundTask()
    }
    
    private func cancelOperation() {
        autoreleasepool { () -> Void in
            endBackgroundTask()
            self.thumbnailImageOperation?.cancel()
            self.mediaImageOperation?.cancel()
            self.fileDownloadOperation?.cancel()
            self.thumbnailImageDownloadOperation?.cancel()
            
            if imageRequestId != PHInvalidImageRequestID {
                LGPhotoManager.imageManager.cancelImageRequest(imageRequestId)
            }
            
            if livePhotoRequestId != PHLivePhotoRequestIDInvalid {
                PHLivePhoto.cancelRequest(withRequestID: livePhotoRequestId)
            }
        }
    }
    
    private func endBackgroundTask() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if self.taskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(self.taskId)
            self.taskId = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // MARK: - 销毁
    deinit {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if isExecuting {
            cancelOperation()
            isCancelled = true
            isFinished = true
        }
    }
}
