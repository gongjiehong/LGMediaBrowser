//
//  UIView+LGMediaBrowser.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/5/9.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

extension UIView {
    public var lg_width: CGFloat {
        set {
            let newFrame = CGRect(origin: self.frame.origin,
                                  size: CGSize(width: newValue, height: self.frame.height))
            self.frame = newFrame
        } get {
            return self.frame.width
        }
    }
    
    public var lg_height: CGFloat {
        set {
            let newFrame = CGRect(origin: self.frame.origin,
                                  size: CGSize(width: self.frame.width, height: newValue))
            self.frame = newFrame
        } get {
            return self.frame.height
        }
    }
    
    
    public var lg_originX: CGFloat {
        set {
            let newFrame = CGRect(origin: CGPoint(x: newValue, y: self.frame.origin.y),
                                  size: self.frame.size)
            self.frame = newFrame
        } get {
            return self.frame.origin.x
        }
    }
    
    
    public var lg_originY: CGFloat {
        set {
            let newFrame = CGRect(origin: CGPoint(x: self.frame.origin.x, y: newValue),
                                  size: self.frame.size)
            self.frame = newFrame
        } get {
            return self.frame.origin.y
        }
    }
    
    public var lg_size: CGSize {
        set {
            let newFrame = CGRect(origin: self.frame.origin,
                                  size: newValue)
            self.frame = newFrame
        } get {
            return self.frame.size
        }
    }
    
    public var lg_origin: CGPoint {
        set {
            let newFrame = CGRect(origin: newValue,
                                  size: self.frame.size)
            self.frame = newFrame
        } get {
            return self.frame.origin
        }
    }
}
