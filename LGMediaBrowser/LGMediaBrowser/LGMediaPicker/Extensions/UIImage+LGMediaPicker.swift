//
//  UIImage+LGMediaPicker.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/30.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit
import CoreImage

extension UIImage {
    func imageWith(filter: CIFilter) -> UIImage? {
        let picture = CIImage(image: self)
        filter.setValue(picture, forKey: kCIInputImageKey)
        if let output = filter.outputImage {
            let result = UIImage(ciImage: output)
            return result
        }
        return nil
    }
}
