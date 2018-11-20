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
    
    public required convenience init(frame: CGRect, mediaModel: LGMediaModel) {
        self.init(frame: frame)
        self.mediaModel = mediaModel
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
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        livePhotoMarkView.frame = self.livePhotoMarkFrame
    }
    
    func refreshLayout() {
        
    }
}
