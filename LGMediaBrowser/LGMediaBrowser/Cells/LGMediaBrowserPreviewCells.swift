//
//  LGGeneralPhotoCell.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

open class LGMediaBrowserPreviewCell: UICollectionViewCell {
    open var mediaModel: LGMediaModel? {
        didSet {
            refreshLayout()
        }
    }
    open var previewView: UIView?
    
    open func willDisplay() {
    }
    
    open func didEndDisplay() {
    }
    
    open func refreshLayout() {
        
    }
}


open class LGMediaBrowserVideoCell: LGMediaBrowserPreviewCell {
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let temp = self.previewView {
            temp.frame = self.contentView.bounds
        }
    }
    
    override open func willDisplay() {
        
    }
    
    override open func didEndDisplay() {
        if let playerView = previewView as? LGPlayerControlView {
            playerView.stopPlay()
        }
    }
    
    override open func refreshLayout() {
        guard let media = self.mediaModel else {
            return
        }
        if let playerView = previewView as? LGPlayerControlView {
            playerView.mediaModel = media
        } else if previewView != nil {
            previewView?.removeFromSuperview()
            previewView = nil
            initPlayerView(media)
        } else {
            initPlayerView(media)
        }
    }
    
    func initPlayerView(_ media: LGMediaModel) {
        previewView = LGPlayerControlView(frame: self.contentView.bounds,
                                          mediaModel: media)
        self.contentView.addSubview(previewView!)
    }
}

open class LGMediaBrowserAudioCell: LGMediaBrowserVideoCell {
    override open func layoutSubviews() {
        super.layoutSubviews()
    }
}

open class LGMediaBrowserGeneralPhotoCell: LGMediaBrowserPreviewCell {

    override open func refreshLayout() {
        guard let media = self.mediaModel else {
            return
        }
        if let imageZoom = previewView as? LGZoomingScrollView {
            imageZoom.mediaModel = media
        } else if previewView != nil {
            previewView?.removeFromSuperview()
            previewView = nil
            initImageZoomView(media)
        } else {
            initImageZoomView(media)
        }
    }
    
    func initImageZoomView(_ media: LGMediaModel) {
        let imageZoom = LGZoomingScrollView(frame: self.contentView.bounds)
        imageZoom.mediaModel = media
        self.previewView = imageZoom
        self.contentView.addSubview(imageZoom)
    }
    
    override open func willDisplay() {
        if let previewView = self.previewView as? LGZoomingScrollView {
            previewView.setMaxMinZoomScalesForCurrentBounds()
        }
    }
    
    override open func didEndDisplay() {
        
    }
}

open class LGMediaBrowserLivePhotoCell: LGMediaBrowserPreviewCell {
    lazy var progressView: LGSectorProgressView = {
        let temp = LGSectorProgressView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return temp
    }()
    
    open override func refreshLayout() {
        if #available(iOS 9.1, *) {
            var targetView: PHLivePhotoView
            if let previewView = self.previewView as? PHLivePhotoView {
                targetView = previewView
            } else {
                let livePhotoView = PHLivePhotoView(frame: self.contentView.bounds)
                livePhotoView.contentMode = UIView.ContentMode.scaleAspectFill
                livePhotoView.addSubview(progressView)
                self.contentView.addSubview(livePhotoView)
                targetView = livePhotoView
                self.previewView = livePhotoView
            }
            
            guard let mediaModel = self.mediaModel else {return}
            do {
                try mediaModel.fetchLivePhoto(withProgress:
                { (progress) in
                    DispatchQueue.main.async { [weak self] in
                        guard let weakSelf = self else {return}
                        weakSelf.progressView.progress = CGFloat(progress.fractionCompleted)
                        
                    }
                }, completion: { [weak self] (livePhoto) in
                    guard let weakSelf = self else {return}
                    guard let livePhoto = livePhoto else {
                        weakSelf.progressView.isShowError = true
                        return
                    }
                    targetView.livePhoto = livePhoto
                    targetView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                })
            } catch {
                self.progressView.isShowError = true
            }
        } else {
            self.contentView.addSubview(progressView)
            progressView.center = self.contentView.center
            progressView.isShowError = true
        }
    }
}

