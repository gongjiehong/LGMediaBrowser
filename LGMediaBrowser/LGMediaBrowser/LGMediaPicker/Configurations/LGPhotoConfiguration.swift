//
//  LGPhotoConfiguration.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import AVFoundation

open class LGPhotoConfiguration: LGMediaTypeConfiguration {
    public override init() {
        super.init()
        self.isEnabled = true
    }
    
    private var _options: LGOptionsDictionary?
    
    override public var options: LGOptionsDictionary? {
        get {
            if let result = _options {
                return result
            } else {
                _options = [AVVideoCodecKey: AVVideoCodecType.jpeg]
                return _options
            }
        } set {
            _options = newValue
        }
    }
}
