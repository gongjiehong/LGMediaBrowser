//
//  UIImage+LGMediaPicker.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/30.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import GPUImage

extension UIImage {
    func imageWith(filter: GPUImageFilter) -> UIImage? {
        let picture = GPUImagePicture(image: self)
        filter.useNextFrameForImageCapture()
        picture?.addTarget(filter)
        picture?.processImage()

        return filter.imageFromCurrentFramebuffer(with: self.imageOrientation)
    }
}
