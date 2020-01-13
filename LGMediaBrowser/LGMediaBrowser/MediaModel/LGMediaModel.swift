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

fileprivate var _LGMediaModelIdentify: Int64 = 0

/// 存储媒体数据的模型，承载下载数据功能
public class LGMediaModel {
    public typealias ProgressHandler = (Progress, Int64) -> Void
    
    /// 媒体文件位置
    ///
    /// - remoteFile: 远程服务器上的文件
    /// - localFile: 本地文件
    /// - album: 系统相册中的PHAsset
    public enum Position {
        case remoteFile
        case localFile
        case album
    }
    
    /// 缩略图地址，如果是LivePhoto，该属性为第一帧图像的URL
    public private(set) var thumbnailImageURL: LGURLConvertible?
    
    /// 媒体文件地址，如果是LivePhoto，该属性为视频的URL
    public private(set) var mediaURL: LGURLConvertible?
    
    /// 相册中的媒体文件Asset对象
    public private(set) var mediaAsset: PHAsset?
    
    /// 媒体文件类型
    public private(set) var mediaType: LGMediaType = .unsupport
    
    /// 媒体文件位置
    public private(set) var mediaPosition: Position = .remoteFile
    
    /// 是否自动播放动图，默认true，本地相册图片无需播放动图时可特殊处理为false
    public var isAutoPlayAnimatedImage: Bool = true
    
    public private(set) lazy var identify: Int64 = {
        return OSAtomicIncrement64(&_LGMediaModelIdentify)
    }()
    
    internal weak var photoModel: LGAlbumAssetModel? = nil
    
    private var _thumbnailImage: UIImage?
    private var _lock: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    /// 占位图，大多数时候直接就是原图
    public var thumbnailImage: UIImage? {
        set {
            _lock.lg_lock()
            defer {
                _lock.lg_unlock()
            }
            _thumbnailImage = newValue
        } get {
            _lock.lg_lock()
            defer {
                _lock.lg_unlock()
            }
            return _thumbnailImage
        }
    }
    
    public init() {
        self.mediaType = .unsupport
        self.mediaPosition = .localFile
    }
    
    
    /// 初始化, 此处会校验参数是否合法
    ///
    /// - Parameters:
    ///   - thumbnailImageURL: 媒体文件缩略图路径
    ///   - mediaURL: 媒体文件路径
    ///   - mediaAsset: 媒体文件的PHAsset
    ///   - mediaType: 媒体类型
    ///   - mediaPosition: 媒体文件的位置
    ///   - thumbnailImage: 缩略图
    /// - Throws: 参数不正确的异常抛出
    public convenience init(thumbnailImageURL: LGURLConvertible?,
                            mediaURL: LGURLConvertible?,
                            mediaAsset: PHAsset?,
                            mediaType: LGMediaType,
                            mediaPosition: Position,
                            thumbnailImage: UIImage? = nil) throws
    {
        self.init()
        func checkParams() throws {
            switch mediaPosition {
            case .remoteFile:
                switch mediaType {
                case .image, .livePhoto, .video, .animatedImage:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    } else if thumbnailImageURL == nil {
                        throw LGMediaModelError.thumbnailURLIsInvalid
                    }
                    break
                case .audio:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    break
                default:
                    break
                }
                break
            case .localFile:
                switch mediaType {
                case .image, .animatedImage:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    break
                case .livePhoto:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    } else if thumbnailImageURL == nil {
                        throw LGMediaModelError.thumbnailURLIsInvalid
                    }
                    break
                case .video, .audio:
                    if mediaURL == nil {
                        throw LGMediaModelError.mediaURLIsInvalid
                    }
                    break
                default:
                    break
                }
                break
            case .album:
                if mediaAsset == nil {
                    throw LGMediaModelError.mediaAssetIsInvalid
                }
                break
            }
        }
        
        try checkParams()
        
        self.thumbnailImageURL = thumbnailImageURL
        self.mediaURL = mediaURL
        self.mediaAsset = mediaAsset
        self.mediaType = mediaType
        self.mediaPosition = mediaPosition
        self.thumbnailImage = thumbnailImage
    }
    
    deinit {
    }
}

extension LGMediaModel {
    /// 缩略图是否有效
    public var isThumbnailImageValid: Bool {
        if let thumbnailImageURL = try? self.thumbnailImageURL?.asURL() {
            if let mediaURL = try? self.mediaURL?.asURL() {
                if thumbnailImageURL == mediaURL {
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        }
        return false
    }
}


public enum LGMediaModelError: Error {
    case thumbnailURLIsInvalid
    case mediaURLIsInvalid
    case mediaAssetIsInvalid
    case unableToGetThumbnail
    case mediaModelIsInvalid
}
