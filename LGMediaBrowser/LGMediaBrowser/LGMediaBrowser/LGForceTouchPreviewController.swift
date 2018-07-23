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
        do {
            if let model = self.mediaModel {
                let temp = try LGPlayerView(frame: self.view.bounds, mediaModel: model)
                return temp
            }
            return nil
        } catch {
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
        
        
        if let url = self.mediaModel?.mediaLocation.toURL() {
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
        } else if let asset = self.mediaModel?.mediaLocation.toAsset() {
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

        } else {
            self.progressView.isShowError = true
        }
    }
    
    func setupLivePhotoView() {
        if #available(iOS 9.1, *) {
            self.view.addSubview(livePhotoView)
            livePhotoView.frame = self.view.bounds
            if let asset = self.mediaModel?.mediaLocation.toAsset() {
                PHCachingImageManager.default().requestLivePhoto(for: asset,
                                                                 targetSize: CGSize(width: asset.pixelWidth,
                                                                                    height: asset.pixelHeight),
                                                                 contentMode: PHImageContentMode.aspectFill,
                                                                 options: nil)
                {[weak self] (livePhoto, infoDic) in
                    guard let weakSelf = self else { return }
                    guard let livePhoto = livePhoto  else { return }
                    weakSelf.livePhotoView.livePhoto = livePhoto
                    weakSelf.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                }
            }
        }
    }
    
    func setupVideoView() {
        guard let mediaModel = self.mediaModel else { return }

        if let playerView = self.playerView {
            self.view.addSubview(playerView)
            playerView.play()
            return
        }
        
        if mediaModel.isLocalFile {
            if let asset = mediaModel.mediaLocation.toAsset() {
                
                self.view.bringSubviewToFront(self.progressView)
                
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.progressHandler = {[weak self] (progress, error, stop, infoDic) in
                    guard let weakSelf = self else { return }
                    weakSelf.progressView.progress = CGFloat(progress)
                }
                
                PHCachingImageManager.default().requestAVAsset(forVideo: asset,
                                                               options: options)
                {(avAsset, audioMix, infoDic) in
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
            }
        } else {
            
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
