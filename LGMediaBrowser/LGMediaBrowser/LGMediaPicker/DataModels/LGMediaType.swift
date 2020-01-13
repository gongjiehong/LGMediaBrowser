//
//  LGMediaType.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2019/6/12.
//  Copyright © 2019 龚杰洪. All rights reserved.
//

import Foundation

/// 输出的数据类型定义
public struct LGMediaType: OptionSet {
    public var rawValue: RawValue
    
    public typealias RawValue = Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// 正常图片，包含不动的apng和gif
    public static var image: LGMediaType {
        return  LGMediaType(rawValue: 1 << 5)
    }
    
    /// 实况照片
    public static var livePhoto: LGMediaType {
        return  LGMediaType(rawValue: 1 << 1)
    }
    
    /// 动图，apng和gif
    public static var animatedImage: LGMediaType {
        return  LGMediaType(rawValue: 1 << 2)
    }
    
    /// 视频
    public static var video: LGMediaType {
        return  LGMediaType(rawValue: 1 << 3)
    }
    
    /// 音频
    public static var audio: LGMediaType {
        return  LGMediaType(rawValue: 1 << 4)
    }
    
    /// 不支持的数据类型
    public static var unsupport: LGMediaType {
        return  LGMediaType(rawValue: 1 << 0)
    }
    
    /// 全部，包含视频，普通图片，实况照片和动图
    public static var all: LGMediaType {
        return [.image, .livePhoto, .animatedImage, .video]
    }
}
