//
//  LGGeneralPhotoCell.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

open class LGMediaBrowserPreviewCell: UICollectionViewCell {
    public var mediaModel: LGMediaProtocol?
    var previewView: UIScrollView?
}


open class LGMediaBrowserVideoCell: LGMediaBrowserPreviewCell {
    override open func layoutSubviews() {
        super.layoutSubviews()
        guard let media = self.mediaModel else {
            return
        }
        if previewView == nil {
            previewView = LGZoomingScrollView<LGPlayerControlView>(frame: self.contentView.bounds, media: media)
            self.contentView.addSubview(previewView!)
        } else if let temp = previewView as? LGZoomingScrollView<LGPlayerControlView> {
            temp.media = media
        } else {
            // do nothing
        }
    }
}

open class LGMediaBrowserAudioCell: LGMediaBrowserPreviewCell {
    override open func layoutSubviews() {
        super.layoutSubviews()
        guard let media = self.mediaModel else {
            return
        }
        if previewView == nil {
            previewView = LGZoomingScrollView<LGPlayerControlView>(frame: self.contentView.bounds, media: media)
            self.contentView.addSubview(previewView!)
        } else if let temp = previewView as? LGZoomingScrollView<LGPlayerControlView> {
            temp.media = media
        } else {
            // do nothing
        }
    }
}

