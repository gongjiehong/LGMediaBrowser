//
//  LGAlbumListModel.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos

/// 相册列表模型
public class LGAlbumListModel {
    /// 相册名
    public var title: String?
    
    /// 此相册中的元素个数
    public var count: Int
    
    /// 是否为所有图片那个相册
    public var isAllPhotos: Bool
    
    /// PHFetchResult<PHAsset>，存储asset
    public var result: PHFetchResult<PHAsset>?
    
    /// 头图asset
    public var headImageAsset: PHAsset?
    
    /// 图片/视频/livephoto...对象模型数组
    public var models: [LGAlbumAssetModel] = []
    
    /// 被选中的模型数组
    public var selectedModels: [LGAlbumAssetModel] = []
    
    /// 此相册中被选中的张数
    public var selectedCount: Int = 0
    
    /// 构造函数
    ///
    /// - Parameters:
    ///   - title: 相册标题
    ///   - count: item数量
    ///   - isAllPhotos: 是否为所有图片那个相册
    ///   - result: PHFetchResult<PHAsset>，存储asset
    ///   - headImageAsset: 头图asset
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

