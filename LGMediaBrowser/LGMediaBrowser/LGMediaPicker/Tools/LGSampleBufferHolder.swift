//
//  LGSampleBufferHolder.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/27.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import Foundation
import CoreMedia

public class LGSampleBufferHolder {
    weak var sampleBuffer: CMSampleBuffer?
    
    public init(sampleBuffer: CMSampleBuffer?) {
        self.sampleBuffer = sampleBuffer
    }
}
