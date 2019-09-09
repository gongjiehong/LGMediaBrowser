//
//  SCMediaTypeConfiguration.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation
import CoreVideo
import GPUImage

@objc public protocol LGVideoOverlay {
    @objc optional
    func requiresUpdateOnMainThread(atVideoTime time: TimeInterval, videoSize: CGSize) -> Bool
    func update(withVideoTime time: TimeInterval)
}

/// 视频相关定义
open class LGVideoConfiguration: LGMediaTypeConfiguration {
    /// 默认设置项
    public struct DefaultSettings {
        
        /// 编码类型，iOS11以后应该为AVVideoCodecType.h264, 暂不做替换
        public static var codecType: AVVideoCodecType = AVVideoCodecType.h264
        
        /// 缩放模式
        public static var scalingMode: String = AVVideoScalingModeResizeAspectFill
        
        /// 比特率
        /// LD 240p 3G Mobile @ H.264 baseline profile 350 kbps (3 MB/minute)
        /// LD 360p 4G Mobile @ H.264 main profile 700 kbps (6 MB/minute)
        /// SD 480p WiFi @ H.264 main profile 1200 kbps (10 MB/minute)
        /// HD 720p @ H.264 high profile 2500 kbps (20 MB/minute)
        /// HD 1080p @ H.264 high profile 5000 kbps (35 MB/minute)
        public static var bitrate: UInt64 = 2_000_000
    }
    
    /// 水印相关的定义
    public struct WaterMark {
        /// 水印的位置定义
        ///
        /// - topLeft: 左上角
        /// - topRight: 右上角
        /// - center: 中间
        /// - bottomLeft: 左下角
        /// - bottomRight: 右下角
        public enum Location {
            case topLeft
            case topRight
            case center
            case bottomLeft
            case bottomRight
        }
        
        /// 水印图片内容
        public var image: UIImage
        
        /// 水印坐标
        public var frame: CGRect
        
        /// 水印位置
        public var location: Location
        
        /// 初始化
        ///
        /// - Parameters:
        ///   - image: 水印图片UIImage
        ///   - frame: 水印坐标和大小
        ///   - location: 水印位置
        public init(image: UIImage, frame: CGRect, location: Location) {
            self.image = image
            self.frame = frame
            self.location = location
        }
    }
    
    
    /// output size， 默认为CGSize.zero
    public var size: CGSize = CGSize.zero
    
    ///视频的图像变换模式，默认无变化
    public var affineTransform: CGAffineTransform = CGAffineTransform.identity
    
    /// 视频文件压缩格式，默认H264
    public var codecType: AVVideoCodecType = AVVideoCodecType.h264
    
    /// 缩放模式，默认AspectFill
    public var scalingMode: String = AVVideoScalingModeResizeAspectFill
    
    /// 相机帧速率，如果过高会被丢弃，默认0，表示使用原始视频
    public var maxFrameRate: CMTimeScale = 0
    
    /// 视频的时间缩放，默认1.0，小于1.0为延时摄影效果，大于1.0则为慢动作视频
    public var timeScale: CGFloat = 1.0
    
    /// 是否录制正方形视频
    public var sizeAsSquare: Bool = false
    
    /// 如果为true，则每帧都会被编码为关键帧
    public var shouldKeepOnlyKeyFrames: Bool = false
    public var keepInputAffineTransform: Bool = true
    
    /// 需要应用的滤镜
    public var filter: GPUImageOutput?
    public var composition: AVVideoComposition?
    public var waterMark: WaterMark?
    public var profileLevel: String?
    public var overlay: (UIView, LGVideoOverlay)?
    public var bufferSize: CGSize = CGSize.zero
    

    public override init() {
        super.init()
        self.bitrate = DefaultSettings.bitrate
    }
    
    @inline(__always) func calcVideoSize(videoSize: CGSize, requestedWidth: CGFloat) -> CGSize {
        let ratio = videoSize.width / requestedWidth
        if ratio.isNaN || ratio <= 1.0 {
            return videoSize
        } else {
            return CGSize(width: videoSize.width / ratio, height: videoSize.height / ratio)
        }
    }
    
    public func createAssetWriterOptions(withVideoSize videoSize: CGSize) -> LGOptionsDictionary {
        if let options = self.options {
            return options
        }
        
        var outputSize = self.size
        var bitrate = self.bitrate

        switch self.preset {
        case .low:
            bitrate = 500_000
            outputSize = calcVideoSize(videoSize: videoSize, requestedWidth: 640.0)
            break
        case .medium:
            bitrate = 1_000_000
            outputSize = calcVideoSize(videoSize: videoSize, requestedWidth: 1280.0)
            break
        case .high:
            bitrate = 6_000_000
            outputSize = calcVideoSize(videoSize: videoSize, requestedWidth: 1920.0)
            break
        default:
            bitrate = 1_000_000
            outputSize = calcVideoSize(videoSize: videoSize, requestedWidth: 1280.0)
            break
        }
        
        if outputSize.equalTo(CGSize.zero) {
            outputSize = videoSize
        }

        
        if self.sizeAsSquare {
            if videoSize.width > videoSize.height {
                outputSize.width = videoSize.height
            } else {
                outputSize.height = videoSize.width
            }
        }
        
        var compressionSettings = LGOptionsDictionary()
        compressionSettings[AVVideoAverageBitRateKey] = bitrate
        

        
        if shouldKeepOnlyKeyFrames {
            compressionSettings[AVVideoMaxKeyFrameIntervalKey] = 1
        }
        
        if let profileLevel = self.profileLevel {
            compressionSettings[AVVideoProfileLevelKey] = profileLevel
        }
        
        compressionSettings[AVVideoAllowFrameReorderingKey] = true
        compressionSettings[AVVideoExpectedSourceFrameRateKey] = 30

        
        return [AVVideoCodecKey : self.codecType,
                AVVideoScalingModeKey : self.scalingMode,
                AVVideoWidthKey: outputSize.width,
                AVVideoHeightKey: outputSize.height,
                AVVideoCompressionPropertiesKey: compressionSettings]
    }
    
    open override func createAssetWriterOptions(using sampleBuffer: CMSampleBuffer?) -> LGOptionsDictionary? {
        if let sampleBuffer = sampleBuffer {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                
                return createAssetWriterOptions(withVideoSize: CGSize(width: width, height: height))
            }
        }
        
        return nil
    }
}
