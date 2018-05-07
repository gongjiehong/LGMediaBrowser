//
//  LGNormalPhoto.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

public struct LGGeneralPhoto: LGMediaProtocol {
    public var mediaLocation: LGMediaLocation
    
    public var placeholderImage: UIImage?
    
    public init(mediaLocation: LGMediaLocation,
                mediaType: LGMediaType,
                isLocalFile: Bool,
                placeholderImage: UIImage? = nil)
    {
        self.mediaLocation = mediaLocation
        self.mediaType = mediaType
        self.isLocalFile = isLocalFile
        self.placeholderImage = placeholderImage
    }
    
    public var mediaType: LGMediaType
    
    public var isLocalFile: Bool
}
