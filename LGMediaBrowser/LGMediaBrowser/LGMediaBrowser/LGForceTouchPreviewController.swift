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
            self.preferredContentSize = calcFinalImageSize(image.size)
        }
    }
    
    func calcFinalImageSize(_ finalImageSize: CGSize) -> CGSize {
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
        
        do {
            self.progressView.isHidden = false
            self.progressView.isShowError = false
            
            try mediaModel.fetchImage(withProgress:
                { [weak self] (progress, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel?.identify == identify else {return}
                    weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
            }) { [weak self] (resultImage, hashValue) in
                guard let weakSelf = self, weakSelf.mediaModel?.identify == hashValue else { return }
                if let resultImage = resultImage {
                    weakSelf.progressView.isHidden = true
                    weakSelf.imageView.image = resultImage
                    weakSelf.preferredContentSize = weakSelf.calcFinalImageSize(resultImage.size)
                } else {
                    weakSelf.progressView.isShowError = true
                }
            }
        } catch {
            self.progressView.isShowError = true
        }
    }
    
    func setupLivePhotoView() {
        if #available(iOS 9.1, *) {
            self.view.addSubview(livePhotoView)
            self.view.bringSubviewToFront(self.progressView)
            livePhotoView.frame = self.view.bounds
            guard let mediaModel = self.mediaModel else { return }

            do {
                try mediaModel.fetchLivePhoto(withProgress: { [weak self] (progress, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel?.identify == identify else {return}
                    weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
                }, completion: { [weak self] (livePhoto, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel?.identify == identify else { return }
                    guard let livePhoto = livePhoto  else {
                        weakSelf.progressView.isShowError = true
                        return
                    }
                    weakSelf.progressView.isHidden = true
                    weakSelf.livePhotoView.livePhoto = livePhoto
                    weakSelf.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                    weakSelf.preferredContentSize = weakSelf.calcFinalImageSize(livePhoto.size)
                })
            } catch {
                self.progressView.isShowError = true
            }
        } else {
            self.progressView.isShowError = true
        }
    }
    
    func setupVideoView() {
        guard let mediaModel = self.mediaModel else { return }
        self.view.addSubview(imageView)
        imageView.image = mediaModel.thumbnailImage
        fixGeneralPhotoViewFrame()
        
        func playVideo(withItem item: AVPlayerItem) {
            self.playerView = LGPlayerView(frame: self.view.bounds,
                                           mediaPlayerItem: item,
                                           isMuted: false)
            self.view.addSubview(self.playerView!)
            self.playerView?.play()
            self.progressView.isHidden = true
        }
        
        do {
            try mediaModel.fetchMoviePlayerItem(withProgress:
            { [weak self] (progress, identify) in
                guard let weakSelf = self, weakSelf.mediaModel?.identify == identify else { return }
                weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
            }) { [weak self] (resultItem, identify) in
                guard let weakSelf = self, weakSelf.mediaModel?.identify == identify else { return }
                if let resultItem = resultItem {
                    playVideo(withItem: resultItem)
                    if let size = weakSelf.mediaModel?.thumbnailImage?.size {
                        weakSelf.preferredContentSize = weakSelf.calcFinalImageSize(size)
                    }
                } else {
                    weakSelf.progressView.isShowError = true
                }
            }
        } catch {
            self.progressView.isShowError = true
        }
    }
    
    func setupAudioView() {
        // 没有实际应用场景，暂不开发
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        fixSubViewFrame()
    }
    
    func fixSubViewFrame() {
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
        if #available(iOS 9.1, *) {
            guard let livePhotoSize = self.livePhotoView.livePhoto?.size else {return}
            let size = calcFinalImageSize(livePhotoSize)
            let frame = CGRect(origin: CGPoint(x: 0,
                                               y: (self.view.lg_height - size.height) / 2.0),
                               size: size)
            self.livePhotoView.frame = frame
            self.progressView.center = self.view.center
        } else {
        }
    }
    
    func getSizeWith(mediaModel: LGMediaModel?) -> CGSize {
        guard let asset  = mediaModel?.mediaAsset else {return CGSize.zero}
        var width = min(CGFloat(asset.pixelWidth),
                        self.view.lg_width)
        var height = width * CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
        
        if height.isNaN { return CGSize.zero }
        
        if height > self.view.lg_height {
            height = self.view.lg_height
            width = height * CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
        }
        
        return CGSize(width: width, height: height)
    }
    
    
    func fixVideoViewFrame() {
        self.imageView.frame = self.view.bounds
        self.playerView?.frame = self.view.bounds
        self.progressView.center = self.view.center
    }
    
    func fixAudioViewFrame() {
        self.imageView.frame = self.view.bounds
        self.progressView.center = self.view.center
    }
}
