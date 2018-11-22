//
//  LGLivePhotoView.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/11/20.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import PhotosUI
import Photos


open class LGLivePhotoView: UIView, LGMediaPreviewerProtocol {
    public var mediaModel: LGMediaModel! {
        didSet {
            refreshLayout()
        }
    }
    
    public var livePhotoMarkFrame: CGRect = CGRect.zero
    
    var livePhotoView: UIView!
    
    var livePhotoMarkView: UIImageView!
    
    lazy var progressView: LGSectorProgressView = {
        let temp = LGSectorProgressView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return temp
    }()
    
    public required convenience init(frame: CGRect, mediaModel: LGMediaModel) {
        self.init(frame: frame)
        self.mediaModel = mediaModel
        refreshLayout()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefault()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefault()
    }
    
    func setupDefault() {
        if #available(iOS 9.1, *) {
            livePhotoView = PHLivePhotoView(frame: CGRect.zero)
        } else {
            livePhotoView = UIImageView(frame: CGRect.zero)
        }
        livePhotoView.contentMode = UIView.ContentMode.scaleAspectFill
        livePhotoView.clipsToBounds = true
        self.addSubview(livePhotoView)
        
        livePhotoMarkView = UIImageView(frame: livePhotoMarkFrame)
        livePhotoMarkView.contentMode = UIView.ContentMode.scaleAspectFill
        self.addSubview(livePhotoMarkView)
        
        if #available(iOS 9.1, *) {
            livePhotoMarkView.image = PHLivePhotoView.livePhotoBadgeImage(options: PHLivePhotoBadgeOptions.overContent)
        } else {
            livePhotoMarkView.image = UIImage(namedFromThisBundle: "mark_livePhoto")
        }
        
        self.addSubview(progressView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        livePhotoMarkView.frame = self.livePhotoMarkFrame
    }
    
    func refreshLayout() {
        self.progressView.center = self.center
        guard let mediaModel = self.mediaModel else {return}
        do {
            if #available(iOS 9.1, *) {
                try mediaModel.fetchLivePhoto(withProgress:
                { [weak self] (progress, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel.identify == identify else {return}
                    weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
                }, completion: { [weak self] (livePhoto, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel.identify == identify else {return}

                    
                    guard let livePhoto = livePhoto,
                        let livePhotoView = weakSelf.livePhotoView as? PHLivePhotoView,
                        weakSelf.isShown else
                    {
                        weakSelf.progressView.isShowError = true
                        return
                    }
                    livePhotoView.livePhoto = livePhoto
                    livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                    weakSelf.progressView.isHidden = true
                    weakSelf.fixViewFrame()
                })
            } else {
                try mediaModel.fetchThumbnailImage(withProgress:
                { [weak self] (progress, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel.identify == identify else {return}
                    weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
                }, completion: { [weak self] (resultImage, identify) in
                    guard let weakSelf = self, weakSelf.mediaModel.identify == identify else {return}
                    if let livePhotoView = weakSelf.livePhotoView as? UIImageView,
                        let resultImage = resultImage {
                        livePhotoView.image = resultImage
                        weakSelf.progressView.isHidden = true
                        weakSelf.fixViewFrame()
                    } else {
                        weakSelf.progressView.isShowError = true
                    }
                })
            }
        } catch {
            self.progressView.isShowError = true
        }
    }
    
    func fixViewFrame() {
        var finalSize: CGSize
        if #available(iOS 9.1, *) {
            if let thumbnailImage = self.mediaModel.thumbnailImage {
                finalSize = thumbnailImage.size
            } else if let livePhoto = (self.livePhotoView as? PHLivePhotoView)?.livePhoto {
                finalSize = livePhoto.size
            } else {
                finalSize = self.lg_size
            }
        } else {
            if let thumbnailImage = self.mediaModel.thumbnailImage {
                finalSize = thumbnailImage.size
            }  else {
                finalSize = self.lg_size
            }
        }
        
        finalSize = calcFinalImageSize(finalSize)
        
        self.livePhotoView.frame = CGRect(origin: CGPoint(x: 0, y: (self.lg_height - finalSize.height) / 2.0),
                                          size: finalSize)
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
    
    var isShown: Bool = true
    
    func willAppear() {
    }
    
    func didDisappear() {
        stopPlay()
    }
    
    func stopPlay() {
        if #available(iOS 9.1, *) {
            if let livePhotoView = self.livePhotoView as? PHLivePhotoView {
                livePhotoView.stopPlayback()
            }
        } else {
            if let imageView = self.livePhotoView as? UIImageView {
                imageView.image = nil
            }
        }
    }
}
