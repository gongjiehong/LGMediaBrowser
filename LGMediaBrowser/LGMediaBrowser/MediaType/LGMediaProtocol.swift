//
//  LGMediaProtocol.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos

public enum LGMediaType {
    case generalPhoto
    case livePhoto
    case video
    case audio
    case other
}

public protocol LGMediaLocation {
    func asURL() throws ->  URL
    func asAsset() throws -> PHAsset
}

public protocol LGMediaProtocol {
    var mediaLocation: LGMediaLocation { get }
    var mediaType: LGMediaType { get }
    var isLocalFile: Bool { get }
    
    var placeholderImage: UIImage? { get set }

    init(mediaLocation: LGMediaLocation,
         mediaType: LGMediaType,
         isLocalFile: Bool,
         placeholderImage: UIImage?)
}
