//
//  LGForceTouchPreviewController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/16.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import LGWebImage
import PhotosUI
import Photos

open class LGForceTouchPreviewController: UIViewController {
    public var mediaModel: LGMediaModel?
    public var currentIndex: Int = 0
    
    var requestId: PHImageRequestID = 0
    
    lazy var imageView: LGAnimatedImageView = {
        let temp = LGAnimatedImageView(frame: CGRect.zero)
        temp.contentMode = UIView.ContentMode.scaleAspectFill
        temp.clipsToBounds = true
        return temp
    }()
    
    lazy var progressView: LGSectorProgressView = {
        let temp = LGSectorProgressView(frame: CGRect.zero)
        return temp
    }()
    
    @available(iOS 9.1, *)
    lazy var livePhotoView: PHLivePhotoView = {
        let temp = PHLivePhotoView(frame: CGRect.zero)
        temp.clipsToBounds = true
        temp.contentMode = UIView.ContentMode.scaleAspectFill
        return temp
    }()
    
    lazy var playerView: LGPlayerView? = {
        if let model = self.mediaModel {
            let temp = LGPlayerView(frame: self.view.bounds, mediaModel: model)
            return temp
        } else {
            return nil
        }
    }()
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(mediaModel: LGMediaModel, currentIndex: Int) {
        self.init(nibName: nil, bundle: nil)
        self.mediaModel = mediaModel
        self.currentIndex = currentIndex
        
        if let image = self.mediaModel?.thumbnailImage {
            self.preferredContentSize = calcfinalImageSize(image.size)
        }
    }
    
    func calcfinalImageSize(_ finalImageSize: CGSize) -> CGSize {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let imageWidth = finalImageSize.width
        var imageHeight = finalImageSize.height
        
        var resultWidth: CGFloat
        var resultHeight: CGFloat
        imageHeight = width / imageWidth * imageHeight
        if imageHeight > height {
            resultWidth = height / finalImageSize.height * imageWidth
            resultHeight = height
        } else {
            resultWidth = width
            resultHeight = imageHeight
        }
        return CGSize(width: resultWidth, height: resultHeight)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubViews()
    }
    
    func setupSubViews() {
        self.progressView.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        self.view.addSubview(self.progressView)
        self.progressView.center = self.view.center
        if let model = self.mediaModel {
            switch model.mediaType {
            case .generalPhoto:
                setupGeneralPhotoView()
                break
            case .livePhoto:
                setupLivePhotoView()
                break
            case .video:
                setupVideoView()
                break
            case .audio:
                setupAudioView()
                break
            default:
                break
            }
        } else {
            self.progressView.isShowError = true
            self.view.bringSubviewToFront(self.progressView)
        }
    }
    
    func setupGeneralPhotoView() {
        self.view.addSubview(self.imageView)
        self.view.bringSubviewToFront(self.progressView)
        guard let mediaModel = self.mediaModel else {
            self.progressView.isShowError = true
            return
        }

        func setImageWithRemoteURL() {
            do {
                guard let url = try mediaModel.mediaURL?.asURL() else {
                    self.progressView.isShowError = true
                    return
                }

                self.imageView.lg_setImageWithURL(url,
                                                  placeholder: nil,
                                                  options: LGWebImageOptions.default,
                                                  progressBlock:
                    {[weak self] (progress) in
                        self?.progressView.progress = CGFloat(progress.fractionCompleted)
                    }, transformBlock: nil)
                {[weak self] (resultImage, imageURL, sourceType, imageStage, error) in
                    guard let weakSelf = self else { return }
                    if error == nil, let resultImage = resultImage {
                        weakSelf.progressView.isHidden = true
                        weakSelf.preferredContentSize = weakSelf.calcfinalImageSize(resultImage.size)
                    } else {
                        weakSelf.progressView.isShowError = true
                    }
                }
            } catch {
                println(error)
            }

        }

        func setImageWithLocalFile() {
            do {
                guard var url = try mediaModel.mediaURL?.asURL() else {
                    self.progressView.isShowError = true
                    return
                }

                if url.absoluteString.range(of: "://") == nil {
                    url = URL(fileURLWithPath: url.absoluteString)
                }

                DispatchQueue.userInitiated.async {
                    do {
                        let data = try Data(contentsOf: url)
                        let image = LGImage.imageWith(data: data)
                        DispatchQueue.main.async { [weak self] in
                            guard let weakSelf = self else { return }
                            weakSelf.imageView.image = image
                        }
                    } catch {
                        println(error)
                    }
                }
            } catch {
                println(error)
            }
        }

        func setImageWithAlbumAsset() {
            guard let asset = self.mediaModel?.mediaAsset else {
                self.progressView.isShowError = true
                return
            }

            self.progressView.isHidden = true
            if let tempImage = self.mediaModel?.thumbnailImage {
                self.imageView.image = tempImage
            }

            DispatchQueue.utility.async {
                PHCachingImageManager.default().requestImageData(for: asset,
                                                                 options: nil)
                { [weak self] (imageData, dataUTI, imageOrientation, infoDic) in
                    guard let data = imageData else { return }
                    let image = LGImage.imageWith(data: data)

                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.imageView.image = image
                    }
                }
            }
        }

        switch mediaModel.mediaPosition {
        case .localFile:
            setImageWithLocalFile()
            break
        case .remoteFile:
            setImageWithRemoteURL()
            break
        case .album:
            setImageWithAlbumAsset()
            break
        }
    }
    
    func setupLivePhotoView() {
        if #available(iOS 9.1, *) {
            self.view.addSubview(livePhotoView)
            livePhotoView.frame = self.view.bounds
            guard let mediaModel = self.mediaModel else { return }

            func setLivePhotoWithAlbumAsset() {
                guard let asset = mediaModel.mediaAsset else { return }
                let options = PHLivePhotoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.progressHandler = { (progress, error, stoped, infoDic) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        weakSelf.progressView.progress = CGFloat(progress)
                    }
                }
                LGPhotoManager.imageManager.requestLivePhoto(for: asset,
                                                             targetSize: CGSize(width: asset.pixelWidth,
                                                                                height: asset.pixelHeight),
                                                             contentMode: PHImageContentMode.aspectFill,
                                                             options: options)
                { [weak self] (livePhoto, infoDic) in
                    guard let weakSelf = self else { return }
                    guard let livePhoto = livePhoto  else { return }
                    weakSelf.livePhotoView.livePhoto = livePhoto
                    weakSelf.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                }
            }
            
            func playLivePhoto(withThumbnailImageURL thumbnailImageURL: URL,
                               mediaURL: URL,
                               placeholderImage: UIImage?)
            {
                PHLivePhoto.request(withResourceFileURLs: [thumbnailImageURL, mediaURL],
                                    placeholderImage: placeholderImage,
                                    targetSize: placeholderImage?.size ?? CGSize.zero,
                                    contentMode: PHImageContentMode.aspectFill)
                { [weak self]  (resultPhoto, infoDic) in
                    guard let weakSelf = self else { return }
                    guard let livePhoto = resultPhoto  else { return }
                    weakSelf.livePhotoView.livePhoto = livePhoto
                    weakSelf.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                    weakSelf.progressView.isHidden = true
                }
            }
            
            func setLivePhotoWithLocalFile() {
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
                        playLivePhoto(withThumbnailImageURL: thumbnailImageURL,
                                      mediaURL: movieFileURL,
                                      placeholderImage: placeholderImage)
                    } else {
                        self.progressView.isShowError = true
                    }
                } catch {
                    println(error)
                    self.progressView.isShowError = true
                }
            }
            
            func setLivePhotoWithRemoteFile() {
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
                            
                            playLivePhoto(withThumbnailImageURL: URL(fileURLWithPath: destinationImageURL),
                                          mediaURL: URL(fileURLWithPath: destinationMovieFileURL),
                                          placeholderImage: placeholderImage)
                        } else {
                            
                            LGFileDownloader.default.downloadFile(thumbnailImageURL,
                                                                  progress: { (progress) in
                                                                    
                            }) { (destinationImageURL, isDownloadCompleted, error) in
                                
                            }
                            
                            LGFileDownloader.default.downloadFile(movieFileURL,
                                                                  progress: { (progress) in
                                                                    
                            }) { (destinationImageURL, isDownloadCompleted, error) in
                                
                            }
                        }
                        
                    } else {
                        self.progressView.isShowError = true
                    }
                } catch {
                    println(error)
                    self.progressView.isShowError = true
                }
            }

            switch mediaModel.mediaPosition {
            case .localFile:
                setLivePhotoWithLocalFile()
                break
            case .remoteFile:
                setLivePhotoWithRemoteFile()
                break
            case .album:
                setLivePhotoWithAlbumAsset()
                break
            }
        }
    }
    
    func setupVideoView() {
        guard let mediaModel = self.mediaModel else { return }
        
        func playLocalVideo() {
            do {
                if let url = try mediaModel.mediaURL?.asURL() {
                    playVideo(withURL: url)
                }
            } catch {
                println(error)
                self.progressView.isShowError = true
            }
        }
        
        func playVideo(withURL url: URL) {
            self.playerView = LGPlayerView(frame: self.view.bounds,
                                               mediaPlayerItem: AVPlayerItem(url: url),
                                               isMuted: false)
            self.view.addSubview(self.playerView!)
            self.playerView?.play()
            self.progressView.isHidden = true
        }
        
        func playRemoteVideo() {
            do {
                if let url = try mediaModel.mediaURL?.asURL() {
                    if globalConfigs.isPlayVideoAfterDownloadEndsOrExportEnds &&
                        !LGFileDownloader.default.remoteURLIsDownloaded(url)
                    {
                        LGFileDownloader.default.downloadFile(url,
                                                              progress: { (progress) in
                                                                
                        }) { (destinationURL, isDownloadCompleted, error) in
                            DispatchQueue.main.async { [weak self] in
                                guard let weakSelf = self else {return}
                                
                                if !isDownloadCompleted {
                                    weakSelf.progressView.isShowError = true
                                    return
                                }
                                
                                playVideo(withURL: url)
                            }
                        }
                    } else {
                        playVideo(withURL: url)
                    }
                }
            } catch {
                println(error)
                self.progressView.isShowError = true
            }
            
        }
        
        func playAlbumVideo() {
            if let asset = mediaModel.mediaAsset {
                self.view.bringSubviewToFront(self.progressView)
                
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.progressHandler = {(progress, error, stop, infoDic) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.progressView.progress = CGFloat(progress)
                    }
                }
                
                LGPhotoManager.imageManager.requestAVAsset(forVideo: asset,
                                                           options: options)
                { (avAsset, audioMix, infoDic) in
                    guard let avAsset = avAsset else { return }
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.playerView = LGPlayerView(frame: weakSelf.view.bounds,
                                                           mediaPlayerItem: AVPlayerItem(asset: avAsset),
                                                           isMuted: false)
                        weakSelf.view.addSubview(weakSelf.playerView!)
                        weakSelf.playerView?.play()
                        weakSelf.progressView.isHidden = true
                    }
                }
            } else {
                self.progressView.isShowError = true
            }
        }
        
        switch mediaModel.mediaPosition {
        case .localFile:
            playLocalVideo()
            break
        case .remoteFile:
            playRemoteVideo()
            break
        case .album:
            playAlbumVideo()
            break
        }
    }
    
    func setupAudioView() {
        
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let model = self.mediaModel {
            switch model.mediaType {
            case .generalPhoto:
                fixGeneralPhotoViewFrame()
                break
            case .livePhoto:
                fixLivePhotoViewFrame()
                break
            case .video:
                fixVideoViewFrame()
                break
            case .audio:
                fixAudioViewFrame()
                break
            default:
                break
            }
        }
        
    }
    
    func fixGeneralPhotoViewFrame() {
        self.imageView.frame = self.view.bounds
        self.progressView.center = self.view.center
    }
    
    func fixLivePhotoViewFrame() {
        self.imageView.frame = self.view.bounds
        self.progressView.center = self.view.center
    }
    
    func fixVideoViewFrame() {
        self.imageView.frame = self.view.bounds
        self.progressView.center = self.view.center
    }
    
    func fixAudioViewFrame() {
        self.imageView.frame = self.view.bounds
        self.progressView.center = self.view.center
    }
}
