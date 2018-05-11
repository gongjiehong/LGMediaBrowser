//
//  LGMediaModel.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/4/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

public enum LGMediaType {
    case generalPhoto
    case livePhoto
    case video
    case audio
    case other
}

public protocol LGMediaLocation {
    func toURL() ->  URL?
    func toAsset() -> PHAsset?
}

extension String: LGMediaLocation {
    public func toURL() -> URL? {
        if self.range(of: "://") != nil {
            return URL(string: self)
        } else {
            return URL(fileURLWithPath: self)
        }
    }
    
    public func toAsset() -> PHAsset? {
        return nil
    }
}

extension PHAsset: LGMediaLocation {
    public func toURL() -> URL? {
        return nil
    }
    
    public func toAsset() -> PHAsset? {
        return self
    }
}

extension AVURLAsset: LGMediaLocation {
    public func toURL() -> URL? {
        return self.url
    }
    
    public func toAsset() -> PHAsset? {
        return nil
    }
}

public class LGMediaModel {
    public private(set) var mediaLocation: LGMediaLocation
    public private(set) var mediaType: LGMediaType
    public private(set) var isLocalFile: Bool
    
    public var thumbnailImage: UIImage
    public var thumbnailImageURL: 
    
    public init(mediaLocation: LGMediaLocation,
                mediaType: LGMediaType,
                isLocalFile: Bool,
                placeholderImage: UIImage)
    {
        self.mediaLocation = mediaLocation
        self.mediaType = mediaType
        self.isLocalFile = isLocalFile
        self.thumbnailImage = placeholderImage
    }
    
    public func fetch
    
}
