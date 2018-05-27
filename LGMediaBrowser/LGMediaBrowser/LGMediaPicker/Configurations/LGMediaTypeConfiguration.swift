//
//  LGMediaTypeConfiguration.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/24.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import CoreVideo
import AVFoundation

public typealias LGOptionsDictionary = [String: Any]

open class LGMediaTypeConfiguration {
    public init() {
    }
    
    /// 预置项定义
    ///
    /// - high: 高质量
    /// - medium: 中等质量
    /// - low: 低质量
    public enum Preset: String {
        case high = "HighestQuality"
        case medium = "MediumQuality"
        case low = "LowQuality"
        case other = "Other"
    }
    
    /// 此类型是否启用
    public var isEnabled = false
    
    /// 用于不改变输入输出设备的情况下忽略当前类型
    public var shouldIgnore = false

    /// 设置音频比特率，如果options字段为空，则此属性不生效
    public var bitrate: UInt64 = 0
    
    /// 设置一些输入输出的相应属性，如果有设置，则优先使用本属性的内容
    public var options: LGOptionsDictionary?
    
    /// 预设值字符串，例如视频质量
    public var preset: Preset = .other
    
    /// 根据buffer创建AVAssetWriter需要的options
    ///
    /// - Parameter sampleBuffer: CMSampleBuffer
    /// - Returns: 需要的options
    open func createAssetWriterOptions(using sampleBuffer: CMSampleBuffer?) -> LGOptionsDictionary? {
        return nil
    }

}
