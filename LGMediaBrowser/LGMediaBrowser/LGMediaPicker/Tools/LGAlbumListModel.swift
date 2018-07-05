//
//  LGAlbumListModel.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos

public class LGPhotoModel {
    public enum AssetMediaType {
        case unknown
        case generalImage
        case livePhoto
        case video
        case audio
        case remoteImage
        case remoteVideo
    }
    
    public var asset: PHAsset
    public var type: AssetMediaType
    public var duration: String
    public var isSelected: Bool
    public var url: URL?
    public var image: UIImage?
    public var currentSelectedIndex: Int = -1
    
    public init(asset: PHAsset, type: AssetMediaType, duration: String) {
        self.asset = asset
        self.type = type
        self.duration = duration
        self.isSelected = false
    }
    
    public var pixelSize: CGSize {
        return CGSize(width: self.asset.pixelWidth, height: self.asset.pixelHeight)
    }
    
    public func pixelSize(containInSize size: CGSize) -> CGSize {
        var width = min(CGFloat(self.asset.pixelWidth), size.width)
        var height = width * CGFloat(self.asset.pixelHeight) / CGFloat(self.asset.pixelWidth)
        
        if height.isNaN { return CGSize.zero }
        
        if height > size.height {
            height = size.height
            width = height * CGFloat(self.asset.pixelWidth) / CGFloat(self.asset.pixelHeight)
        }
        
        return CGSize(width: width, height: height)
    }
}


public class LGAlbumListModel {
    public var title: String?
    public var count: Int
    public var isAllPhotos: Bool
    public var result: PHFetchResult<PHAsset>?
    public var headImageAsset: PHAsset?
    public var models: [LGPhotoModel] = []
    public var selectedModels: [LGPhotoModel] = []
    public var selectedCount: Int = 0
    
    public init(title: String?,
                count: Int,
                isAllPhotos: Bool,
                result: PHFetchResult<PHAsset>?,
                headImageAsset: PHAsset?)
    {
        self.title = title
        self.count = count
        self.isAllPhotos = isAllPhotos
        self.result = result
        self.headImageAsset = headImageAsset
        
    }
}
