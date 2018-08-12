//
//  UIView+ScreenShot.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/8/2.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

extension UIView {
    /// 对当前视图截图
    ///
    /// - Parameters:
    ///   - inHierarchy: 是否直接截取当前图层树中显示的内容
    ///   - rect: 裁切矩形
    /// - Returns: 截取到的UIImage or nil
    public func screenShot(inHierarchy: Bool = true, rect: CGRect = CGRect.zero) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.layer.frame.size, false, scale)
        defer{
            UIGraphicsEndImageContext()
        }
        
        if inHierarchy == true {
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        } else {
            if let context = UIGraphicsGetCurrentContext() {
                self.layer.render(in: context)
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let rectTransform = CGAffineTransform(scaleX: image?.scale ?? scale, y: image?.scale ?? scale)
        if !rect.equalTo(CGRect.zero) {
            if let croppedCGImage = image?.cgImage?.cropping(to: rect.applying(rectTransform)) {
               return UIImage(cgImage: croppedCGImage)
            }
        }
        return image
    }
}
