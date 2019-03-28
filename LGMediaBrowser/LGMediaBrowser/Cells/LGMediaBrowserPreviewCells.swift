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
    
    open func didDisplay() {
        
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
        if let playerView = previewView as? LGPlayerControlView {
            playerView.isActive = false
        }
    }
    
    override open func didEndDisplay() {
        if let playerView = previewView as? LGPlayerControlView {
            playerView.stopPlay()
            playerView.isActive = false
        }
    }
    
    open override func didDisplay() {
        if let playerView = previewView as? LGPlayerControlView {
            playerView.isActive = true
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
            previewView.reset()
        }
    }
    
    open override func didDisplay() {
        if let previewView = self.previewView as? LGZoomingScrollView {
            previewView.layoutImageIfNeeded()
        }
    }
    
    override open func didEndDisplay() {
    }
}

open class LGMediaBrowserLivePhotoCell: LGMediaBrowserPreviewCell {
    open override func refreshLayout() {
        if let previewView = self.previewView as? LGLivePhotoView {
            previewView.mediaModel = mediaModel
        } else {
            guard let mediaModel = self.mediaModel else {return}
            self.previewView = LGLivePhotoView(frame: self.contentView.bounds, mediaModel: mediaModel)
            self.contentView.addSubview(self.previewView!)
        }
    }
    
    override open func willDisplay() {
        if let previewView = self.previewView as? LGLivePhotoView {
            previewView.willAppear()
        }
    }
    
    open override func didDisplay() {
        if let previewView = self.previewView as? LGLivePhotoView {
            previewView.didAppear()
        }
    }
    
    override open func didEndDisplay() {
        if let previewView = self.previewView as? LGLivePhotoView {
            previewView.didDisappear()
        }
    }
}

