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
//    lazy var livePhotoView: PHLivePhotoView = {
//        let temp = PHLivePhotoView(frame: CGRect.zero)
//        temp.clipsToBounds = true
//        temp.contentMode = UIView.ContentMode.scaleAspectFill
//        return temp
//    }()
    open override func refreshLayout() {
        if #available(iOS 9.1, *) {
//            if let previewView = self.previewView as? PHLivePhotoView {
//                mediaModel?.fetchImage(withProgress: <#T##LGProgressHandler?##LGProgressHandler?##(Progress) -> Void#>, completion: <#T##((UIImage?) -> Void)?##((UIImage?) -> Void)?##(UIImage?) -> Void#>)
//                previewView.livePhoto
//            } else {
//                
//            }
        } else {
            self.previewView = LGSectorProgressView(frame: CGRect(x: 0, y: 0, width: 50.0, height: 50.0),
                                                    isShowError: true)
            self.contentView.addSubview(self.previewView!)
            self.previewView?.center = self.contentView.center
        }
    }
}

