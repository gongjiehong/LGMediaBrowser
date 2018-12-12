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
    
    
    lazy var mediaSetter: LGMediaModelFetchSetter = {
        return LGMediaModelFetchSetter()
    }()
    
    func refreshLayout() {
        self.progressView.center = self.center
        guard let mediaModel = self.mediaModel else {return}
        
        let sentinel = mediaSetter.cancel(withNewMediaModel: mediaModel)
        
        self.stopPlay()
        
        LGMediaModelFetchSetter.setterQueue.async { [weak self] in
            guard let weakSelf = self else {return}
            var newSentinel = sentinel
            
            newSentinel = weakSelf.mediaSetter.setOperation(with: sentinel,
                                                            mediaModel: mediaModel,
                                                            progress:
                { [weak self] (progress) in
                    guard let weakSelf = self, weakSelf.mediaSetter.sentinel == newSentinel else {return}
                    weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
                }, livePhotoCompletion: { [weak self] (livePhoto, finished, error) in
                    guard let weakSelf = self else {return}
                    
                    guard let livePhoto = livePhoto,
                        let livePhotoView = weakSelf.livePhotoView as? PHLivePhotoView else
                    {
                        weakSelf.progressView.isShowError = true
                        return
                    }
                    livePhotoView.livePhoto = livePhoto
                    weakSelf.progressView.isHidden = true
                    weakSelf.fixViewFrame()
                    if weakSelf.isShown {
                        livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                    } else {
                        livePhotoView.stopPlayback()
                    }
            })
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
        isShown = false
        stopPlay()
    }
    
    func didAppear() {
        isShown = true
        startPlay()
    }
    
    func didDisappear() {
        isShown = false
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
    
    func startPlay() {
        if #available(iOS 9.1, *) {
            if let livePhotoView = self.livePhotoView as? PHLivePhotoView {
                livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
            }
        } else {
            if let imageView = self.livePhotoView as? UIImageView {
                imageView.image = self.mediaModel.thumbnailImage
            }
        }
    }
}
