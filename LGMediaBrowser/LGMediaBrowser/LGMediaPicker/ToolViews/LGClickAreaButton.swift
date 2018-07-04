//
//  LGButton.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/7/4.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit

public class LGClickAreaButton: UIButton {
    
    public var enlargeOffset: UIEdgeInsets = UIEdgeInsets.zero
    
    private var enlargedRect: CGRect {
        if enlargeOffset == UIEdgeInsets.zero {
            return self.bounds
        } else {
            return CGRect(x: -enlargeOffset.left,
                          y: -enlargeOffset.top,
                          width: self.lg_width + enlargeOffset.left + enlargeOffset.right,
                          height: self.lg_height + enlargeOffset.top + enlargeOffset.bottom)
        }
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let enlargedRect = self.enlargedRect
        if enlargedRect == self.bounds {
            return super.hitTest(point, with: event)
        } else {
            return enlargedRect.contains(point) ? self : nil
        }
    }
}
