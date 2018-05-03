//
//  LGVideo.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation

public struct LGVideo: LGMediaProtocol {
    public var mediaURL: LGMediaLocation
    
    public var mediaType: LGMediaType
    
    public var isLocalFile: Bool
    
    public init(mediaURL: LGMediaLocation, mediaType: LGMediaType, isLocalFile: Bool) {
        self.mediaURL = mediaURL
        self.mediaType = mediaType
        self.isLocalFile = isLocalFile
    }
}
