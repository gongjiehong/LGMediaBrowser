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
import LGWebImage
import LGHTTPRequest

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
    
    private var _thumbnailImage: UIImage
    private var _lock: NSLock = NSLock()
    
    public var thumbnailImage: UIImage {
        set {
            _lock.lock()
            defer {
                _lock.unlock()
            }
            _thumbnailImage = newValue
        } get {
            _lock.lock()
            defer {
                _lock.unlock()
            }
            return _thumbnailImage
        }
    }
    public var thumbnailImageURL: LGURLConvertible?
    
    public init(mediaLocation: LGMediaLocation,
                mediaType: LGMediaType,
                isLocalFile: Bool,
                thumbnailImage: UIImage,
                thumbnailImageURL: LGURLConvertible? = nil)
    {
        self.mediaLocation = mediaLocation
        self.mediaType = mediaType
        self.isLocalFile = isLocalFile
        _thumbnailImage = thumbnailImage
        self.thumbnailImageURL = thumbnailImageURL
    }
    
    public func fetchThumbnailImage() {
        guard let url = self.thumbnailImageURL else {
            return
        }
        LGWebImageManager.default.downloadImageWith(url: url,
                                                    options: LGWebImageOptions.default,
                                                    progress: nil,
                                                    transform: nil)
        { (resultImage, imageURL, sourceType, imageStage, error) in
            guard error == nil, let image = resultImage else {
                return
            }
            self.thumbnailImage = image
        }
    }
    
}
